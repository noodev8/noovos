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
  "active": true,                        // boolean, optional - Active status
  "image_name": "services_123_1234567890" // string, optional - Image filename from upload_image API
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
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary with environment variables
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

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
            active,
            image_name
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

        // Handle image update if image_name is provided
        if (image_name !== undefined) {
            try {
                if (image_name && image_name.trim() !== '') {
                    // Check if service already has an image
                    const existingImageQuery = await pool.query(
                        `SELECT id, image_name FROM media WHERE service_id = $1 AND media_type = 'image'`,
                        [service_id]
                    );

                    if (existingImageQuery.rows.length > 0) {
                        // Get the old image name for deletion from Cloudinary
                        const oldImageName = existingImageQuery.rows[0].image_name;

                        // Only delete from Cloudinary if the image name is different (i.e., it's being replaced)
                        if (oldImageName && oldImageName !== image_name.trim()) {
                            try {
                                // Delete old image from Cloudinary using filename
                                // Filename format: noovos_123_1234567890
                                const publicId = `noovos/${oldImageName}`;
                                const deleteResult = await cloudinary.uploader.destroy(publicId, {
                                    resource_type: 'image'
                                });
                                console.log(`Old image deleted from Cloudinary: ${publicId}, Result: ${deleteResult.result}`);
                            } catch (cloudinaryError) {
                                console.error('Error deleting old image from Cloudinary:', cloudinaryError);
                                // Continue with database update even if Cloudinary deletion fails
                            }
                        }

                        // Update existing image record in database
                        await pool.query(
                            `UPDATE media SET image_name = $1
                             WHERE service_id = $2 AND media_type = 'image'`,
                            [image_name.trim(), service_id]
                        );
                        console.log(`Service image updated: ${image_name}`);
                    } else {
                        // Insert new image record
                        const mediaInsertResult = await pool.query(
                            `INSERT INTO media (service_id, business_id, image_name, position, media_type, is_active)
                             VALUES ($1, $2, $3, 1, 'image', true)
                             RETURNING id`,
                            [service_id, currentService.business_id, image_name.trim()]
                        );
                        console.log(`Service image added: ${image_name}, Media ID: ${mediaInsertResult.rows[0].id}`);
                    }
                } else {
                    // Remove existing image if image_name is empty or null
                    const existingImageQuery = await pool.query(
                        `SELECT image_name FROM media WHERE service_id = $1 AND media_type = 'image'`,
                        [service_id]
                    );

                    // Delete from Cloudinary if image exists
                    if (existingImageQuery.rows.length > 0) {
                        const oldImageName = existingImageQuery.rows[0].image_name;
                        if (oldImageName) {
                            try {
                                // Delete image from Cloudinary using filename
                                // Filename format: noovos_123_1234567890
                                const publicId = `noovos/${oldImageName}`;
                                const deleteResult = await cloudinary.uploader.destroy(publicId, {
                                    resource_type: 'image'
                                });
                                console.log(`Image deleted from Cloudinary: ${publicId}, Result: ${deleteResult.result}`);
                            } catch (cloudinaryError) {
                                console.error('Error deleting image from Cloudinary:', cloudinaryError);
                                // Continue with database deletion even if Cloudinary deletion fails
                            }
                        }
                    }

                    // Remove image record from database
                    await pool.query(
                        `DELETE FROM media WHERE service_id = $1 AND media_type = 'image'`,
                        [service_id]
                    );
                    console.log(`Service image removed for service ID: ${service_id}`);
                }
            } catch (mediaError) {
                console.error('Error updating service image in media table:', mediaError);
                // Don't fail the service update if image update fails
            }
        }

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
