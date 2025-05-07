/*
=======================================================================================================================================
API Route: delete_staff_rota
=======================================================================================================================================
Method: POST
Purpose: Deletes a staff rota entry
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "rota_id": 15                       // integer, required - ID of the rota entry to delete
}
=======================================================================================================================================
Response:
{
  "return_code": "SUCCESS",
  "message": "Staff rota entry deleted successfully"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /delete_staff_rota
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { rota_id } = req.body;

        // Validate required fields
        if (!rota_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Rota ID is required"
            });
        }

        // Get the rota entry and check if it exists
        const rotaQuery = await pool.query(
            `SELECT sr.id, sr.business_id
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

        // Check if the user has permission to delete staff rota for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to delete staff rota for this business"
            });
        }

        // Delete the rota entry
        await pool.query('DELETE FROM staff_rota WHERE id = $1', [rota_id]);

        // Return success response
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Staff rota entry deleted successfully"
        });
    } catch (error) {
        console.error('Error in delete_staff_rota:', error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while deleting staff rota entry"
        });
    }
});

module.exports = router;
