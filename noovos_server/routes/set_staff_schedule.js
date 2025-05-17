/*
=======================================================================================================================================
API Route: set_staff_schedule
=======================================================================================================================================
Method: POST
Purpose: Applies a new schedule to the database for a staff member.
         Replaces any existing schedule entries for the staff member.
         Validates that new schedule entries do not overlap with each other.
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 5,                   // integer, required - ID of the business
  "staff_id": 10,                     // integer, required - ID of the staff member
  "schedule": [                       // array, required - Array of schedule entries
    {
      "day_of_week": "Monday",        // string, required - Day of the week (Monday, Tuesday, etc.)
      "start_time": "09:00",          // string, required - Start time in 24hr format (HH:MM)
      "end_time": "17:00",            // string, required - End time in 24hr format (HH:MM)
      "start_date": "2023-06-01",     // string, required - Start date (YYYY-MM-DD)
      "end_date": "2023-12-31",       // string, optional - End date (YYYY-MM-DD)
      "repeat_every_n_weeks": 1       // integer, optional - Repeat frequency in weeks
    },
    ...
  ],
  "force": false                    // boolean, optional - Bypass schedule overlap checks
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Staff schedule updated successfully"
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
  "message": "End time must be after or equal to start time"
}
{
  "return_code": "INVALID_FORMAT",
  "message": "Invalid time format. Use 24-hour format HH:MM (e.g. 09:00, 17:30)"
}
{
  "return_code": "SCHEDULE_OVERLAP",
  "message": "Schedule entries overlap on [day] between [time1] and [time2]"
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
                // Helper function to parse time string to minutes for 24-hour format
                function parseTimeToMinutes(timeStr) {
                    // Remove any whitespace
                    timeStr = timeStr.trim();

                    // Split into hours and minutes
                    const parts = timeStr.split(':');
                    if (parts.length === 2) {
                        const hours = parseInt(parts[0], 10);
                        const minutes = parseInt(parts[1], 10);

                        // Validate hours and minutes for 24-hour format
                        if (hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
                            return -1;
                        }

                        return hours * 60 + minutes;
                    }

                    return -1; // Invalid format
                }

                // Parse times to minutes
                const startMinutes = parseTimeToMinutes(entry.start_time);
                const endMinutes = parseTimeToMinutes(entry.end_time);

                if (startMinutes >= 0 && endMinutes >= 0) {
                    if (startMinutes > endMinutes) {
                        await client.query('ROLLBACK');
                        return res.status(400).json({
                            return_code: "INVALID_TIME",
                            message: "End time must be after or equal to start time"
                        });
                    }
                } else {
                    await client.query('ROLLBACK');
                    return res.status(400).json({
                        return_code: "INVALID_FORMAT",
                        message: "Invalid time format. Use 24-hour format HH:MM (e.g. 09:00, 17:30)"
                    });
                }
            }

            // Check for overlapping schedules within the same request
            // Skip if force parameter is true (used for multi-week schedules)
            if (!force) {
                // Group schedules by day and repeat week pattern
                const schedulesByDayAndWeek = {};
                
                for (const entry of schedule) {
                    // Create a key that combines day_of_week with repeat pattern information
                    const repeatWeeks = entry.repeat_every_n_weeks || 1;
                    
                    // Parse the week offset from the start date (for multi-week schedules)
                    let weekOffset = 0;
                    if (repeatWeeks > 1) {
                        const startDate = new Date(entry.start_date);
                        const baseDate = new Date(schedule[0].start_date); // Use first entry as reference
                        const msPerWeek = 7 * 24 * 60 * 60 * 1000;
                        const weeksDiff = Math.round((startDate - baseDate) / msPerWeek);
                        weekOffset = weeksDiff % repeatWeeks;
                    }
                    
                    // Create a key that includes the day and its position in the repeat cycle
                    const key = `${entry.day_of_week}_week${weekOffset}_repeat${repeatWeeks}`;
                    
                    if (!schedulesByDayAndWeek[key]) {
                        schedulesByDayAndWeek[key] = [];
                    }
                    
                    schedulesByDayAndWeek[key].push({
                        start: parseTimeToMinutes(entry.start_time),
                        end: parseTimeToMinutes(entry.end_time),
                        startTime: entry.start_time,
                        endTime: entry.end_time,
                        repeat: repeatWeeks,
                        offset: weekOffset
                    });
                }

                // Check each day/week pattern group for overlaps
                for (const [key, times] of Object.entries(schedulesByDayAndWeek)) {
                    // Sort by start time to make overlap checking easier
                    times.sort((a, b) => a.start - b.start);
                    
                    // Check consecutive pairs for overlap
                    for (let i = 0; i < times.length - 1; i++) {
                        if (times[i].end > times[i + 1].start) {
                            await client.query('ROLLBACK');
                            const [day] = key.split('_');
                            return res.status(400).json({
                                return_code: "SCHEDULE_OVERLAP",
                                message: `Schedule entries overlap on ${day} between ${times[i].startTime}-${times[i].endTime} and ${times[i + 1].startTime}-${times[i + 1].endTime}`
                            });
                        }
                    }
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

            // Return success response
            return res.status(200).json({
                return_code: "SUCCESS",
                message: "Staff schedule updated successfully"
            });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Error in set_staff_schedule:', error);
        
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while updating the staff schedule"
        });
    }
});

module.exports = router;
