/*
=======================================================================================================================================
API Route: update_business
=======================================================================================================================================
Method: POST
Purpose: Updates business details for an existing business owned by the authenticated user.
         Also handles business image management through the media table.
=======================================================================================================================================
Request Payload:
{
  "business_id": 1,                       // integer, required - ID of the business to update
  "name": "Updated Business Name",        // string, optional
  "image_name": "business_123_1234567890", // string, optional - filename for business image
  "email": "updated@example.com",         // string, optional
  "phone": "1234567890",                  // string, optional
  "website": "https://example.com",       // string, optional
  "address": "123 Updated Street",        // string, optional
  "city": "London",                       // string, optional
  "postcode": "SW1A 1AA",                 // string, optional
  "country": "United Kingdom",            // string, optional
  "description": "Updated description"    // string, optional
}
=======================================================================================================================================
Response Format:
Success:
{
  "return_code": "SUCCESS",
  "message": "Business updated successfully",
  "business": {
    "id": 1,
    "name": "Updated Business Name",
    "email": "updated@example.com",
    "phone": "1234567890",
    "website": "https://example.com",
    "address": "123 Updated Street",
    "city": "London",
    "postcode": "SW1A 1AA",
    "country": "United Kingdom",
    "description": "Updated description"
  }
}

Error:
{
  "return_code": "BUSINESS_NOT_FOUND",
  "message": "Business not found or you don't have permission to update it"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_BUSINESS_ID"
"BUSINESS_NOT_FOUND"
"EMAIL_EXISTS"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/update_business
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{
  "business_id": 1,
  "name": "Updated Test Business",
  "email": "updated@business.com",
  "phone": "9876543210",
  "address": "456 Updated Street",
  "city": "Manchester",
  "postcode": "M1 1AA",
  "country": "United Kingdom",
  "description": "An updated test business",
  "image_name": "noovos_123_1234567890"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary with environment variables
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

// POST /update_business
router.post('/', auth, async (req, res) => {
    try {
        // Get user ID from JWT token (set by auth middleware)
        const userId = req.user.id;

        // Extract business details from request body
        const {
            business_id,
            name,
            email,
            phone,
            website,
            address,
            city,
            postcode,
            country,
            description,
            image_name
        } = req.body;

        // Check if business_id is provided
        if (!business_id) {
            return res.status(400).json({
                return_code: "MISSING_BUSINESS_ID",
                message: "Business ID is required"
            });
        }

        // Check if user has permission to update this business (must be business owner)
        const permissionQuery = await pool.query(
            `SELECT b.* FROM business b
             JOIN appuser_business_role abr ON b.id = abr.business_id
             WHERE b.id = $1 AND abr.appuser_id = $2 AND abr.role = 'business_owner' AND abr.status = 'active'`,
            [business_id, userId]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "BUSINESS_NOT_FOUND",
                message: "Business not found or you don't have permission to update it"
            });
        }

        const currentBusiness = permissionQuery.rows[0];

        // If email is being updated, check if new email already exists for another business
        if (email && email !== currentBusiness.email) {
            const existingBusinessQuery = await pool.query(
                "SELECT * FROM business WHERE email = $1 AND id != $2",
                [email, business_id]
            );

            if (existingBusinessQuery.rows.length > 0) {
                return res.status(409).json({
                    return_code: "EMAIL_EXISTS",
                    message: "A business with this email already exists"
                });
            }
        }

        // Build update query dynamically based on provided fields
        const updateFields = [];
        const updateValues = [];
        let paramCount = 1;

        if (name !== undefined) {
            updateFields.push(`name = $${paramCount}`);
            updateValues.push(name);
            paramCount++;
        }
        if (email !== undefined) {
            updateFields.push(`email = $${paramCount}`);
            updateValues.push(email);
            paramCount++;
        }
        if (phone !== undefined) {
            updateFields.push(`phone = $${paramCount}`);
            updateValues.push(phone || null);
            paramCount++;
        }
        if (website !== undefined) {
            updateFields.push(`website = $${paramCount}`);
            updateValues.push(website || null);
            paramCount++;
        }
        if (address !== undefined) {
            updateFields.push(`address = $${paramCount}`);
            updateValues.push(address || null);
            paramCount++;
        }
        if (city !== undefined) {
            updateFields.push(`city = $${paramCount}`);
            updateValues.push(city || null);
            paramCount++;
        }
        if (postcode !== undefined) {
            updateFields.push(`postcode = $${paramCount}`);
            updateValues.push(postcode || null);
            paramCount++;
        }
        if (country !== undefined) {
            updateFields.push(`country = $${paramCount}`);
            updateValues.push(country || null);
            paramCount++;
        }
        if (description !== undefined) {
            updateFields.push(`description = $${paramCount}`);
            updateValues.push(description || null);
            paramCount++;
        }

        // Always update the updated_at timestamp
        updateFields.push(`updated_at = NOW()`);

        // If no fields to update, return current business
        if (updateFields.length === 1) { // Only updated_at
            return res.status(200).json({
                return_code: "SUCCESS",
                message: "No changes to update",
                business: currentBusiness
            });
        }

        // Add business_id as the last parameter for WHERE clause
        updateValues.push(business_id);

        // Update the business
        const updateQuery = `
            UPDATE business
            SET ${updateFields.join(', ')}
            WHERE id = $${paramCount}
            RETURNING *
        `;

        const updatedBusinessQuery = await pool.query(updateQuery, updateValues);
        const updatedBusiness = updatedBusinessQuery.rows[0];

        // Handle business image update if image_name is provided
        if (image_name !== undefined) {
            try {
                // Check if business already has an image in the media table
                const existingImageQuery = await pool.query(
                    `SELECT image_name FROM media
                     WHERE business_id = $1 AND service_id IS NULL AND media_type = 'image' AND position = 1`,
                    [business_id]
                );

                if (image_name && image_name.trim() !== '') {
                    // Image is being added or updated
                    if (existingImageQuery.rows.length > 0) {
                        // Get the old image name for potential Cloudinary cleanup
                        const oldImageName = existingImageQuery.rows[0].image_name;

                        // Only delete from Cloudinary if the image name is different (i.e., it's being replaced)
                        if (oldImageName && oldImageName !== image_name.trim()) {
                            try {
                                // Delete old image from Cloudinary using filename
                                const publicId = `noovos/${oldImageName}`;
                                const deleteResult = await cloudinary.uploader.destroy(publicId, {
                                    resource_type: 'image'
                                });

                            } catch (cloudinaryError) {
                                console.error('Error deleting old business image from Cloudinary:', cloudinaryError);
                                // Continue with database update even if Cloudinary deletion fails
                            }
                        }

                        // Update existing image record in database
                        await pool.query(
                            `UPDATE media SET image_name = $1
                             WHERE business_id = $2 AND service_id IS NULL AND media_type = 'image' AND position = 1`,
                            [image_name.trim(), business_id]
                        );

                    } else {
                        // Insert new image record
                        const mediaInsertResult = await pool.query(
                            `INSERT INTO media (business_id, image_name, position, media_type, is_active)
                             VALUES ($1, $2, 1, 'image', true)
                             RETURNING id`,
                            [business_id, image_name.trim()]
                        );

                    }
                } else {
                    // Empty image_name means remove the image
                    if (existingImageQuery.rows.length > 0) {
                        const oldImageName = existingImageQuery.rows[0].image_name;

                        // Delete from Cloudinary
                        if (oldImageName) {
                            try {
                                const publicId = `noovos/${oldImageName}`;
                                const deleteResult = await cloudinary.uploader.destroy(publicId, {
                                    resource_type: 'image'
                                });

                            } catch (cloudinaryError) {
                                console.error('Error deleting business image from Cloudinary:', cloudinaryError);
                                // Continue with database deletion even if Cloudinary deletion fails
                            }
                        }

                        // Remove image record from database
                        await pool.query(
                            `DELETE FROM media
                             WHERE business_id = $1 AND service_id IS NULL AND media_type = 'image' AND position = 1`,
                            [business_id]
                        );

                    }
                }
            } catch (imageError) {
                console.error('Error handling business image:', imageError);
                // Don't fail the business update if image handling fails
                // The business was updated successfully, just log the image error
            }
        }

        // Return success response with updated business data
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Business updated successfully",
            business: updatedBusiness
        });

    } catch (error) {
        console.error("Error updating business:", error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while updating the business"
        });
    }
});

module.exports = router;
