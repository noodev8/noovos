/*
=======================================================================================================================================
Web Route: reset-password
=======================================================================================================================================
Method: GET
Purpose: Handles password reset links clicked from emails. Provides a user-friendly web page for password reset.
=======================================================================================================================================
URL Parameters:
?token=abc123...                     // string, required - reset token from email

Response: HTML page with password reset form or instructions
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// GET /reset-password
router.get('/', async (req, res) => {
    try {
        // Extract token from query parameters
        const { token } = req.query;

        // Check if token is provided
        if (!token) {
            return res.status(400).send(generateHtmlResponse(
                'Invalid Reset Link',
                'The password reset link is missing required information.',
                'error',
                null
            ));
        }

        // Find user with the provided reset token
        const userQuery = await pool.query(
            "SELECT * FROM app_user WHERE verification_token = $1",
            [token]
        );

        // Check if token exists
        if (userQuery.rows.length === 0) {
            return res.status(400).send(generateHtmlResponse(
                'Invalid Reset Token',
                'The password reset token is invalid or has already been used.',
                'error',
                null
            ));
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

            return res.status(400).send(generateHtmlResponse(
                'Reset Token Expired',
                'The password reset token has expired. Please request a new password reset from the app.',
                'error',
                null
            ));
        }

        // Return success page with instructions to use the app
        return res.status(200).send(generateHtmlResponse(
            'Password Reset Available',
            `Hello ${user.first_name}! Your password reset token is valid. Please open the app and use the token below to reset your password.`,
            'success',
            'Open App',
            token
        ));

    } catch (error) {
        console.error("Password reset web error:", error);
        return res.status(500).send(generateHtmlResponse(
            'Reset Error',
            'An error occurred while processing your password reset. Please try again later or contact support.',
            'error',
            null
        ));
    }
});

// Generate HTML response for password reset
function generateHtmlResponse(title, message, type, buttonText, token = null) {
    const isSuccess = type === 'success';
    const iconColor = isSuccess ? '#28a745' : '#dc3545';
    const icon = isSuccess ? '🔑' : '✗';
    const appUrl = process.env.EMAIL_VERIFICATION_URL || 'https://test.splitleague.noodev8.com';

    return `
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title} - Noodev8</title>
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
            .token-box {
                background-color: #f8f9fa;
                border: 2px dashed #007bff;
                border-radius: 5px;
                padding: 15px;
                margin: 20px 0;
                font-family: monospace;
                font-size: 14px;
                word-break: break-all;
                color: #007bff;
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
            .instructions {
                background-color: #e7f3ff;
                border-left: 4px solid #007bff;
                padding: 15px;
                margin: 20px 0;
                text-align: left;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <span class="icon">${icon}</span>
            <h1>${title}</h1>
            <p>${message}</p>
            ${token ? `
                <div class="token-box">
                    ${token}
                </div>
                <div class="instructions">
                    <strong>Instructions:</strong>
                    <ol>
                        <li>Copy the token above</li>
                        <li>Open the Noovos app</li>
                        <li>Go to "Reset Password"</li>
                        <li>Paste the token and enter your new password</li>
                    </ol>
                </div>
            ` : ''}
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
