/*
=======================================================================================================================================
API Route: delete_user_data
=======================================================================================================================================
Method: POST
Purpose: Permanently deletes all user data from the system. This action cannot be undone.
=======================================================================================================================================
Request Payload:
{
  "confirmation": "DELETE_MY_DATA"     // string, required - confirmation phrase
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "All user data has been permanently deleted"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_CONFIRMATION"
"UNAUTHORIZED"
"USER_NOT_FOUND"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/delete_user_data
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{
  "confirmation": "DELETE_MY_DATA"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// POST /delete_user_data
router.post('/', auth, async (req, res) => {
    try {
        // Get user ID from JWT token (set by auth middleware)
        const userId = req.user.id;

        // Extract confirmation from request body
        const { confirmation } = req.body;

        // Check if confirmation is provided
        if (!confirmation) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Confirmation phrase is required"
            });
        }

        // Validate confirmation phrase
        if (confirmation !== "DELETE_MY_DATA") {
            return res.status(400).json({
                return_code: "INVALID_CONFIRMATION",
                message: "Invalid confirmation phrase. Please type 'DELETE_MY_DATA' exactly."
            });
        }

        // Check if user exists
        const userQuery = await pool.query(
            "SELECT id, email FROM app_user WHERE id = $1",
            [userId]
        );

        if (userQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "USER_NOT_FOUND",
                message: "User not found"
            });
        }

        const user = userQuery.rows[0];

        // Start transaction for data deletion
        await pool.query('BEGIN');

        try {
            // Delete user data in order (respecting foreign key constraints)
            
            // 1. Delete from audit_log (if exists)
            await pool.query(
                "DELETE FROM audit_log WHERE appuser_id = $1",
                [userId]
            );

            // 2. Delete from booking (if exists)
            await pool.query(
                "DELETE FROM booking WHERE customer_id = $1 OR staff_id = $1",
                [userId]
            );

            // 3. Delete from staff_rota (if exists)
            await pool.query(
                "DELETE FROM staff_rota WHERE staff_id = $1",
                [userId]
            );

            // 4. Delete from staff_schedule (if exists)
            await pool.query(
                "DELETE FROM staff_schedule WHERE staff_id = $1",
                [userId]
            );

            // 5. Delete from appuser_business_role
            await pool.query(
                "DELETE FROM appuser_business_role WHERE appuser_id = $1",
                [userId]
            );

            // 6. Finally, delete the user record
            await pool.query(
                "DELETE FROM app_user WHERE id = $1",
                [userId]
            );

            // Commit transaction
            await pool.query('COMMIT');

            console.log(`User data deleted successfully for user ID: ${userId}, email: ${user.email}`);

            // Return success response
            return res.status(200).json({
                return_code: "SUCCESS",
                message: "All user data has been permanently deleted"
            });

        } catch (deleteError) {
            // Rollback transaction on error
            await pool.query('ROLLBACK');
            throw deleteError;
        }

    } catch (error) {
        console.error("Delete user data error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while deleting user data: " + error.message
        });
    }
});

module.exports = router;
