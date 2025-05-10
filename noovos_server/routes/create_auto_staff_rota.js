/*
=======================================================================================================================================
API Route: create_auto_staff_rota
=======================================================================================================================================
Method: POST
Purpose: Automatically generates staff rota entries based on staff schedules for the next 60 days.
         Replaces all future auto-generated entries with new ones based on current schedules.
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 10                   // integer, required - ID of the business
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
  "return_code": "SERVER_ERROR",
  "message": "An error occurred while generating staff rota"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /create_auto_staff_rota
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id } = req.body;

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

            // Delete all future auto-generated entries for this business
            // This simplifies the approach by replacing the entire future schedule
            await client.query(
                `DELETE FROM staff_rota
                 WHERE business_id = $1
                 AND is_generated = TRUE
                 AND rota_date >= CURRENT_DATE`,
                [business_id]
            );

            // Get all staff schedules for this business
            const scheduleCheckQuery = await client.query(
                `SELECT
                    ss.id,
                    ss.staff_id,
                    ss.day_of_week,
                    ss.start_time,
                    ss.end_time,
                    ss.start_date,
                    ss.end_date,
                    ss.repeat_every_n_weeks
                 FROM staff_schedule ss
                 WHERE ss.business_id = $1
                 AND ss.start_date <= $3
                 AND (ss.end_date IS NULL OR ss.end_date >= $2)`,
                [business_id, formattedCurrentDate, formattedEndDate]
            );

            if (scheduleCheckQuery.rows.length === 0) {
                await client.query('ROLLBACK');
                return res.status(404).json({
                    return_code: "NO_SCHEDULES_FOUND",
                    message: "No staff schedules found for this business"
                });
            }

            // Now get all schedules for generating the rota
            // We'll look ahead for 10 days
            // We can reuse the same date variables since we're using the same date range

            // Get all staff schedules for this business
            const schedulesQuery = await client.query(
                `SELECT
                    ss.id,
                    ss.staff_id,
                    ss.day_of_week,
                    ss.start_time,
                    ss.end_time,
                    ss.start_date,
                    ss.end_date,
                    ss.repeat_every_n_weeks
                 FROM staff_schedule ss
                 WHERE ss.business_id = $1
                 AND ss.start_date <= $3
                 AND (ss.end_date IS NULL OR ss.end_date >= $2)`,
                [business_id, formattedCurrentDate, formattedEndDate]
            );

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
            tempDate.setHours(0, 0, 0, 0);

            // Create a proper end date that's 60 days from now
            // Reuse the existing endDate variable
            endDate.setTime(tempDate.getTime());
            endDate.setDate(endDate.getDate() + 59); // 60 days including today

            // Generate all dates in the range
            while (tempDate <= endDate) {
                dateRange.push(new Date(tempDate));
                tempDate.setDate(tempDate.getDate() + 1);
            }

            // Process each schedule
            for (const schedule of schedulesQuery.rows) {
                // Get the day of week for this schedule (e.g., "Monday")
                const scheduleDay = schedule.day_of_week;

                // Process each date in the range
                for (const date of dateRange) {
                    // Get the day of week for this date (0 = Sunday, 1 = Monday, etc.)
                    const dayOfWeek = date.getDay();

                    // Convert JavaScript day of week to day name
                    const dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
                    const dateDayName = dayNames[dayOfWeek];

                    // Check if this date matches the schedule day
                    if (dateDayName === scheduleDay) {
                        // Check if the date is within the schedule's date range
                        const scheduleStartDate = new Date(schedule.start_date);
                        const scheduleEndDate = schedule.end_date ? new Date(schedule.end_date) : null;

                        if (date >= scheduleStartDate && (!scheduleEndDate || date <= scheduleEndDate)) {
                            // Check repeat pattern if specified
                            let includeDate = true;
                            if (schedule.repeat_every_n_weeks) {
                                // Calculate weeks between schedule start date and current date
                                const weeksDiff = Math.floor((date - scheduleStartDate) / (7 * 24 * 60 * 60 * 1000));

                                // Only include dates that match the repeat pattern
                                includeDate = (weeksDiff % schedule.repeat_every_n_weeks === 0);

                                if (!includeDate) {
                                    continue;
                                }
                            }

                            // Format the date for PostgreSQL
                            const formattedDate = date.toISOString().split('T')[0];

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
