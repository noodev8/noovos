/*
=======================================================================================================================================
API Route: resend_verification
=======================================================================================================================================
Method: POST
Purpose: Resends email verification email to user. Generates a new verification token and sends a new email.
=======================================================================================================================================
Request Payload:
{
  "email": "user@example.com"         // string, required - user's email address
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Verification email sent successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"USER_NOT_FOUND"
"ALREADY_VERIFIED"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/resend_verification
Content-Type: application/json

{
  "email": "test@example.com"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const { generateToken, sendVerificationEmail } = require('../utils/email_service');

// POST /resend_verification
router.post('/', async (req, res) => {
    try {
        // Extract email from request body
        const { email } = req.body;

        // Check if email is provided
        if (!email) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Email address is required"
            });
        }

        // Find user with the provided email
        const userQuery = await pool.query(
            "SELECT * FROM app_user WHERE email = $1",
            [email]
        );

        // Check if user exists
        if (userQuery.rows.length === 0) {
            // For security reasons, we don't reveal if the email exists or not
            // We return success but don't actually send an email
            return res.status(200).json({
                return_code: "SUCCESS",
                message: "If an account with this email exists and is not verified, a verification email has been sent"
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

        // Generate new verification token (32 bytes = 64 character hex string)
        const verificationToken = generateToken(32);

        // Set token expiration to 24 hours from now
        const tokenExpiration = new Date();
        tokenExpiration.setHours(tokenExpiration.getHours() + 24);

        // Update the verification token and expiration in the database
        await pool.query(
            `UPDATE app_user 
             SET verification_token = $1, verification_expires = $2 
             WHERE id = $3`,
            [verificationToken, tokenExpiration, user.id]
        );

        // Send verification email
        try {
            await sendVerificationEmail(
                user.email,
                `${user.first_name} ${user.last_name}`,
                verificationToken
            );

            console.log(`Verification email resent to: ${user.email}`);

            // Return success response
            return res.status(200).json({
                return_code: "SUCCESS",
                message: "Verification email sent successfully"
            });

        } catch (emailError) {
            console.error("Error sending verification email:", emailError);
            
            // Clear the token from database if email failed
            await pool.query(
                `UPDATE app_user 
                 SET verification_token = NULL, verification_expires = NULL 
                 WHERE id = $1`,
                [user.id]
            );

            return res.status(500).json({
                return_code: "SERVER_ERROR",
                message: "Failed to send verification email. Please try again later."
            });
        }

    } catch (error) {
        console.error("Resend verification error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while resending verification email: " + error.message
        });
    }
});

module.exports = router;
