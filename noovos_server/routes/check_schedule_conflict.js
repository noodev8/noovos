/*
API: check_schedule_conflict
Description: Checks if a new schedule has conflicts with existing bookings
Input:
  - business_id: ID of the business
  - staff_id: ID of the staff member
  - schedule: Array of schedule entries with:
    - day_of_week: Day of the week (Monday, Tuesday, etc.)
    - start_time: Start time (HH:MM)
    - end_time: End time (HH:MM)
    - start_date: Start date (YYYY-MM-DD)
    - end_date: End date (YYYY-MM-DD) - optional
    - repeat_every_n_weeks: Repeat frequency in weeks - optional
Output:
  - Success with no conflicts: return_code: "SUCCESS", conflicts: []
  - Success with conflicts: return_code: "SUCCESS", conflicts: [array of conflict details]
  - Error: return_code: error code, message: error message
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/verify_token');

// POST /check_schedule_conflict
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id, staff_id, schedule } = req.body;

        // Validate required fields
        if (!business_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID is required"
            });
        }

        if (!staff_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Staff ID is required"
            });
        }

        if (!schedule || !Array.isArray(schedule) || schedule.length === 0) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Schedule entries are required"
            });
        }

        // Check if the user has permission to manage staff schedules for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner' AND status = 'active'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to manage staff schedules for this business"
            });
        }

        // Check if the staff member belongs to this business
        const staffQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND (role = 'Staff' OR role = 'business_owner') AND status = 'active'`,
            [staff_id, business_id]
        );

        if (staffQuery.rows.length === 0) {
            return res.status(400).json({
                return_code: "INVALID_STAFF",
                message: "The specified staff member does not belong to this business"
            });
        }

        // Validate each schedule entry
        for (const entry of schedule) {
            // Check required fields
            if (!entry.day_of_week || !entry.start_time || !entry.end_time || !entry.start_date) {
                return res.status(400).json({
                    return_code: "MISSING_FIELDS",
                    message: "Each schedule entry must include day_of_week, start_time, end_time, and start_date"
                });
            }

            // Validate day_of_week
            const validDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
            if (!validDays.includes(entry.day_of_week)) {
                return res.status(400).json({
                    return_code: "INVALID_DAY",
                    message: `Invalid day_of_week: ${entry.day_of_week}. Must be one of: ${validDays.join(', ')}`
                });
            }

            // Validate times
            if (entry.start_time >= entry.end_time) {
                return res.status(400).json({
                    return_code: "INVALID_TIME",
                    message: "End time must be after start time"
                });
            }
        }

        // Check for overlapping time blocks within the same day
        const dayGroups = {};
        for (const entry of schedule) {
            const key = entry.day_of_week;
            if (!dayGroups[key]) {
                dayGroups[key] = [];
            }
            dayGroups[key].push(entry);
        }

        const overlaps = [];
        for (const day in dayGroups) {
            const entries = dayGroups[day];
            for (let i = 0; i < entries.length; i++) {
                for (let j = i + 1; j < entries.length; j++) {
                    const a = entries[i];
                    const b = entries[j];
                    
                    // Check for overlap
                    if ((a.start_time < b.end_time && a.end_time > b.start_time) ||
                        (b.start_time < a.end_time && b.end_time > a.start_time)) {
                        overlaps.push({
                            type: 'schedule_overlap',
                            day_of_week: day,
                            entries: [a, b]
                        });
                    }
                }
            }
        }

        // If there are schedule overlaps, return them immediately
        if (overlaps.length > 0) {
            return res.status(200).json({
                return_code: "SUCCESS",
                has_conflicts: true,
                conflicts: overlaps
            });
        }

        // Check for conflicts with existing non-generated rota entries
        const rotaConflictsQuery = `
            WITH schedule_days AS (
                SELECT 
                    generate_series(
                        $1::date, 
                        COALESCE($2::date, $1::date + INTERVAL '30 days'), 
                        '1 day'
                    )::date AS date
            ),
            day_mapping AS (
                SELECT 
                    date,
                    to_char(date, 'Day') AS day_name
                FROM schedule_days
            )
            SELECT 
                sr.id AS rota_id,
                sr.rota_date,
                sr.start_time,
                sr.end_time,
                s.service_name,
                c.first_name || ' ' || c.last_name AS customer_name,
                b.id AS booking_id
            FROM 
                staff_rota sr
            LEFT JOIN 
                booking b ON sr.staff_id = b.staff_id 
                AND sr.rota_date = b.booking_date 
                AND sr.start_time <= b.end_time 
                AND sr.end_time >= b.start_time
            LEFT JOIN 
                service s ON b.service_id = s.id
            LEFT JOIN 
                app_user c ON b.customer_id = c.id
            WHERE 
                sr.staff_id = $3
                AND sr.is_generated = false
                AND sr.rota_date >= $1
                AND (sr.rota_date <= $2 OR $2 IS NULL)
                AND NOT EXISTS (
                    SELECT 1 FROM day_mapping dm
                    JOIN unnest($4::text[]) AS schedule_day ON trim(dm.day_name) = schedule_day
                    WHERE dm.date = sr.rota_date
                    AND EXISTS (
                        SELECT 1 FROM unnest($5::time[]) AS start_time
                        JOIN unnest($6::time[]) AS end_time ON true
                        WHERE start_time <= sr.end_time AND end_time >= sr.start_time
                    )
                )
        `;

        // Prepare parameters for the query
        const startDate = schedule[0].start_date;
        const endDate = schedule.find(e => e.end_date)?.end_date || null;
        const days = schedule.map(e => e.day_of_week);
        const startTimes = schedule.map(e => e.start_time);
        const endTimes = schedule.map(e => e.end_time);

        const rotaConflictsResult = await pool.query(
            rotaConflictsQuery,
            [startDate, endDate, staff_id, days, startTimes, endTimes]
        );

        const rotaConflicts = rotaConflictsResult.rows.map(row => ({
            type: 'rota_conflict',
            rota_id: row.rota_id,
            rota_date: row.rota_date,
            start_time: row.start_time,
            end_time: row.end_time,
            booking_id: row.booking_id,
            service_name: row.service_name,
            customer_name: row.customer_name
        }));

        // Check for conflicts with existing bookings
        const bookingConflictsQuery = `
            WITH schedule_days AS (
                SELECT 
                    generate_series(
                        $1::date, 
                        COALESCE($2::date, $1::date + INTERVAL '30 days'), 
                        '1 day'
                    )::date AS date
            ),
            day_mapping AS (
                SELECT 
                    date,
                    to_char(date, 'Day') AS day_name
                FROM schedule_days
            ),
            schedule_times AS (
                SELECT 
                    dm.date,
                    unnest($5::time[]) AS start_time,
                    unnest($6::time[]) AS end_time
                FROM day_mapping dm
                WHERE trim(dm.day_name) = ANY($4::text[])
            )
            SELECT 
                b.id AS booking_id,
                b.booking_date,
                b.start_time,
                b.end_time,
                s.service_name,
                c.first_name || ' ' || c.last_name AS customer_name
            FROM 
                booking b
            JOIN 
                service s ON b.service_id = s.id
            JOIN 
                app_user c ON b.customer_id = c.id
            WHERE 
                b.staff_id = $3
                AND b.status = 'confirmed'
                AND b.booking_date >= $1
                AND (b.booking_date <= $2 OR $2 IS NULL)
                AND NOT EXISTS (
                    SELECT 1 FROM schedule_times st
                    WHERE st.date = b.booking_date
                    AND st.start_time <= b.end_time 
                    AND st.end_time >= b.start_time
                )
        `;

        const bookingConflictsResult = await pool.query(
            bookingConflictsQuery,
            [startDate, endDate, staff_id, days, startTimes, endTimes]
        );

        const bookingConflicts = bookingConflictsResult.rows.map(row => ({
            type: 'booking_conflict',
            booking_id: row.booking_id,
            booking_date: row.booking_date,
            start_time: row.start_time,
            end_time: row.end_time,
            service_name: row.service_name,
            customer_name: row.customer_name
        }));

        // Combine all conflicts
        const allConflicts = [...overlaps, ...rotaConflicts, ...bookingConflicts];

        // Return success response with conflicts (if any)
        return res.status(200).json({
            return_code: "SUCCESS",
            has_conflicts: allConflicts.length > 0,
            conflicts: allConflicts
        });
    } catch (error) {
        console.error('Error in check_schedule_conflict:', error);
        
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while checking for schedule conflicts"
        });
    }
});

module.exports = router;
