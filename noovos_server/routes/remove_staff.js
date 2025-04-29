/*
=======================================================================================================================================
API Route: remove_staff
=======================================================================================================================================
Method: POST
Purpose: Allows business owners to remove staff members from their business
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 5,                   // integer, required - ID of the business
  "appuser_id": 10                    // integer, required - ID of the app user to remove
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Staff member removed successfully"
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Business ID and app user ID are required"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "You do not have permission to manage this business"
}
{
  "return_code": "STAFF_NOT_FOUND",
  "message": "Staff member not found for this business"
}
{
  "return_code": "CANNOT_REMOVE_SELF",
  "message": "You cannot remove yourself as a business owner"
}
{
  "return_code": "SERVER_ERROR",
  "message": "An error occurred while processing your request"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /remove_staff
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id, appuser_id } = req.body;

        // Validate required fields
        if (!business_id || !appuser_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID and app user ID are required"
            });
        }

        // Check if the user has permission to manage this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to manage this business"
            });
        }

        // Check if the user is trying to remove themselves
        if (parseInt(userId) === parseInt(appuser_id)) {
            return res.status(400).json({
                return_code: "CANNOT_REMOVE_SELF",
                message: "You cannot remove yourself as a business owner"
            });
        }

        // Check if the staff member exists for this business
        const staffQuery = await pool.query(
            `SELECT id, role FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2`,
            [appuser_id, business_id]
        );

        if (staffQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "STAFF_NOT_FOUND",
                message: "Staff member not found for this business"
            });
        }

        // Check if the staff member is a business owner
        const staffRole = staffQuery.rows[0].role;
        if (staffRole && staffRole.toLowerCase() === 'business_owner') {
            return res.status(400).json({
                return_code: "CANNOT_REMOVE_BUSINESS_OWNER",
                message: "Business owners cannot be removed from the staff list"
            });
        }

        // Remove the staff member
        await pool.query(
            `DELETE FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2`,
            [appuser_id, business_id]
        );

        // Return success response
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Staff member removed successfully"
        });

    } catch (error) {
        console.error("Error in remove_staff:", error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
