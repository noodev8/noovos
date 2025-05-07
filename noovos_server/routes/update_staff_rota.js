/*
=======================================================================================================================================
API Route: update_staff_rota
=======================================================================================================================================
Method: POST
Purpose: Updates an existing staff rota entry
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "rota_id": 15,                      // integer, required - ID of the rota entry to update
  "staff_id": 10,                     // integer, optional - New staff ID (if changing staff)
  "rota_date": "2025-05-01",          // string, optional - New date (YYYY-MM-DD)
  "start_time": "09:00",              // string, optional - New start time (HH:MM)
  "end_time": "17:00"                 // string, optional - New end time (HH:MM)
}
=======================================================================================================================================
Response:
{
  "return_code": "SUCCESS",
  "message": "Staff rota entry updated successfully"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /update_staff_rota
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { rota_id, staff_id, rota_date, start_time, end_time } = req.body;

        // Validate required fields
        if (!rota_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Rota ID is required"
            });
        }

        // Check if at least one field to update is provided
        if (!staff_id && !rota_date && !start_time && !end_time) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "At least one field to update is required"
            });
        }

        // Get the rota entry and check if it exists
        const rotaQuery = await pool.query(
            `SELECT sr.id, sr.staff_id, sr.business_id
             FROM staff_rota sr
             WHERE sr.id = $1`,
            [rota_id]
        );

        if (rotaQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "NOT_FOUND",
                message: "Rota entry not found"
            });
        }

        const business_id = rotaQuery.rows[0].business_id;

        // Check if the user has permission to update staff rota for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to update staff rota for this business"
            });
        }

        // If changing staff, check if new staff belongs to the business
        if (staff_id) {
            const staffQuery = await pool.query(
                `SELECT 1 FROM appuser_business_role
                 WHERE appuser_id = $1 AND business_id = $2 AND status = 'active'`,
                [staff_id, business_id]
            );

            if (staffQuery.rows.length === 0) {
                return res.status(400).json({
                    return_code: "INVALID_STAFF",
                    message: "New staff does not belong to this business or is not active"
                });
            }
        }

        // Build the update query
        let updateQuery = 'UPDATE staff_rota SET ';
        const updateValues = [];
        let paramIndex = 1;

        // Add fields to update
        const updateFields = [];

        if (staff_id) {
            updateFields.push(`staff_id = $${paramIndex++}`);
            updateValues.push(staff_id);
        }

        if (rota_date) {
            updateFields.push(`rota_date = $${paramIndex++}`);
            updateValues.push(rota_date);
        }

        if (start_time) {
            updateFields.push(`start_time = $${paramIndex++}`);
            updateValues.push(start_time);
        }

        if (end_time) {
            updateFields.push(`end_time = $${paramIndex++}`);
            updateValues.push(end_time);
        }

        updateQuery += updateFields.join(', ');
        updateQuery += ` WHERE id = $${paramIndex}`;
        updateValues.push(rota_id);

        // Execute the update
        await pool.query(updateQuery, updateValues);

        // Return success response
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Staff rota entry updated successfully"
        });
    } catch (error) {
        console.error('Error in update_staff_rota:', error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while updating staff rota entry"
        });
    }
});

module.exports = router;
