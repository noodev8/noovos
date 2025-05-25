/*
=======================================================================================================================================
API Route: reset_password
=======================================================================================================================================
Method: POST
Purpose: Handles password reset requests and processes password reset tokens. Supports both requesting a reset and setting a new password.
=======================================================================================================================================
Request Payload for Password Reset Request:
{
  "email": "user@example.com"         // string, required - user's email address
}

Request Payload for Password Reset Confirmation:
{
  "token": "abc123...",               // string, required - reset token from email
  "new_password": "newpassword123"    // string, required - new password
}

Success Response for Reset Request:
{
  "return_code": "SUCCESS",
  "message": "Password reset email sent successfully"
}

Success Response for Password Reset:
{
  "return_code": "SUCCESS",
  "message": "Password reset successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"USER_NOT_FOUND"
"INVALID_TOKEN"
"TOKEN_EXPIRED"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/reset_password
Content-Type: application/json

For reset request:
{
  "email": "test@example.com"
}

For password reset:
{
  "token": "your_reset_token_here",
  "new_password": "newpassword123"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const pool = require('../db');
const { generateToken, sendPasswordResetEmail, sendPasswordChangeConfirmationEmail } = require('../utils/email_service');

// POST /reset_password
router.post('/', async (req, res) => {
    try {
        // Extract parameters from request body
        const { email, token, new_password } = req.body;

        // Determine if this is a reset request or password reset confirmation
        if (token && new_password) {
            // This is a password reset confirmation with token
            return await handlePasswordReset(req, res, token, new_password);
        } else if (email) {
            // This is a password reset request
            return await handlePasswordResetRequest(req, res, email);
        } else {
            // Missing required fields
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Either email (for reset request) or token and new_password (for reset confirmation) are required"
            });
        }

    } catch (error) {
        console.error("Password reset error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred during password reset: " + error.message
        });
    }
});

/**
 * Handle password reset request - send reset email
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {string} email - User's email address
 */
async function handlePasswordResetRequest(req, res, email) {
    // Check if user exists with the provided email
    const userQuery = await pool.query(
        "SELECT * FROM app_user WHERE email = $1",
        [email]
    );

    // If user doesn't exist, return error (but don't reveal this for security)
    if (userQuery.rows.length === 0) {
        // For security reasons, we don't reveal if the email exists or not
        // We return success but don't actually send an email
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "If an account with this email exists, a password reset email has been sent"
        });
    }

    // Get the user from the query result
    const user = userQuery.rows[0];

    // Generate reset token (32 bytes = 64 character hex string)
    const resetToken = generateToken(32);

    // Set token expiration to 1 hour from now
    const tokenExpiration = new Date();
    tokenExpiration.setHours(tokenExpiration.getHours() + 1);

    // Store the reset token and expiration in the database
    // We'll reuse the verification_token and verification_expires fields for password reset
    await pool.query(
        `UPDATE app_user
         SET verification_token = $1, verification_expires = $2
         WHERE id = $3`,
        [resetToken, tokenExpiration, user.id]
    );

    // Send password reset email
    try {
        await sendPasswordResetEmail(
            user.email,
            `${user.first_name} ${user.last_name}`,
            resetToken
        );

        console.log(`Password reset email sent to: ${user.email}`);

        // Return success response
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Password reset email sent successfully"
        });

    } catch (emailError) {
        console.error("Error sending password reset email:", emailError);

        // Clear the token from database if email failed
        await pool.query(
            `UPDATE app_user
             SET verification_token = NULL, verification_expires = NULL
             WHERE id = $1`,
            [user.id]
        );

        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "Failed to send password reset email. Please try again later."
        });
    }
}

/**
 * Handle password reset confirmation - reset the password
 * @param {Object} req - Express request object
 * @param {Object} res - Express response object
 * @param {string} token - Reset token from email
 * @param {string} newPassword - New password
 */
async function handlePasswordReset(req, res, token, newPassword) {
    // Validate new password
    if (!newPassword || newPassword.length < 6) {
        return res.status(400).json({
            return_code: "MISSING_FIELDS",
            message: "New password must be at least 6 characters long"
        });
    }

    // Find user with the provided reset token
    const userQuery = await pool.query(
        "SELECT * FROM app_user WHERE verification_token = $1",
        [token]
    );

    // Check if token exists
    if (userQuery.rows.length === 0) {
        return res.status(400).json({
            return_code: "INVALID_TOKEN",
            message: "Invalid or expired reset token"
        });
    }

    // Get the user from the query result
    const user = userQuery.rows[0];

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
            message: "Reset token has expired. Please request a new password reset."
        });
    }

    // Hash the new password
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update user's password and clear the reset token
    await pool.query(
        `UPDATE app_user
         SET password_hash = $1, verification_token = NULL, verification_expires = NULL
         WHERE id = $2`,
        [newPasswordHash, user.id]
    );

    // Send password change confirmation email
    try {
        await sendPasswordChangeConfirmationEmail(
            user.email,
            `${user.first_name} ${user.last_name}`
        );

        console.log(`Password change confirmation email sent to: ${user.email}`);
    } catch (emailError) {
        // Log error but don't fail the password reset process
        console.error("Error sending password change confirmation email:", emailError);
    }

    console.log(`Password reset successfully for user: ${user.email}`);

    // Return success response
    return res.status(200).json({
        return_code: "SUCCESS",
        message: "Password reset successfully"
    });
}

module.exports = router;
