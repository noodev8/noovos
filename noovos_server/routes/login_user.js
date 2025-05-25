/*
=======================================================================================================================================
API Route: login_user
=======================================================================================================================================
Method: POST
Purpose: Authenticates a user using their email and password. Returns a token and basic user details upon success.
=======================================================================================================================================
Request Payload:
{
  "email": "user@example.com",         // string, required
  "password": "securepassword123"      // string, required
}

Success Response:
{
  "return_code": "SUCCESS"
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // string, JWT token for auth
  "user": {
    "id": 123,                         // integer, unique user ID
    "name": "Andreas",                 // string, user's name
    "email": "user@example.com",       // string, user's email
    "account_level": "standard"        // string, e.g. 'standard', 'premium', 'admin'
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_CREDENTIALS"
"EMAIL_NOT_VERIFIED"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db');

// POST /login_user
router.post('/', async (req, res) => {
    try {
        // Extract email and password from request body
        const { email, password } = req.body;

        // Check if email and password are provided
        if (!email || !password) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Email and password are required"
            });
        }

        // Query the database to find the user with the provided email
        const userQuery = await pool.query(
            "SELECT * FROM app_user WHERE email = $1",
            [email]
        );

        // Check if user exists
        if (userQuery.rows.length === 0) {
            return res.status(401).json({
                return_code: "INVALID_CREDENTIALS",
                message: "Invalid email or password"
            });
        }

        // Get the user from the query result
        const user = userQuery.rows[0];

        // Compare the provided password with the stored hash
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);

        // If password is invalid, return error
        if (!isPasswordValid) {
            return res.status(401).json({
                return_code: "INVALID_CREDENTIALS",
                message: "Invalid email or password"
            });
        }

        // Check if email is verified (handle both false and null values)
        if (user.email_verified !== true) {
            return res.status(401).json({
                return_code: "EMAIL_NOT_VERIFIED",
                message: "Please verify your email address before logging in. Check your email for a verification link.",
                email: user.email
            });
        }

        // Generate JWT token
        const token = jwt.sign(
            {
                id: user.id,
                email: user.email
            },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        // Return success response with token and user details
        return res.status(200).json({
            return_code: "SUCCESS",
            token: token,
            user: {
                id: user.id,
                name: `${user.first_name} ${user.last_name}`,
                email: user.email,
                email_verified: user.email_verified || false,
                account_level: 'standard'  // Default account level
            }
        });

    } catch (error) {
        console.error("Login error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred during login: " + error.message
        });
    }
});

module.exports = router;
