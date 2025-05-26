/*
=======================================================================================================================================
Web Route: verify-email
=======================================================================================================================================
Method: GET
Purpose: Handles email verification links clicked from emails. Provides a user-friendly web page for email verification.
=======================================================================================================================================
URL Parameters:
?token=abc123...                     // string, required - verification token from email

Response: HTML page with verification status and instructions
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const { sendVerificationSuccessEmail } = require('../utils/email_service');

// GET /verify-email
router.get('/', async (req, res) => {
    try {
        // Extract token from query parameters
        const { token } = req.query;

        // Check if token is provided
        if (!token) {
            return res.status(400).send(generateHtmlResponse(
                'Invalid Verification Link',
                'The verification link is missing required information.',
                'error',
                null
            ));
        }

        // Find user with the provided verification token
        const userQuery = await pool.query(
            "SELECT * FROM app_user WHERE verification_token = $1",
            [token]
        );

        // Check if token exists
        if (userQuery.rows.length === 0) {
            return res.status(400).send(generateHtmlResponse(
                'Invalid Verification Token',
                'The verification token is invalid or has already been used.',
                'error',
                null
            ));
        }

        // Get the user from the query result
        const user = userQuery.rows[0];

        // Check if email is already verified
        if (user.email_verified === true) {
            return res.status(200).send(generateHtmlResponse(
                'Email Already Verified',
                'Your email address has already been verified. You can now use your account.',
                'success',
                'Continue to App'
            ));
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

            return res.status(400).send(generateHtmlResponse(
                'Verification Token Expired',
                'The verification token has expired. Please request a new verification email from the app.',
                'error',
                null
            ));
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

        // Return success page
        return res.status(200).send(generateHtmlResponse(
            'Email Verified Successfully!',
            `Thank you, ${user.first_name}! Your email address has been verified. You can now use all features of your account.`,
            'success',
            'Continue to App'
        ));

    } catch (error) {
        console.error("Email verification error:", error);
        return res.status(500).send(generateHtmlResponse(
            'Verification Error',
            'An error occurred while verifying your email. Please try again later or contact support.',
            'error',
            null
        ));
    }
});

// Generate HTML response for email verification
function generateHtmlResponse(title, message, type, buttonText) {
    const isSuccess = type === 'success';
    const iconColor = isSuccess ? '#28a745' : '#dc3545';
    const icon = isSuccess ? '✓' : '✗';
    const appUrl = process.env.EMAIL_VERIFICATION_URL || 'https://test.splitleague.noodev8.com';

    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title} - Noovos</title>
        <style>
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                line-height: 1.6;
                margin: 0;
                padding: 20px;
                background-color: #f5f5f5;
                color: #333;
            }
            .container {
                max-width: 500px;
                margin: 50px auto;
                background: white;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                padding: 40px;
                text-align: center;
            }
            .icon {
                font-size: 64px;
                color: ${iconColor};
                margin-bottom: 20px;
                display: block;
            }
            h1 {
                color: ${iconColor};
                margin-bottom: 20px;
                font-size: 24px;
            }
            p {
                margin-bottom: 30px;
                font-size: 16px;
                line-height: 1.5;
            }
            .button {
                display: inline-block;
                background-color: #007bff;
                color: white;
                padding: 12px 24px;
                text-decoration: none;
                border-radius: 5px;
                font-weight: bold;
                margin: 10px;
            }
            .button:hover {
                background-color: #0056b3;
            }
            .footer {
                margin-top: 40px;
                padding-top: 20px;
                border-top: 1px solid #eee;
                font-size: 14px;
                color: #666;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <span class="icon">${icon}</span>
            <h1>${title}</h1>
            <p>${message}</p>
            ${buttonText ? `<a href="${appUrl}" class="button">${buttonText}</a>` : ''}
            <div class="footer">
                <p>&copy; 2024 Noovos. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    `;
}

module.exports = router;
