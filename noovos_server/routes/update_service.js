/*
=======================================================================================================================================
API Route: update_service
=======================================================================================================================================
Method: POST
Purpose: Updates an existing service for a business. Only business owners and staff can update services for their business.
=======================================================================================================================================
Request Payload:
{
  "service_id": 456,                     // integer, required - ID of the service to update
  "service_name": "Hair Cut & Style",    // string, optional - Name of the service
  "description": "Professional haircut and styling", // string, optional - Description (max 500 chars)
  "duration": 90,                        // integer, optional - Duration in minutes
  "price": 35.00,                        // number, optional - Price of the service
  "buffer_time": 20,                     // integer, optional - Buffer time in minutes
  "category_id": 5,                      // integer, optional - Category ID from category table
  "active": true                         // boolean, optional - Active status
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Service updated successfully",
  "service": {
    "id": 456,                           // integer, service ID
    "business_id": 123,                  // integer, business ID
    "service_name": "Hair Cut & Style",  // string, updated service name
    "description": "Professional haircut and styling", // string, updated description
    "duration": 90,                      // integer, updated duration
    "price": 35.00,                      // number, updated price
    "currency": "GBP",                   // string, currency
    "active": true,                      // boolean, active status
    "buffer_time": 20,                   // integer, updated buffer time
    "category_id": 5,                    // integer, updated category ID
    "created_at": "2024-01-15T10:30:00Z", // timestamp
    "updated_at": "2024-01-15T11:45:00Z"  // timestamp, updated
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"UNAUTHORIZED"
"SERVICE_NOT_FOUND"
"INVALID_CATEGORY"
"INVALID_DURATION"
"INVALID_PRICE"
"INVALID_BUFFER_TIME"
"DESCRIPTION_TOO_LONG"
"NO_CHANGES"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{baseUrl}}/update_service
Headers:
  Authorization: Bearer {{token}}
  Content-Type: application/json
Body:
{
  "service_id": 1,
  "service_name": "Hair Cut & Style",
  "description": "Professional haircut and styling service",
  "duration": 90,
  "price": 35.00,
  "buffer_time": 20,
  "category_id": 1,
  "active": true
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /update_service
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { 
            service_id,
            service_name, 
            description, 
            duration, 
            price, 
            buffer_time, 
            category_id,
            active
        } = req.body;

        // Validate required fields
        if (!service_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Service ID is required"
            });
        }

        // Validate optional fields if provided
        if (duration !== undefined && (!Number.isInteger(duration) || duration <= 0)) {
            return res.status(400).json({
                return_code: "INVALID_DURATION",
                message: "Duration must be a positive integer (minutes)"
            });
        }

        if (price !== undefined && (isNaN(price) || price < 0)) {
            return res.status(400).json({
                return_code: "INVALID_PRICE",
                message: "Price must be a positive number"
            });
        }

        if (buffer_time !== undefined && (!Number.isInteger(buffer_time) || buffer_time < 0)) {
            return res.status(400).json({
                return_code: "INVALID_BUFFER_TIME",
                message: "Buffer time must be a non-negative integer (minutes)"
            });
        }

        if (description !== undefined && description && description.length > 500) {
            return res.status(400).json({
                return_code: "DESCRIPTION_TOO_LONG",
                message: "Description cannot exceed 500 characters"
            });
        }

        // Get the current service and verify it exists
        const currentServiceQuery = await pool.query(
            `SELECT * FROM service WHERE id = $1`,
            [service_id]
        );

        if (currentServiceQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "Service not found"
            });
        }

        const currentService = currentServiceQuery.rows[0];

        // Check if the user has permission to update services for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 
             AND (role = 'business_owner' OR role = 'Staff') 
             AND status = 'active'`,
            [userId, currentService.business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to update services for this business"
            });
        }

        // Validate category_id if provided
        if (category_id !== undefined && category_id !== null) {
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

        // Build the update query dynamically based on provided fields
        const updateFields = [];
        const updateValues = [];
        let paramCount = 1;

        if (service_name !== undefined) {
            updateFields.push(`service_name = $${paramCount}`);
            updateValues.push(service_name);
            paramCount++;
        }
        if (description !== undefined) {
            updateFields.push(`description = $${paramCount}`);
            updateValues.push(description || null);
            paramCount++;
        }
        if (duration !== undefined) {
            updateFields.push(`duration = $${paramCount}`);
            updateValues.push(duration);
            paramCount++;
        }
        if (price !== undefined) {
            updateFields.push(`price = $${paramCount}`);
            updateValues.push(price);
            paramCount++;
        }
        if (buffer_time !== undefined) {
            updateFields.push(`buffer_time = $${paramCount}`);
            updateValues.push(buffer_time);
            paramCount++;
        }
        if (category_id !== undefined) {
            updateFields.push(`category_id = $${paramCount}`);
            updateValues.push(category_id || null);
            paramCount++;
        }
        if (active !== undefined) {
            updateFields.push(`active = $${paramCount}`);
            updateValues.push(active);
            paramCount++;
        }

        // Always update the updated_at timestamp
        updateFields.push(`updated_at = NOW()`);

        // If no fields to update, return current service
        if (updateFields.length === 1) { // Only updated_at
            return res.status(200).json({
                return_code: "NO_CHANGES",
                message: "No changes to update",
                service: currentService
            });
        }

        // Add service_id as the last parameter for WHERE clause
        updateValues.push(service_id);

        // Update the service
        const updateQuery = `
            UPDATE service 
            SET ${updateFields.join(', ')}
            WHERE id = $${paramCount}
            RETURNING *
        `;

        const updatedServiceQuery = await pool.query(updateQuery, updateValues);
        const updatedService = updatedServiceQuery.rows[0];

        console.log(`Service updated successfully: ID ${service_id}, Name: ${updatedService.service_name}`);

        // Return success response with updated service data
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Service updated successfully",
            service: updatedService
        });

    } catch (error) {
        // Log the error for debugging purposes
        console.error("Update service error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return a server error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while updating the service: " + error.message
        });
    }
});

module.exports = router;
