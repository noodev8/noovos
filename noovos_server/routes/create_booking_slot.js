/*
=======================================================================================================================================
API Route: create_booking_slot
=======================================================================================================================================
Method: POST
Purpose: Creates one or more booking slots for a service. Can create a single slot or multiple slots in a date range.
=======================================================================================================================================
Request Payload (Single Slot):
{
  "service_id": 7,                           // integer, required - ID of the service
  "appuser_id": 10,                          // integer or null, optional - ID of the user to assign (defaults to null for unassigned slots)
  "slot_start": "2025-05-04T09:00:00+01:00", // string, required - Start time of the slot (ISO format with timezone)
  "slot_end": "2025-05-04T09:45:00+01:00"    // string, required - End time of the slot (ISO format with timezone)
}

Request Payload (Multiple Slots):
{
  "service_id": 7,                           // integer, required - ID of the service
  "appuser_id": 10,                          // integer or null, optional - ID of the user to assign (defaults to null for unassigned slots)
  "window_start": "2025-05-04T09:00:00+01:00", // string, required - Start of the time window (ISO format with timezone)
  "window_end": "2025-05-04T17:00:00+01:00",   // string, required - End of the time window (ISO format with timezone)
  "slot_interval": "45 minutes"              // string, required - Duration of each slot (PostgreSQL interval format)
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Booking slot(s) created successfully",
  "slots_created": 1,                        // integer - Number of slots created
  "slots": [                                 // array of created slots (limited to 10 for large batches)
    {
      "id": 123,                             // integer - Slot ID
      "service_id": 7,                       // integer - Service ID
      "appuser_id": 10,                      // integer or null - Staff member ID
      "slot_start": "2025-05-04T09:00:00+01:00", // string - Start time (ISO format)
      "slot_end": "2025-05-04T09:45:00+01:00"    // string - End time (ISO format)
    }
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"MISSING_FIELDS"
"INVALID_SERVICE"
"INVALID_USER"        // User doesn't exist or is not a staff member for this business
"INVALID_PARAMETERS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// POST /create_booking_slot
router.post('/', auth, async (req, res) => {
    try {
        // Extract user ID from the JWT token
        const userId = req.user.id;

        // Determine if we're creating a single slot or multiple slots
        const isSingleSlot = req.body.slot_start && req.body.slot_end;
        const isMultipleSlots = req.body.window_start && req.body.window_end && req.body.slot_interval;

        // Validate that we're either creating a single slot or multiple slots
        if (!isSingleSlot && !isMultipleSlots) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "For single slot: service_id, slot_start, and slot_end are required. For multiple slots: service_id, window_start, window_end, and slot_interval are required."
            });
        }

        // Extract common parameters
        const { service_id } = req.body;
        // Use the provided appuser_id if available, otherwise set to null (unassigned)
        // This creates unassigned slots by default
        const appuser_id = req.body.appuser_id !== undefined ? req.body.appuser_id : null;

        // Validate service_id
        if (!service_id || isNaN(parseInt(service_id))) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid service_id is required"
            });
        }

        // Check if the service exists and get the business_id
        const serviceQuery = await pool.query(
            "SELECT business_id FROM service WHERE id = $1 AND active = true",
            [service_id]
        );

        if (serviceQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "INVALID_SERVICE",
                message: "Service not found or inactive"
            });
        }

        const businessId = serviceQuery.rows[0].business_id;

        // Check if the user has permission to create slots for this business
        const roleQuery = await pool.query(
            "SELECT role FROM appuser_business_role WHERE appuser_id = $1 AND business_id = $2 AND role IN ('staff', 'business_owner')",
            [userId, businessId]
        );

        if (roleQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to create booking slots for this business"
            });
        }

        // Validate that appuser_id is a valid integer or null
        if (appuser_id !== null && isNaN(parseInt(appuser_id))) {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "appuser_id must be a valid integer or null"
            });
        }

        // Check if the user exists and is a staff member for this business (only if appuser_id is not null)
        if (appuser_id !== null) {
            // First check if the user exists
            const userQuery = await pool.query(
                "SELECT 1 FROM app_user WHERE id = $1",
                [appuser_id]
            );

            if (userQuery.rows.length === 0) {
                return res.status(400).json({
                    return_code: "INVALID_USER",
                    message: "The specified user does not exist"
                });
            }

            // Then check if the user is a staff member for this business
            const staffQuery = await pool.query(
                `SELECT 1 FROM staff
                 WHERE appuser_id = $1 AND business_id = $2 AND is_active = true`,
                [appuser_id, businessId]
            );

            if (staffQuery.rows.length === 0) {
                return res.status(400).json({
                    return_code: "INVALID_USER",
                    message: "The specified user is not an active staff member for this business"
                });
            }
        }

        let createdSlots = [];
        let slotsCreated = 0;

        // Create a single slot
        if (isSingleSlot) {
            const { slot_start, slot_end } = req.body;

            // Validate slot times
            if (!slot_start || !slot_end) {
                return res.status(400).json({
                    return_code: "MISSING_FIELDS",
                    message: "slot_start and slot_end are required for creating a single slot"
                });
            }

            // Validate that slot_end is after slot_start
            const startDate = new Date(slot_start);
            const endDate = new Date(slot_end);

            if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
                return res.status(400).json({
                    return_code: "INVALID_PARAMETERS",
                    message: "Invalid date format. Use ISO format with timezone (e.g., '2025-05-04T09:00:00+01:00')"
                });
            }

            if (startDate >= endDate) {
                return res.status(400).json({
                    return_code: "INVALID_PARAMETERS",
                    message: "slot_end must be after slot_start"
                });
            }

            // Insert the slot
            const insertResult = await pool.query(
                `INSERT INTO available_slot (service_id, appuser_id, slot_start, slot_end)
                VALUES ($1, $2, $3, $4)
                RETURNING id, service_id, appuser_id, slot_start, slot_end`,
                [service_id, appuser_id || null, slot_start, slot_end]
            );

            createdSlots = insertResult.rows;
            slotsCreated = 1;
        }
        // Create multiple slots
        else if (isMultipleSlots) {
            const { window_start, window_end, slot_interval } = req.body;

            // Validate window times
            if (!window_start || !window_end || !slot_interval) {
                return res.status(400).json({
                    return_code: "MISSING_FIELDS",
                    message: "window_start, window_end, and slot_interval are required for creating multiple slots"
                });
            }

            // Validate that window_end is after window_start
            const startDate = new Date(window_start);
            const endDate = new Date(window_end);

            if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
                return res.status(400).json({
                    return_code: "INVALID_PARAMETERS",
                    message: "Invalid date format. Use ISO format with timezone (e.g., '2025-05-04T09:00:00+01:00')"
                });
            }

            if (startDate >= endDate) {
                return res.status(400).json({
                    return_code: "INVALID_PARAMETERS",
                    message: "window_end must be after window_start"
                });
            }

            // Insert multiple slots using generate_series
            const insertResult = await pool.query(
                `WITH inserted_slots AS (
                    INSERT INTO available_slot (service_id, appuser_id, slot_start, slot_end)
                    SELECT
                        $1,
                        $2,
                        gs AS slot_start,
                        gs + $3::interval AS slot_end
                    FROM generate_series(
                        $4::timestamptz,
                        $5::timestamptz - $3::interval,
                        $3::interval
                    ) AS gs
                    RETURNING id, service_id, appuser_id, slot_start, slot_end
                )
                SELECT COUNT(*) AS total_inserted,
                       (SELECT json_agg(s) FROM (SELECT * FROM inserted_slots LIMIT 10) s) AS sample_slots
                FROM inserted_slots`,
                [service_id, appuser_id || null, slot_interval, window_start, window_end]
            );

            slotsCreated = parseInt(insertResult.rows[0].total_inserted);
            createdSlots = insertResult.rows[0].sample_slots || [];
        }

        // Return success response
        return res.status(201).json({
            return_code: "SUCCESS",
            message: "Booking slot(s) created successfully",
            slots_created: slotsCreated,
            slots: createdSlots
        });

    } catch (error) {
        console.error("Create booking slot error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Handle specific database errors
        if (error.code === '22007' || error.code === '22008') {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "Invalid date format or interval format"
            });
        }

        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while creating booking slot(s): " + error.message
        });
    }
});

module.exports = router;
