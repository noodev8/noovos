/*
=======================================================================================================================================
API Route: register_business
=======================================================================================================================================
Method: POST
Purpose: Registers a new business and assigns the current user as the business owner.
=======================================================================================================================================
Request Payload:
{
  "name": "My Business",              // string, required
  "email": "business@example.com",    // string, required
  "phone": "1234567890",              // string, optional
  "website": "https://mybusiness.com", // string, optional
  "address": "123 Main St",           // string, optional
  "city": "London",                   // string, optional
  "postcode": "SW1A 1AA",             // string, optional
  "country": "United Kingdom",        // string, optional
  "description": "Business description" // string, optional
}

Success Response:
{
  "return_code": "SUCCESS",
  "business": {
    "id": 123,                         // integer, unique business ID
    "name": "My Business",             // string, business name
    "email": "business@example.com",   // string, business email
    "phone": "1234567890",             // string, business phone
    "website": "https://mybusiness.com", // string, business website
    "address": "123 Main St",          // string, business address
    "city": "London",                  // string, business city
    "postcode": "SW1A 1AA",            // string, business postcode
    "country": "United Kingdom",       // string, business country
    "description": "Business description", // string, business description
    "business_verified": false,        // boolean, verification status
    "created_at": "2024-01-01T00:00:00Z" // string, creation date
  },
  "message": "Business registered successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"EMAIL_EXISTS"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/register_business
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{
  "name": "Test Business",
  "email": "test@business.com",
  "phone": "1234567890",
  "address": "123 Test Street",
  "city": "London",
  "postcode": "SW1A 1AA",
  "country": "United Kingdom",
  "description": "A test business"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// POST /register_business
router.post('/', auth, async (req, res) => {
    try {
        // Get user ID from JWT token (set by auth middleware)
        const userId = req.user.id;

        // Extract business details from request body
        const { 
            name, 
            email, 
            phone, 
            website, 
            address, 
            city, 
            postcode, 
            country, 
            description 
        } = req.body;

        // Check if required fields are provided
        if (!name || !email) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business name and email are required"
            });
        }

        // Check if business with the same email already exists
        const existingBusinessQuery = await pool.query(
            "SELECT * FROM business WHERE email = $1",
            [email]
        );

        if (existingBusinessQuery.rows.length > 0) {
            return res.status(409).json({
                return_code: "EMAIL_EXISTS",
                message: "A business with this email already exists"
            });
        }

        // Start transaction
        await pool.query('BEGIN');

        try {
            // Insert the new business into the database
            const newBusinessQuery = await pool.query(
                `INSERT INTO business
                (name, email, phone, website, address, city, postcode, country, description, business_verified, created_at, updated_at)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())
                RETURNING *`,
                [
                    name,
                    email,
                    phone || null,
                    website || null,
                    address || null,
                    city || null,
                    postcode || null,
                    country || null,
                    description || null,
                    false  // business_verified defaults to false
                ]
            );

            // Get the newly created business
            const newBusiness = newBusinessQuery.rows[0];

            // Add the user as business owner in appuser_business_role table
            await pool.query(
                `INSERT INTO appuser_business_role
                (appuser_id, business_id, role, status, requested_at, responded_at)
                VALUES ($1, $2, $3, $4, NOW(), NOW())`,
                [userId, newBusiness.id, 'business_owner', 'active']
            );

            // Commit transaction
            await pool.query('COMMIT');

            console.log(`Business registered successfully: ${newBusiness.name} (ID: ${newBusiness.id}) by user ID: ${userId}`);

            // Return success response with business details
            return res.status(201).json({
                return_code: "SUCCESS",
                business: {
                    id: newBusiness.id,
                    name: newBusiness.name,
                    email: newBusiness.email,
                    phone: newBusiness.phone,
                    website: newBusiness.website,
                    address: newBusiness.address,
                    city: newBusiness.city,
                    postcode: newBusiness.postcode,
                    country: newBusiness.country,
                    description: newBusiness.description,
                    business_verified: newBusiness.business_verified,
                    created_at: newBusiness.created_at
                },
                message: "Business registered successfully"
            });

        } catch (insertError) {
            // Rollback transaction on error
            await pool.query('ROLLBACK');
            throw insertError;
        }

    } catch (error) {
        console.error("Business registration error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred during business registration: " + error.message
        });
    }
});

module.exports = router;
