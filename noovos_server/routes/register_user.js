/*
=======================================================================================================================================
API Route: register_user
=======================================================================================================================================
Method: POST
Purpose: Registers a new user in the system. Returns a token and basic user details upon success.
=======================================================================================================================================
Request Payload:
{
  "first_name": "John",                // string, required
  "last_name": "Doe",                  // string, required
  "email": "user@example.com",         // string, required
  "password": "securepassword123",     // string, required
  "mobile": "1234567890"               // string, optional
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Registration successful. Please check your email to verify your account before logging in.",
  "email": "user@example.com"         // string, user's email for verification
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"EMAIL_EXISTS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db');
const { generateToken, sendVerificationEmail } = require('../utils/email_service');

// POST /register_user
router.post('/', async (req, res) => {
    try {
        // Extract user details from request body
        const { first_name, last_name, email, password, mobile } = req.body;

        // Check if required fields are provided
        if (!first_name || !last_name || !email || !password) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "First name, last name, email, and password are required"
            });
        }

        // Check if user with the same email already exists
        const existingUserQuery = await pool.query(
            "SELECT * FROM app_user WHERE email = $1",
            [email]
        );

        if (existingUserQuery.rows.length > 0) {
            return res.status(409).json({
                return_code: "EMAIL_EXISTS",
                message: "A user with this email already exists"
            });
        }

        // Hash the password
        const saltRounds = 10;
        const passwordHash = await bcrypt.hash(password, saltRounds);

        // Generate email verification token
        const verificationToken = generateToken(32);

        // Set token expiration to 24 hours from now
        const tokenExpiration = new Date();
        tokenExpiration.setHours(tokenExpiration.getHours() + 24);

        // Insert the new user into the database with verification fields
        const newUserQuery = await pool.query(
            `INSERT INTO app_user
            (first_name, last_name, email, mobile, password_hash, email_verified, verification_token, verification_expires)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING *`,
            [first_name, last_name, email, mobile || null, passwordHash, false, verificationToken, tokenExpiration]
        );

        // Get the newly created user
        const newUser = newUserQuery.rows[0];

        // Send verification email
        try {
            await sendVerificationEmail(
                newUser.email,
                `${newUser.first_name} ${newUser.last_name}`,
                verificationToken
            );

            console.log(`Verification email sent to: ${newUser.email}`);
        } catch (emailError) {
            console.error("Error sending verification email:", emailError);
            // Continue with registration even if email fails
            // User can request resend later
        }

        // Return success response without token (user must verify email first)
        return res.status(201).json({
            return_code: "SUCCESS",
            message: "Registration successful. Please check your email to verify your account before logging in.",
            email: newUser.email
        });

    } catch (error) {
        console.error("Registration error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred during registration: " + error.message
        });
    }
});

module.exports = router;
