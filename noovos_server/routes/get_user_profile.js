/*
=======================================================================================================================================
API Route: get_user_profile
=======================================================================================================================================
Method: POST
Purpose: Retrieves the current user's profile information including personal details and account status.
=======================================================================================================================================
Request Payload:
{
  // No additional fields required - user identified by JWT token
}

Success Response:
{
  "return_code": "SUCCESS",
  "user": {
    "id": 123,                         // integer, unique user ID
    "first_name": "John",              // string, user's first name
    "last_name": "Doe",                // string, user's last name
    "email": "user@example.com",       // string, user's email
    "mobile": "1234567890",            // string, user's mobile (optional)
    "email_verified": true,            // boolean, email verification status
    "created_at": "2024-01-01T00:00:00Z", // string, account creation date
    "account_level": "standard"        // string, account level
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"USER_NOT_FOUND"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/get_user_profile
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// POST /get_user_profile
router.post('/', auth, async (req, res) => {
    try {
        // Get user ID from JWT token (set by auth middleware)
        const userId = req.user.id;

        // Get user profile from database
        const userQuery = await pool.query(
            `SELECT id, first_name, last_name, email, mobile, email_verified, created_at
             FROM app_user 
             WHERE id = $1`,
            [userId]
        );

        // Check if user exists
        if (userQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "USER_NOT_FOUND",
                message: "User not found"
            });
        }

        // Get the user from the query result
        const user = userQuery.rows[0];

        // Return success response with user profile
        return res.status(200).json({
            return_code: "SUCCESS",
            user: {
                id: user.id,
                first_name: user.first_name,
                last_name: user.last_name,
                email: user.email,
                mobile: user.mobile,
                email_verified: user.email_verified || false,
                created_at: user.created_at,
                account_level: 'standard'  // Default account level
            }
        });

    } catch (error) {
        console.error("Get user profile error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving user profile: " + error.message
        });
    }
});

module.exports = router;
