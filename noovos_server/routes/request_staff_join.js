/*
=======================================================================================================================================
API Route: request_staff_join
=======================================================================================================================================
Method: POST
Purpose: Allows business owners to send staff join requests by email
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 5,                   // integer, required - ID of the business
  "email": "staff@example.com"        // string, required - Email of the user to invite as staff
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Staff join request sent successfully"
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Business ID and email are required"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "You do not have permission to manage this business"
}
{
  "return_code": "USER_NOT_FOUND",
  "message": "User with this email does not exist"
}
{
  "return_code": "ALREADY_STAFF",
  "message": "This user is already a staff member for this business"
}
{
  "return_code": "REQUEST_ALREADY_SENT",
  "message": "A request has already been sent to this user"
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

// POST /request_staff_join
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id, email } = req.body;

        // Validate required fields
        if (!business_id || !email) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID and email are required"
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

        // Check if the user with the provided email exists
        const userQuery = await pool.query(
            "SELECT id FROM app_user WHERE email = $1",
            [email]
        );

        if (userQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "USER_NOT_FOUND",
                message: "User with this email does not exist"
            });
        }

        const staffUserId = userQuery.rows[0].id;

        // Check if the user is already a staff member for this business
        const existingRoleQuery = await pool.query(
            `SELECT id, status FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2`,
            [staffUserId, business_id]
        );

        if (existingRoleQuery.rows.length > 0) {
            const existingRole = existingRoleQuery.rows[0];

            // If the user already has an active role
            if (existingRole.status === 'active') {
                return res.status(400).json({
                    return_code: "ALREADY_STAFF",
                    message: "This user is already a staff member for this business"
                });
            }

            // If there's already a pending request
            if (existingRole.status === 'pending') {
                return res.status(400).json({
                    return_code: "REQUEST_ALREADY_SENT",
                    message: "A request has already been sent to this user"
                });
            }
        }

        // Create a new staff join request
        await pool.query(
            `INSERT INTO appuser_business_role (appuser_id, business_id, role, status, requested_at)
             VALUES ($1, $2, 'Staff', 'pending', NOW())`,
            [staffUserId, business_id]
        );

        // Return success response
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Staff join request sent successfully"
        });

    } catch (error) {
        console.error("Error in request_staff_join:", error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
