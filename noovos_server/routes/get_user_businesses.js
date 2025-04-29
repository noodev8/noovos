/*
=======================================================================================================================================
API Route: get_user_businesses
=======================================================================================================================================
Method: POST
Purpose: Retrieves businesses owned by the authenticated user
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  // No additional parameters required, user ID is extracted from JWT token
}

Success Response:
{
  "return_code": "SUCCESS",
  "businesses": [
    {
      "id": 123,                       // integer, business ID
      "name": "Salon Name",            // string, business name
      "email": "business@example.com", // string, business email
      "phone": "1234567890",           // string, business phone
      "address": "123 Main St",        // string, business address
      "city": "London",                // string, business city
      "postcode": "W1 1AA",            // string, business postcode
      "role": "business_owner"         // string, user's role for this business
    },
    // ... more businesses if the user owns multiple
  ]
}

Error Responses:
{
  "return_code": "UNAUTHORIZED",
  "message": "Authentication required"
}
{
  "return_code": "NO_BUSINESSES_FOUND",
  "message": "No businesses found for this user"
}
{
  "return_code": "SERVER_ERROR",
  "message": "An error occurred while processing your request"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /get_user_businesses
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Query to get businesses where the user has a role
        const query = `
            SELECT
                b.id,
                b.name,
                b.email,
                b.phone,
                b.address,
                b.city,
                b.postcode,
                b.country,
                b.description,
                b.website,
                abr.role,
                (
                    SELECT m.image_name
                    FROM media m
                    WHERE m.business_id = b.id AND m.position = 1 AND m.is_active = TRUE
                    LIMIT 1
                ) AS business_image
            FROM
                business b
            JOIN
                appuser_business_role abr ON b.id = abr.business_id
            WHERE
                abr.appuser_id = $1
            ORDER BY
                b.name ASC
        `;

        // Execute the query
        const result = await pool.query(query, [userId]);

        // Check if any businesses were found
        if (result.rows.length === 0) {
            return res.status(404).json({
                return_code: "NO_BUSINESSES_FOUND",
                message: "No businesses found for this user"
            });
        }

        // Return success response with businesses
        return res.status(200).json({
            return_code: "SUCCESS",
            businesses: result.rows
        });
    } catch (error) {
        console.error("Error in get_user_businesses:", error);

        // Return error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
