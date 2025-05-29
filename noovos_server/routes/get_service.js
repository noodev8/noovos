/*
=======================================================================================================================================
API Route: get_service
=======================================================================================================================================
Method: POST
Purpose: Retrieves detailed information about a specific service by its ID.
=======================================================================================================================================
Request Payload:
{
  "service_id": 7                     // integer, required - ID of the service to retrieve
}

Success Response:
{
  "return_code": "SUCCESS",
  "service": {
    "service_id": 7,                  // integer - Unique service ID
    "service_name": "Deep Tissue Massage", // string - Name of the service
    "business_id": 3,                 // integer - ID of the business that offers this service
    "business_name": "Relaxation Spa", // string - Name of the business
    "service_description": "A deep...", // string - Description of the service
    "service_image": "massage.jpg",   // string - Image name from the media table (service image)
    "business_image": "spa.jpg",      // string - Image name from the media table (business image)
    "duration": 60,                   // integer - Duration of the service in minutes
    "price": 75.00,                   // number - Price of the service
    "currency": "GBP",                // string - Currency code
    "category_id": 4,                 // integer - ID of the category
    "category_name": "Massage",       // string - Name of the category
    "city": "Manchester",             // string - City of the business
    "postcode": "M1 1AA",             // string - Postcode of the business
    "address": "123 Main St",         // string - Address of the business
    "buffer_time": 15                 // integer - Buffer time in minutes
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"SERVICE_NOT_FOUND"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /get_service
router.post('/', async (req, res) => {
    try {
        // Extract service_id from request body
        const { service_id } = req.body;

        // Validate service_id
        if (!service_id || isNaN(parseInt(service_id))) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid service_id is required"
            });
        }

        // Define the SQL query to get service details
        const serviceQuery = `
            SELECT
                s.id AS service_id,
                s.service_name,
                s.business_id,
                b.name AS business_name,
                s.description AS service_description,
                -- Get service image if available
                (SELECT m.image_name FROM public.media m
                 WHERE m.service_id = s.id AND m.position = 1 AND m.is_active = TRUE
                 ORDER BY m.id LIMIT 1) AS service_image,
                -- Get business image
                (SELECT m.image_name FROM public.media m
                 WHERE m.business_id = b.id AND m.position = 1 AND m.is_active = TRUE
                 ORDER BY m.id LIMIT 1) AS business_image,
                s.duration,
                s.price,
                s.currency,
                s.category_id,
                c.name AS category_name,
                b.city,
                b.postcode,
                b.address,
                s.buffer_time
            FROM
                service s
            JOIN
                business b ON s.business_id = b.id
            LEFT JOIN
                category c ON s.category_id = c.id
            WHERE
                s.id = $1
                AND s.active = true;
        `;

        // Execute the query
        const serviceResult = await pool.query(serviceQuery, [service_id]);

        // Check if service exists
        if (serviceResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "Service not found or inactive"
            });
        }

        // Get the service details
        const service = serviceResult.rows[0];

        // Ensure numeric fields are properly converted
        // PostgreSQL numeric types may be returned as strings
        if (service.price !== null && service.price !== undefined) {
            service.price = parseFloat(service.price);
        }
        if (service.duration !== null && service.duration !== undefined) {
            service.duration = parseInt(service.duration);
        }
        if (service.buffer_time !== null && service.buffer_time !== undefined) {
            service.buffer_time = parseInt(service.buffer_time);
        }

        // Return success response
        return res.status(200).json({
            return_code: "SUCCESS",
            service: service
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Get service error:", error.message);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving service details: " + error.message
        });
    }
});

module.exports = router;
