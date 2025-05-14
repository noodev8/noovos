/*
=======================================================================================================================================
API Route: get_business_services
=======================================================================================================================================
Method: POST
Purpose: Retrieves all services for a specific business
Authentication: Not required - This endpoint is publicly accessible
=======================================================================================================================================
Request Payload:
{
  "business_id": 5                    // integer, required - ID of the business
}

Success Response:
{
  "return_code": "SUCCESS",
  "services": [
    {
      "id": 7,                       // integer - Service ID
      "name": "Deep Tissue Massage",  // string - Service name
      "description": "A deep...",     // string - Service description
      "duration": 45,                // integer - Duration in minutes
      "price": 75.00,                // number - Price of the service
      "currency": "GBP",             // string - Currency code
      "category_id": 4,              // integer - Category ID
      "category_name": "Massage",     // string - Category name
      "image_name": "massage.jpg"     // string - Image name from media table
    },
    ...
  ]
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Business ID is required"
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

// POST /get_business_services
router.post('/', async (req, res) => {
    try {
        // Extract business_id from request body
        const { business_id } = req.body;

        // Validate business_id
        if (!business_id || isNaN(parseInt(business_id))) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid business_id is required"
            });
        }

        // Define the SQL query to get services
        const servicesQuery = `
            SELECT
                s.id,
                s.service_name AS name,
                s.description,
                s.duration,
                s.price,
                s.currency,
                s.category_id,
                c.name AS category_name,
                -- Get service image if available
                (SELECT m.image_name FROM public.media m
                 WHERE m.service_id = s.id AND m.position = 1 AND m.is_active = TRUE
                 ORDER BY m.id LIMIT 1) AS image_name
            FROM
                service s
            LEFT JOIN
                category c ON s.category_id = c.id
            WHERE
                s.business_id = $1
                AND s.active = true
            ORDER BY
                s.service_name ASC;
        `;

        // Execute the query
        const servicesResult = await pool.query(servicesQuery, [business_id]);

        // Return success response with services list
        return res.status(200).json({
            return_code: "SUCCESS",
            services: servicesResult.rows
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Get business services error:", error.message);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving business services: " + error.message
        });
    }
});

module.exports = router; 