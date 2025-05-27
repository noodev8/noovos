/*
=======================================================================================================================================
API Route: create_service
=======================================================================================================================================
Method: POST
Purpose: Creates a new service for a business. Only business owners and staff can create services for their business.
=======================================================================================================================================
Request Payload:
{
  "business_id": 123,                    // integer, required - ID of the business
  "service_name": "Hair Cut",            // string, required - Name of the service
  "description": "Professional haircut", // string, optional - Description of the service (max 500 chars)
  "duration": 60,                        // integer, required - Duration in minutes
  "price": 25.50,                        // number, required - Price of the service
  "buffer_time": 15,                     // integer, optional - Buffer time in minutes (default: 0)
  "category_id": 5,                      // integer, optional - Category ID from category table
  "image_name": "services_123_1234567890" // string, optional - Image filename from upload_image API
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Service created successfully",
  "service": {
    "id": 456,                           // integer, generated service ID
    "business_id": 123,                  // integer, business ID
    "service_name": "Hair Cut",          // string, service name
    "description": "Professional haircut", // string, description
    "duration": 60,                      // integer, duration in minutes
    "price": 25.50,                      // number, price
    "currency": "GBP",                   // string, currency
    "active": true,                      // boolean, active status
    "buffer_time": 15,                   // integer, buffer time
    "category_id": 5,                    // integer, category ID
    "created_at": "2024-01-15T10:30:00Z", // timestamp
    "updated_at": "2024-01-15T10:30:00Z"  // timestamp
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"UNAUTHORIZED"
"BUSINESS_NOT_FOUND"
"INVALID_CATEGORY"
"INVALID_DURATION"
"INVALID_PRICE"
"INVALID_BUFFER_TIME"
"DESCRIPTION_TOO_LONG"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{baseUrl}}/create_service
Headers:
  Authorization: Bearer {{token}}
  Content-Type: application/json
Body:
{
  "business_id": 1,
  "service_name": "Hair Cut",
  "description": "Professional haircut service",
  "duration": 60,
  "price": 25.50,
  "buffer_time": 15,
  "category_id": 1
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /create_service
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const {
            business_id,
            service_name,
            description,
            duration,
            price,
            buffer_time,
            category_id,
            image_name
        } = req.body;

        // Validate required fields
        if (!business_id || !service_name || !duration || price === undefined || price === null) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID, service name, duration, and price are required"
            });
        }

        // Validate duration (must be positive integer)
        if (!Number.isInteger(duration) || duration <= 0) {
            return res.status(400).json({
                return_code: "INVALID_DURATION",
                message: "Duration must be a positive integer (minutes)"
            });
        }

        // Validate price (must be positive number)
        if (isNaN(price) || price < 0) {
            return res.status(400).json({
                return_code: "INVALID_PRICE",
                message: "Price must be a positive number"
            });
        }

        // Validate buffer_time if provided (must be non-negative integer)
        if (buffer_time !== undefined && (!Number.isInteger(buffer_time) || buffer_time < 0)) {
            return res.status(400).json({
                return_code: "INVALID_BUFFER_TIME",
                message: "Buffer time must be a non-negative integer (minutes)"
            });
        }

        // Validate description length if provided
        if (description && description.length > 500) {
            return res.status(400).json({
                return_code: "DESCRIPTION_TOO_LONG",
                message: "Description cannot exceed 500 characters"
            });
        }

        // Check if the user has permission to create services for this business
        // User must be either a business owner or staff member with active status
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2
             AND (role = 'business_owner' OR role = 'Staff')
             AND status = 'active'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to create services for this business"
            });
        }

        // Verify that the business exists
        const businessQuery = await pool.query(
            `SELECT id FROM business WHERE id = $1`,
            [business_id]
        );

        if (businessQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "BUSINESS_NOT_FOUND",
                message: "Business not found"
            });
        }

        // Validate category_id if provided
        if (category_id) {
            const categoryQuery = await pool.query(
                `SELECT id FROM category WHERE id = $1`,
                [category_id]
            );

            if (categoryQuery.rows.length === 0) {
                return res.status(400).json({
                    return_code: "INVALID_CATEGORY",
                    message: "Invalid category ID"
                });
            }
        }

        // Create the service
        const createServiceQuery = `
            INSERT INTO service (
                business_id,
                service_name,
                description,
                duration,
                price,
                currency,
                active,
                buffer_time,
                category_id,
                created_at,
                updated_at
            ) VALUES (
                $1, $2, $3, $4, $5, 'GBP', true, $6, $7, NOW(), NOW()
            ) RETURNING *
        `;

        const serviceResult = await pool.query(createServiceQuery, [
            business_id,
            service_name,
            description || null,
            duration,
            price,
            buffer_time || 0,
            category_id || null
        ]);

        const newService = serviceResult.rows[0];

        // If image_name is provided, insert it into the media table
        if (image_name && image_name.trim() !== '') {
            try {
                const mediaQuery = `
                    INSERT INTO media (
                        service_id,
                        business_id,
                        image_name,
                        position,
                        media_type,
                        is_active
                    ) VALUES ($1, $2, $3, 1, 'image', true)
                    RETURNING id
                `;

                const mediaResult = await pool.query(mediaQuery, [
                    newService.id,
                    business_id,
                    image_name.trim()
                ]);

                console.log(`Service image added to media table: ${image_name}, Media ID: ${mediaResult.rows[0].id}`);
            } catch (mediaError) {
                console.error('Error adding service image to media table:', mediaError);
                // Don't fail the service creation if image insertion fails
                // The service was created successfully, just log the media error
            }
        }

        console.log(`Service created successfully: ID ${newService.id}, Name: ${newService.service_name}, Business: ${business_id}`);

        // Return success response with the created service
        return res.status(201).json({
            return_code: "SUCCESS",
            message: "Service created successfully",
            service: newService
        });

    } catch (error) {
        // Log the error for debugging purposes
        console.error("Create service error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return a server error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while creating the service: " + error.message
        });
    }
});

module.exports = router;
