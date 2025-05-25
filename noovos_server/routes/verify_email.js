/*
=======================================================================================================================================
API Route: verify_email
=======================================================================================================================================
Method: POST
Purpose: Verifies user email address using verification token sent via email during registration.
=======================================================================================================================================
Request Payload:
{
  "token": "abc123..."                // string, required - verification token from email
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Email verified successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_TOKEN"
"TOKEN_EXPIRED"
"ALREADY_VERIFIED"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/verify_email
Content-Type: application/json

{
  "token": "your_verification_token_here"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const { sendVerificationSuccessEmail } = require('../utils/email_service');

// POST /verify_email
router.post('/', async (req, res) => {
    try {
        // Extract token from request body
        const { token } = req.body;

        // Check if token is provided
        if (!token) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Verification token is required"
            });
        }

        // Find user with the provided verification token
        const userQuery = await pool.query(
            "SELECT * FROM app_user WHERE verification_token = $1",
            [token]
        );

        // Check if token exists
        if (userQuery.rows.length === 0) {
            return res.status(400).json({
                return_code: "INVALID_TOKEN",
                message: "Invalid verification token"
            });
        }

        // Get the user from the query result
        const user = userQuery.rows[0];

        // Check if email is already verified
        if (user.email_verified === true) {
            return res.status(400).json({
                return_code: "ALREADY_VERIFIED",
                message: "Email address is already verified"
            });
        }

        // Check if token has expired
        const now = new Date();
        const tokenExpiration = new Date(user.verification_expires);

        if (now > tokenExpiration) {
            // Clear expired token
            await pool.query(
                `UPDATE app_user 
                 SET verification_token = NULL, verification_expires = NULL 
                 WHERE id = $1`,
                [user.id]
            );

            return res.status(400).json({
                return_code: "TOKEN_EXPIRED",
                message: "Verification token has expired. Please request a new verification email."
            });
        }

        // Mark email as verified and clear the verification token
        await pool.query(
            `UPDATE app_user 
             SET email_verified = true, verification_token = NULL, verification_expires = NULL 
             WHERE id = $1`,
            [user.id]
        );

        // Send verification success email
        try {
            await sendVerificationSuccessEmail(
                user.email,
                `${user.first_name} ${user.last_name}`
            );

            console.log(`Verification success email sent to: ${user.email}`);
        } catch (emailError) {
            // Log error but don't fail the verification process
            console.error("Error sending verification success email:", emailError);
        }

        console.log(`Email verified successfully for user: ${user.email}`);

        // Return success response
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Email verified successfully"
        });

    } catch (error) {
        console.error("Email verification error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred during email verification: " + error.message
        });
    }
});

module.exports = router;
