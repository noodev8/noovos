/*
=======================================================================================================================================
API Route: set_staff_schedule
=======================================================================================================================================
Method: POST
Purpose: Applies a new schedule to the database for a staff member
         Includes comprehensive conflict checking with existing bookings and manual rota entries
         (This API now incorporates the functionality previously provided by check_schedule_conflict)
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 5,                   // integer, required - ID of the business
  "staff_id": 10,                     // integer, required - ID of the staff member
  "schedule": [                       // array, required - Array of schedule entries
    {
      "day_of_week": "Monday",        // string, required - Day of the week (Monday, Tuesday, etc.)
      "start_time": "09:00",          // string, required - Start time (HH:MM)
      "end_time": "17:00",            // string, required - End time (HH:MM)
      "start_date": "2023-06-01",     // string, required - Start date (YYYY-MM-DD)
      "end_date": "2023-12-31",       // string, optional - End date (YYYY-MM-DD)
      "repeat_every_n_weeks": 1       // integer, optional - Repeat frequency in weeks
    },
    ...
  ],
  "force": false                      // boolean, optional - Force schedule update even if booking conflicts exist (default: false)
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Staff schedule updated successfully"
}

Success Response (With Warnings):
{
  "return_code": "SUCCESS_WITH_WARNINGS",
  "message": "Staff schedule updated successfully, but there are booking conflicts",
  "conflicts": [
    {
      "booking_id": 123,
      "booking_date": "2023-06-05",
      "start_time": "10:00:00",
      "end_time": "11:00:00",
      "service_name": "Haircut",
      "customer_name": "John Doe"
    },
    ...
  ]
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Business ID is required"
}
{
  "return_code": "MISSING_FIELDS",
  "message": "Staff ID is required"
}
{
  "return_code": "MISSING_FIELDS",
  "message": "Schedule entries are required"
}
{
  "return_code": "MISSING_FIELDS",
  "message": "Each schedule entry must include day_of_week, start_time, end_time, and start_date"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "You do not have permission to manage staff schedules for this business"
}
{
  "return_code": "INVALID_STAFF",
  "message": "The specified staff member does not belong to this business"
}
{
  "return_code": "INVALID_DAY",
  "message": "Invalid day_of_week: [day]. Must be one of: Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday"
}
{
  "return_code": "INVALID_TIME",
  "message": "End time must be after start time"
}
{
  "return_code": "SCHEDULE_OVERLAP",
  "message": "Overlapping schedule entries for [day]"
}
{
  "return_code": "BOOKING_CONFLICTS",
  "message": "The new schedule conflicts with existing bookings. Use force=true to override.",
  "conflicts": [...]
}
{
  "return_code": "SERVER_ERROR",
  "message": "An error occurred while updating the staff schedule"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// Helper function to check if a date falls on a specific day of the week
function isDateOnDayOfWeek(date, dayOfWeek) {
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const dayIndex = days.indexOf(dayOfWeek);
    return date.getDay() === dayIndex;
}

// Helper function to check if a date is within a schedule's date range and repeat pattern
function isDateInSchedule(date, schedule) {
    // Check if date is within the schedule's date range
    const scheduleStartDate = new Date(schedule.start_date);
    let scheduleEndDate = null;
    if (schedule.end_date) {
        scheduleEndDate = new Date(schedule.end_date);
    }

    if (date < scheduleStartDate || (scheduleEndDate && date > scheduleEndDate)) {
        return false;
    }

    // Check if the date matches the day of week
    if (!isDateOnDayOfWeek(date, schedule.day_of_week)) {
        return false;
    }

    // Check repeat pattern if specified
    if (schedule.repeat_every_n_weeks) {
        // Calculate weeks between schedule start date and current date
        const msPerDay = 24 * 60 * 60 * 1000;
        const daysDiff = Math.round(Math.abs(date - scheduleStartDate) / msPerDay);
        const weeksDiff = Math.floor(daysDiff / 7);

        // Only include dates that match the repeat pattern
        return (weeksDiff % schedule.repeat_every_n_weeks === 0);
    }

    return true;
}

// POST /set_staff_schedule
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id, staff_id, schedule, force } = req.body;

        // Default force to false if not provided
        const forceUpdate = force === true;

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

            // Initialize bookingConflicts array outside the conditional scope
            let bookingConflicts = [];

            // First, get all manual rota entries for this staff member
            // These will be used to check if bookings are covered by manual entries
            const manualRotaQuery = await client.query(
                `SELECT
                    rota_date,
                    start_time,
                    end_time
                FROM
                    staff_rota
                WHERE
                    staff_id = $1
                    AND business_id = $2
                    AND is_generated = false
                    AND rota_date >= CURRENT_DATE`,
                [staff_id, business_id]
            );

            // Create a lookup map for manual rota entries
            // Key format: 'YYYY-MM-DD'
            const manualRotaEntries = {};

            for (const entry of manualRotaQuery.rows) {
                const dateKey = entry.rota_date.toISOString().split('T')[0];

                if (!manualRotaEntries[dateKey]) {
                    manualRotaEntries[dateKey] = [];
                }

                manualRotaEntries[dateKey].push({
                    start_time: entry.start_time,
                    end_time: entry.end_time
                });
            }

            // Check for conflicts with existing bookings
            // Get all confirmed bookings for this staff member
            const bookingsQuery = await client.query(
                `SELECT
                    b.id AS booking_id,
                    b.booking_date,
                    b.start_time,
                    b.end_time,
                    s.service_name,
                    CONCAT(c.first_name, ' ', c.last_name) AS customer_name
                FROM
                    booking b
                JOIN
                    service s ON b.service_id = s.id
                JOIN
                    app_user c ON b.customer_id = c.id
                WHERE
                    b.staff_id = $1
                    AND b.status = 'confirmed'
                    AND b.booking_date >= CURRENT_DATE
                ORDER BY
                    b.booking_date, b.start_time`,
                [staff_id]
            );

            // If there are bookings, check if they would be orphaned by the new schedule
            if (bookingsQuery.rows.length > 0) {
                // Check each booking against the new schedule and manual rota entries
                for (const booking of bookingsQuery.rows) {
                    const bookingDate = new Date(booking.booking_date);
                    let bookingCovered = false;

                    // Check if any schedule entry covers this booking
                    for (const entry of schedule) {
                        if (isDateInSchedule(bookingDate, entry)) {
                            // Check if the booking time falls within the schedule time
                            if (booking.start_time >= entry.start_time && booking.end_time <= entry.end_time) {
                                bookingCovered = true;
                                break;
                            }
                        }
                    }

                    // If not covered by schedule, check if covered by manual rota entry
                    if (!bookingCovered) {
                        const dateKey = booking.booking_date.toISOString().split('T')[0];
                        const manualEntries = manualRotaEntries[dateKey] || [];

                        for (const manualEntry of manualEntries) {
                            // Check if the booking time falls within the manual rota time
                            if (booking.start_time >= manualEntry.start_time && booking.end_time <= manualEntry.end_time) {
                                bookingCovered = true;
                                break;
                            }
                        }
                    }

                    // If the booking is not covered by any schedule entry or manual rota, it's a conflict
                    if (!bookingCovered) {
                        bookingConflicts.push({
                            booking_id: booking.booking_id,
                            booking_date: booking.booking_date.toISOString().split('T')[0],
                            start_time: booking.start_time,
                            end_time: booking.end_time,
                            service_name: booking.service_name,
                            customer_name: booking.customer_name
                        });
                    }
                }

                // If there are conflicts and force is not true, return an error
                if (bookingConflicts.length > 0 && !forceUpdate) {
                    await client.query('ROLLBACK');
                    return res.status(409).json({
                        return_code: "BOOKING_CONFLICTS",
                        message: "The new schedule conflicts with existing bookings. Use force=true to override or create manual rota entries for these bookings.",
                        conflicts: bookingConflicts
                    });
                }
            }

            // Delete existing generated rota entries for this staff member
            await client.query(
                `DELETE FROM staff_rota
                 WHERE staff_id = $1
                 AND business_id = $2
                 AND is_generated = true`,
                [staff_id, business_id]
            );

            // Delete existing schedule entries for this staff member at this business
            await client.query(
                `DELETE FROM staff_schedule
                 WHERE staff_id = $1
                 AND business_id = $2`,
                [staff_id, business_id]
            );

            // Insert new schedule entries
            for (const entry of schedule) {
                await client.query(
                    `INSERT INTO staff_schedule
                     (staff_id, business_id, day_of_week, start_time, end_time, start_date, end_date, repeat_every_n_weeks)
                     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
                    [
                        staff_id,
                        business_id,
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

            // If there were conflicts but force was true, return success with warnings
            if (bookingConflicts.length > 0) {
                return res.status(200).json({
                    return_code: "SUCCESS_WITH_WARNINGS",
                    message: "Staff schedule updated successfully, but there are booking conflicts. Consider creating manual rota entries for these bookings.",
                    conflicts: bookingConflicts
                });
            }

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
