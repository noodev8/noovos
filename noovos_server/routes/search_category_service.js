/*
=======================================================================================================================================
API Route: search_category_service
=======================================================================================================================================
Method: POST
Purpose: Retrieves salon and service details for a specific category. Returns a list of services and their associated businesses.
=======================================================================================================================================
Request Payload:
{
  "category_id": 1                // integer, required - The ID of the category to search for
}

Success Response:
{
  "return_code": "SUCCESS",
  "category": {
    "id": 1,                      // integer, unique category ID
    "name": "Hair",               // string, category name
    "description": "Hair services", // string, category description (may be null)
    "icon_url": "hair.jpg"        // string, icon URL for the category (may be null)
  },
  "services": [
    {
      "service_id": 123,                    // integer, unique service ID
      "service_name": "Haircut",            // string, name of the service
      "business_name": "Style Salon",       // string, name of the business
      "service_description": "A stylish...", // string, description of the service
      "service_image": "url/to/image.jpg",  // string, URL to service image
      "business_profile": "url/to/image.jpg", // string, URL to business profile image
      "price": 45.00,                       // number, price of the service
      "duration": 30,                       // integer, duration of the service in minutes
      "city": "London",                     // string, city of the business
      "postcode": "W1A 1AA"                 // string, postcode of the business
    },
    // More services...
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"CATEGORY_NOT_FOUND"
"NO_SERVICES"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /search_category_service
router.post('/', async (req, res) => {
    try {
        // Extract category_id from request body
        const { category_id } = req.body;

        // Check if category_id is provided
        if (!category_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Category ID is required"
            });
        }

        // First, check if the category exists
        const categoryQuery = `
            SELECT 
                id,
                name,
                description,
                icon_url
            FROM 
                category
            WHERE 
                id = $1;
        `;

        // Execute the query to get the category
        const categoryResult = await pool.query(categoryQuery, [category_id]);

        // Check if the category exists
        if (categoryResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "CATEGORY_NOT_FOUND",
                message: "Category not found with the provided ID"
            });
        }

        // Get the category details
        const category = categoryResult.rows[0];

        // Now, get all services for this category
        const servicesQuery = `
            SELECT
                s.id AS service_id,
                s.service_name::TEXT,
                b.name::TEXT AS business_name,
                s.description::TEXT AS service_description,
                s.service_image::TEXT,
                b.profile_picture::TEXT AS business_profile,
                s.price::NUMERIC AS price,
                s.duration::INTEGER,
                b.city::TEXT,
                b.postcode::TEXT
            FROM
                service s
            JOIN
                business b ON s.business_id = b.id
            WHERE
                s.category_id = $1
                AND s.active = true
            ORDER BY
                b.name ASC,
                s.service_name ASC;
        `;

        // Execute the query to get services
        const servicesResult = await pool.query(servicesQuery, [category_id]);

        // Check if there are any services for this category
        if (servicesResult.rows.length === 0) {
            return res.status(200).json({
                return_code: "NO_SERVICES",
                message: "No services found for this category",
                category: category,
                services: []
            });
        }

        // Process the results to ensure numeric values
        const processedServices = servicesResult.rows.map(row => {
            return {
                ...row,
                // Ensure price is a number
                price: typeof row.price === 'string' ? parseFloat(row.price) : Number(row.price),
                // Ensure duration is a number
                duration: typeof row.duration === 'string' ? parseInt(row.duration) : Number(row.duration)
            };
        });

        // Return success response with category and services
        return res.status(200).json({
            return_code: "SUCCESS",
            category: category,
            services: processedServices
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Search category service error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving category services: " + error.message
        });
    }
});

module.exports = router;
