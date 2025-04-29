/*
=======================================================================================================================================
API Route: add_staff_rota
=======================================================================================================================================
Method: POST
Purpose: Adds new staff rota entries for a business
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 5,                   // integer, required - ID of the business
  "entries": [                        // array, required - Array of rota entries to add
    {
      "staff_id": 10,                 // integer, required - ID of the staff member
      "rota_date": "2025-05-01",      // string, required - Date for the rota entry (YYYY-MM-DD)
      "start_time": "09:00",          // string, required - Start time (HH:MM)
      "end_time": "17:00"             // string, required - End time (HH:MM)
    },
    ...
  ]
}
=======================================================================================================================================
Response:
{
  "return_code": "SUCCESS",
  "message": "Staff rota entries added successfully",
  "added_count": 5                    // Number of entries added
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /add_staff_rota
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id, entries } = req.body;

        // Validate required fields
        if (!business_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID is required"
            });
        }

        if (!entries || !Array.isArray(entries) || entries.length === 0) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "At least one rota entry is required"
            });
        }

        // Check if the user has permission to add staff rota for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to add staff rota for this business"
            });
        }

        // Validate each entry and check if staff belongs to the business
        for (const entry of entries) {
            // Check required fields
            if (!entry.staff_id || !entry.rota_date || !entry.start_time || !entry.end_time) {
                return res.status(400).json({
                    return_code: "MISSING_FIELDS",
                    message: "Each entry must include staff_id, rota_date, start_time, and end_time"
                });
            }

            // Check if staff belongs to the business
            const staffQuery = await pool.query(
                `SELECT 1 FROM appuser_business_role
                 WHERE appuser_id = $1 AND business_id = $2 AND status = 'active'`,
                [entry.staff_id, business_id]
            );

            if (staffQuery.rows.length === 0) {
                return res.status(400).json({
                    return_code: "INVALID_STAFF",
                    message: `Staff ID ${entry.staff_id} does not belong to this business or is not active`
                });
            }
        }

        // Begin transaction
        const client = await pool.connect();
        try {
            await client.query('BEGIN');

            // Insert each entry
            let addedCount = 0;
            for (const entry of entries) {
                await client.query(
                    `INSERT INTO staff_rota (staff_id, rota_date, start_time, end_time)
                     VALUES ($1, $2, $3, $4)`,
                    [entry.staff_id, entry.rota_date, entry.start_time, entry.end_time]
                );
                addedCount++;
            }

            await client.query('COMMIT');

            // Return success response
            return res.status(200).json({
                return_code: "SUCCESS",
                message: "Staff rota entries added successfully",
                added_count: addedCount
            });
        } catch (error) {
            await client.query('ROLLBACK');
            throw error;
        } finally {
            client.release();
        }
    } catch (error) {
        console.error('Error in add_staff_rota:', error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while adding staff rota entries"
        });
    }
});

module.exports = router;
