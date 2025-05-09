/*
API: set_staff_schedule
Description: Applies a new schedule to the database for a staff member
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
  - Success: return_code: "SUCCESS", message: "Staff schedule updated successfully"
  - Error: return_code: error code, message: error message
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/verify_token');

// POST /set_staff_schedule
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

        // Begin transaction
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Validate each schedule entry
            for (const entry of schedule) {
                // Check required fields
                if (!entry.day_of_week || !entry.start_time || !entry.end_time || !entry.start_date) {
                    await client.query('ROLLBACK');
                    return res.status(400).json({
                        return_code: "MISSING_FIELDS",
                        message: "Each schedule entry must include day_of_week, start_time, end_time, and start_date"
                    });
                }

                // Validate day_of_week
                const validDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                if (!validDays.includes(entry.day_of_week)) {
                    await client.query('ROLLBACK');
                    return res.status(400).json({
                        return_code: "INVALID_DAY",
                        message: `Invalid day_of_week: ${entry.day_of_week}. Must be one of: ${validDays.join(', ')}`
                    });
                }

                // Validate times
                if (entry.start_time >= entry.end_time) {
                    await client.query('ROLLBACK');
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

            for (const day in dayGroups) {
                const entries = dayGroups[day];
                for (let i = 0; i < entries.length; i++) {
                    for (let j = i + 1; j < entries.length; j++) {
                        const a = entries[i];
                        const b = entries[j];
                        
                        // Check for overlap
                        if ((a.start_time < b.end_time && a.end_time > b.start_time) ||
                            (b.start_time < a.end_time && b.end_time > a.start_time)) {
                            await client.query('ROLLBACK');
                            return res.status(400).json({
                                return_code: "SCHEDULE_OVERLAP",
                                message: `Overlapping schedule entries for ${day}`
                            });
                        }
                    }
                }
            }

            // Delete existing generated schedule entries for this staff member
            await client.query(
                `DELETE FROM staff_rota 
                 WHERE staff_id = $1 
                 AND business_id = $2
                 AND is_generated = true`,
                [staff_id, business_id]
            );

            // Insert new schedule entries
            for (const entry of schedule) {
                await client.query(
                    `INSERT INTO staff_schedule 
                     (staff_id, day_of_week, start_time, end_time, start_date, end_date, repeat_every_n_weeks)
                     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
                    [
                        staff_id,
                        entry.day_of_week,
                        entry.start_time,
                        entry.end_time,
                        entry.start_date,
                        entry.end_date || null,
                        entry.repeat_every_n_weeks || null
                    ]
                );
            }

            await client.query('COMMIT');

            // Return success response
            return res.status(200).json({
                return_code: "SUCCESS",
                message: "Staff schedule updated successfully"
            });
        } catch (error) {
            await client.query('ROLLBACK');
            console.error('Error in set_staff_schedule:', error);
            
            return res.status(500).json({
                return_code: "SERVER_ERROR",
                message: "An error occurred while updating the staff schedule"
            });
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Error in set_staff_schedule:', error);
        
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
