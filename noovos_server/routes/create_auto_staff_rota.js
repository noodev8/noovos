/*
=======================================================================================================================================
API Route: create_auto_staff_rota
=======================================================================================================================================
Method: POST
Purpose: Automatically generates staff rota entries based on staff schedules for the next 60 days.
         Replaces all future auto-generated entries with new ones based on current schedules.
         Intelligently handles existing manual entries (is_generated=false) by:
         1. Skipping auto-generation for dates with manual entries that cover the entire schedule time
         2. Creating partial entries for remaining time slots when manual entries only cover part of the day
            (e.g., if a manual entry exists for 9:00-12:00 and the schedule is 9:00-17:00,
            it will generate an entry for 12:00-17:00)
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 10,                  // integer, required - ID of the business
  "staff_id": 21                      // integer, optional - ID of the staff member to generate rota for
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Staff rota entries generated successfully",
  "generated_count": 25               // integer - Number of rota entries generated
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Business ID is required"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "You do not have permission to generate rota for this business"
}
{
  "return_code": "NO_SCHEDULES_FOUND",
  "message": "No staff schedules found for this business"
}
{
  "return_code": "INVALID_STAFF",
  "message": "The specified staff member does not belong to this business"
}
{
  "return_code": "SERVER_ERROR",
  "message": "An error occurred while generating staff rota"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// Helper function to convert time string (HH:MM:SS) to minutes since midnight
function convertTimeToMinutes(timeStr) {
    // Handle different time formats
    let hours, minutes, seconds = 0;

    if (typeof timeStr === 'string') {
        const parts = timeStr.split(':');
        hours = parseInt(parts[0], 10);
        minutes = parseInt(parts[1], 10);
        if (parts.length > 2) {
            seconds = parseInt(parts[2], 10);
        }
    } else if (timeStr instanceof Date) {
        hours = timeStr.getHours();
        minutes = timeStr.getMinutes();
        seconds = timeStr.getSeconds();
    } else {
        // If it's already a number, assume it's already in minutes
        return timeStr;
    }

    return hours * 60 + minutes + seconds / 60;
}

// Helper function to convert minutes since midnight back to time string (HH:MM:SS)
function convertMinutesToTime(minutes) {
    const hours = Math.floor(minutes / 60);
    const mins = Math.floor(minutes % 60);

    // Format as HH:MM:00
    return `${hours.toString().padStart(2, '0')}:${mins.toString().padStart(2, '0')}:00`;
}

// Helper function to find non-overlapping time ranges
function findNonOverlappingRanges(scheduleStart, scheduleEnd, manualRanges) {
    // Convert manual ranges to minutes for easier comparison
    const manualRangesInMinutes = manualRanges.map(range => ({
        start: convertTimeToMinutes(range.start_time),
        end: convertTimeToMinutes(range.end_time)
    }));

    // Sort manual ranges by start time
    manualRangesInMinutes.sort((a, b) => a.start - b.start);

    // Find gaps between manual ranges
    const nonOverlappingRanges = [];
    let currentStart = scheduleStart;

    for (const range of manualRangesInMinutes) {
        // If there's a gap before this manual range, add it
        if (currentStart < range.start) {
            nonOverlappingRanges.push({
                start: currentStart,
                end: Math.min(scheduleEnd, range.start)
            });
        }

        // Move current start to after this manual range
        currentStart = Math.max(currentStart, range.end);
    }

    // Add any remaining time after the last manual range
    if (currentStart < scheduleEnd) {
        nonOverlappingRanges.push({
            start: currentStart,
            end: scheduleEnd
        });
    }

    return nonOverlappingRanges;
}

// POST /create_auto_staff_rota
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id, staff_id } = req.body;

        // Validate required fields
        if (!business_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID is required"
            });
        }

        // Check if the user has permission to manage staff rota for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner' AND status = 'active'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to generate rota for this business"
            });
        }

        // If staff_id is provided, validate that the staff member belongs to this business
        if (staff_id) {
            const staffQuery = await pool.query(
                `SELECT 1 FROM appuser_business_role
                 WHERE appuser_id = $1 AND business_id = $2 AND status = 'active'`,
                [staff_id, business_id]
            );

            if (staffQuery.rows.length === 0) {
                return res.status(400).json({
                    return_code: "INVALID_STAFF",
                    message: "The specified staff member does not belong to this business"
                });
            }
        }

        // Begin transaction
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Clean up old history - delete auto-generated entries older than 30 days
            await client.query(
                `DELETE FROM staff_rota
                 WHERE is_generated = TRUE
                 AND rota_date < CURRENT_DATE - INTERVAL '30 days'`
            );

            // Get current date
            const currentDate = new Date();

            // Calculate the date range (60 days from today)
            const endDate = new Date(currentDate);
            endDate.setDate(endDate.getDate() + 59); // 60 days including today

            // Format dates for PostgreSQL
            const formattedCurrentDate = currentDate.toISOString().split('T')[0];
            const formattedEndDate = endDate.toISOString().split('T')[0];

            // Delete future auto-generated entries
            // If staff_id is provided, only delete entries for that staff member
            if (staff_id) {
                await client.query(
                    `DELETE FROM staff_rota
                     WHERE business_id = $1
                     AND staff_id = $2
                     AND is_generated = TRUE
                     AND rota_date >= CURRENT_DATE`,
                    [business_id, staff_id]
                );
            } else {
                // Otherwise delete all future auto-generated entries for this business
                await client.query(
                    `DELETE FROM staff_rota
                     WHERE business_id = $1
                     AND is_generated = TRUE
                     AND rota_date >= CURRENT_DATE`,
                    [business_id]
                );
            }

            // Get staff schedules
            let scheduleCheckQuery;
            if (staff_id) {
                // If staff_id is provided, only get schedules for that staff member
                scheduleCheckQuery = await client.query(
                    `SELECT
                        ss.id,
                        ss.staff_id,
                        ss.day_of_week,
                        ss.start_time,
                        ss.end_time,
                        ss.start_date,
                        ss.end_date,
                        ss.week
                     FROM staff_schedule ss
                     WHERE ss.business_id = $1
                     AND ss.staff_id = $2
                     AND ss.start_date <= $4
                     AND (ss.end_date IS NULL OR ss.end_date >= $3)`,
                    [business_id, staff_id, formattedCurrentDate, formattedEndDate]
                );
            } else {
                // Otherwise get all staff schedules for this business
                scheduleCheckQuery = await client.query(
                    `SELECT
                        ss.id,
                        ss.staff_id,
                        ss.day_of_week,
                        ss.start_time,
                        ss.end_time,
                        ss.start_date,
                        ss.end_date,
                        ss.week
                     FROM staff_schedule ss
                     WHERE ss.business_id = $1
                     AND ss.start_date <= $3
                     AND (ss.end_date IS NULL OR ss.end_date >= $2)`,
                    [business_id, formattedCurrentDate, formattedEndDate]
                );
            }

            if (scheduleCheckQuery.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(404).json({
                    return_code: "NO_SCHEDULES_FOUND",
                    message: "No staff schedules found for this business"
                });
            }

            // Now get all schedules for generating the rota
            // We can reuse the same date variables since we're using the same date range

            // Get staff schedules for generating the rota
            let schedulesQuery;
            if (staff_id) {
                // If staff_id is provided, only get schedules for that staff member
                schedulesQuery = await client.query(
                    `SELECT
                        ss.id,
                        ss.staff_id,
                        ss.day_of_week,
                        ss.start_time,
                        ss.end_time,
                        ss.start_date,
                        ss.end_date,
                        ss.week
                     FROM staff_schedule ss
                     WHERE ss.business_id = $1
                     AND ss.staff_id = $2
                     AND ss.start_date <= $4
                     AND (ss.end_date IS NULL OR ss.end_date >= $3)`,
                    [business_id, staff_id, formattedCurrentDate, formattedEndDate]
                );
            } else {
                // Otherwise get all staff schedules for this business
                schedulesQuery = await client.query(
                    `SELECT
                        ss.id,
                        ss.staff_id,
                        ss.day_of_week,
                        ss.start_time,
                        ss.end_time,
                        ss.start_date,
                        ss.end_date,
                        ss.week
                     FROM staff_schedule ss
                     WHERE ss.business_id = $1
                     AND ss.start_date <= $3
                     AND (ss.end_date IS NULL OR ss.end_date >= $2)`,
                    [business_id, formattedCurrentDate, formattedEndDate]
                );
            }

            if (schedulesQuery.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(404).json({
                    return_code: "NO_SCHEDULES_FOUND",
                    message: "No staff schedules found for this business"
                });
            }

            // Generate rota entries for each schedule
            let generatedCount = 0;

            // Get all dates in the range
            const dateRange = [];
            const tempDate = new Date(currentDate);

            // Make sure we're working with just the date part (no time)
            // Also ensure we're working with UTC dates to avoid time zone issues
            tempDate.setUTCHours(0, 0, 0, 0);

            // Create a proper end date that's 60 days from now
            // Reuse the existing endDate variable
            endDate.setTime(tempDate.getTime());
            endDate.setDate(endDate.getDate() + 59); // 60 days including today

            // Generate all dates in the range
            while (tempDate <= endDate) {
                // Create a new date object for each day to avoid reference issues
                const newDate = new Date(tempDate);
                dateRange.push(newDate);
                tempDate.setDate(tempDate.getDate() + 1);
            }

            // Fetch existing manual entries (is_generated=false) to handle time conflicts
            // We'll respect manual entries by either skipping or adjusting auto-generated entries
            let manualEntriesQuery;
            if (staff_id) {
                // If staff_id is provided, only get manual entries for that staff member
                manualEntriesQuery = await client.query(
                    `SELECT
                        staff_id,
                        TO_CHAR(rota_date, 'YYYY-MM-DD') as rota_date,
                        start_time,
                        end_time
                     FROM staff_rota
                     WHERE business_id = $1
                     AND staff_id = $2
                     AND is_generated = FALSE
                     AND rota_date >= $3
                     AND rota_date <= $4`,
                    [business_id, staff_id, formattedCurrentDate, formattedEndDate]
                );
            } else {
                // Otherwise get all manual entries for this business
                manualEntriesQuery = await client.query(
                    `SELECT
                        staff_id,
                        TO_CHAR(rota_date, 'YYYY-MM-DD') as rota_date,
                        start_time,
                        end_time
                     FROM staff_rota
                     WHERE business_id = $1
                     AND is_generated = FALSE
                     AND rota_date >= $2
                     AND rota_date <= $3`,
                    [business_id, formattedCurrentDate, formattedEndDate]
                );
            }

            // Create a lookup map for quick checking if a manual entry exists
            // The key format is 'staffId-YYYY-MM-DD' and the value is an array of time ranges
            const manualEntries = {};

            for (const entry of manualEntriesQuery.rows) {
                const key = `${entry.staff_id}-${entry.rota_date}`;

                // Initialize array if this is the first entry for this staff/date
                if (!manualEntries[key]) {
                    manualEntries[key] = [];
                }

                // Add the time range to the array
                manualEntries[key].push({
                    start_time: entry.start_time,
                    end_time: entry.end_time
                });
            }

            // Process each schedule
            for (const schedule of schedulesQuery.rows) {
                // Get the day of week for this schedule (e.g., "Monday")
                const scheduleDay = schedule.day_of_week;

                // Process each date in the range
                for (const date of dateRange) {
                    // Get the day of week for this date (0 = Sunday, 1 = Monday, etc.)
                    // Use UTC methods to avoid time zone issues
                    const dayOfWeek = date.getUTCDay();

                    // Convert JavaScript day of week to day name
                    const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
                    const dateDayName = dayNames[dayOfWeek];

                    // Check if this date matches the schedule day
                    if (dateDayName === scheduleDay) {
                        // Check if the date is within the schedule's date range
                        // Parse dates and ensure they're in UTC
                        const scheduleStartDate = new Date(schedule.start_date);
                        scheduleStartDate.setUTCHours(0, 0, 0, 0);

                        let scheduleEndDate = null;
                        if (schedule.end_date) {
                            scheduleEndDate = new Date(schedule.end_date);
                            scheduleEndDate.setUTCHours(0, 0, 0, 0);
                        }

                        if (date >= scheduleStartDate && (!scheduleEndDate || date <= scheduleEndDate)) {
                            // Check week pattern if specified
                            let includeDate = true;
                            if (schedule.week) {
                                // Get the ISO week number (1-53) for the current date
                                // ISO weeks start on Monday (which aligns with day names in the system)
                                const getISOWeek = (date) => {
                                    const d = new Date(date);
                                    d.setHours(0, 0, 0, 0);
                                    // Thursday in current week decides the year
                                    d.setDate(d.getDate() + 3 - (d.getDay() + 6) % 7);
                                    // January 4 is always in week 1
                                    const week1 = new Date(d.getFullYear(), 0, 4);
                                    // Adjust to Thursday in week 1
                                    week1.setDate(week1.getDate() + 3 - (week1.getDay() + 6) % 7);
                                    // Calculate full weeks to nearest Thursday
                                    return 1 + Math.round(((d - week1) / 86400000 - 3 + (week1.getDay() + 6) % 7) / 7);
                                };
                                
                                const currentWeek = getISOWeek(date);
                                
                                // Only include dates where the week matches the schedule's week
                                includeDate = (currentWeek % 2 === schedule.week % 2);

                                if (!includeDate) {
                                    continue;
                                }
                            }

                            // Format the date for PostgreSQL
                            const formattedDate = date.toISOString().split('T')[0];

                            // Check if there are manual entries for this staff member and date
                            const manualEntryKey = `${schedule.staff_id}-${formattedDate}`;
                            const manualTimeRanges = manualEntries[manualEntryKey];

                            if (manualTimeRanges && manualTimeRanges.length > 0) {
                                // There are manual entries for this date
                                // We need to check if we can generate non-overlapping entries

                                // Convert schedule times to comparable format (minutes since midnight)
                                const scheduleStartMinutes = convertTimeToMinutes(schedule.start_time);
                                const scheduleEndMinutes = convertTimeToMinutes(schedule.end_time);

                                // Find all non-overlapping time ranges
                                const nonOverlappingRanges = findNonOverlappingRanges(
                                    scheduleStartMinutes,
                                    scheduleEndMinutes,
                                    manualTimeRanges
                                );

                                // If there are no non-overlapping ranges, skip this date
                                if (nonOverlappingRanges.length === 0) {
                                    continue;
                                }

                                // Generate entries for each non-overlapping range
                                for (const range of nonOverlappingRanges) {
                                    // Convert minutes back to time format
                                    const rangeStartTime = convertMinutesToTime(range.start);
                                    const rangeEndTime = convertMinutesToTime(range.end);

                                    // Insert rota entry for this time range
                                    try {
                                        await client.query(
                                            `INSERT INTO staff_rota
                                             (staff_id, rota_date, start_time, end_time, business_id, is_generated)
                                             VALUES ($1, $2, $3, $4, $5, TRUE)`,
                                            [
                                                schedule.staff_id,
                                                formattedDate,
                                                rangeStartTime,
                                                rangeEndTime,
                                                business_id
                                            ]
                                        );

                                        generatedCount++;
                                    } catch (insertError) {
                                        console.error(`Error inserting rota entry: ${insertError.message}`);
                                        // Continue processing other ranges even if one insert fails
                                    }
                                }

                                // Skip the normal insertion since we've handled this date with custom ranges
                                continue;
                            }

                            // Insert rota entry
                            try {
                                await client.query(
                                    `INSERT INTO staff_rota
                                     (staff_id, rota_date, start_time, end_time, business_id, is_generated)
                                     VALUES ($1, $2, $3, $4, $5, TRUE)`,
                                    [
                                        schedule.staff_id,
                                        formattedDate,
                                        schedule.start_time,
                                        schedule.end_time,
                                        business_id
                                    ]
                                );

                                generatedCount++;
                            } catch (insertError) {
                                console.error(`Error inserting rota entry: ${insertError.message}`);
                                // Continue processing other dates even if one insert fails
                            }
                        }
                    }
                }
            }

            await client.query('COMMIT');

            // Return success response
            return res.status(200).json({
                return_code: "SUCCESS",
                message: "Staff rota entries generated successfully",
                generated_count: generatedCount
            });
        } catch (error) {
            await client.query('ROLLBACK');
            console.error('Error in create_auto_staff_rota:', error);

            return res.status(500).json({
                return_code: "SERVER_ERROR",
                message: "An error occurred while generating staff rota"
            });
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Error in create_auto_staff_rota:', error);

        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
