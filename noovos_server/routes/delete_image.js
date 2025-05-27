/*
=======================================================================================================================================
API Route: delete_image
=======================================================================================================================================
Method: POST
Purpose: Deletes an image from Cloudinary storage. Used when replacing service images to clean up old files.
=======================================================================================================================================
Request Payload:
{
  "image_name": "noovos_123_1234567890",    // string, required - Cloudinary public ID/filename to delete
  "folder": "noovos"                        // string, optional - Cloudinary folder name (default: "noovos")
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Image deleted successfully",
  "deleted_image": "noovos_123_1234567890"  // string, the deleted image name
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"IMAGE_NOT_FOUND"
"DELETE_ERROR"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/delete_image
Headers:
  Content-Type: application/json
  Authorization: Bearer {{jwt_token}}
Body (raw JSON):
{
  "image_name": "noovos_123_1234567890",
  "folder": "noovos"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const cloudinary = require('cloudinary').v2;
const verifyToken = require('../middleware/auth');

// Configure Cloudinary with environment variables
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

// POST /delete_image
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { image_name, folder = 'noovos' } = req.body;

        // Validate required fields
        if (!image_name) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Image name is required"
            });
        }

        // Construct the full public ID for Cloudinary
        const publicId = `${folder}/${image_name}`;

        console.log(`Attempting to delete image from Cloudinary: ${publicId}`);

        // Delete image from Cloudinary
        try {
            const deleteResult = await cloudinary.uploader.destroy(publicId, {
                resource_type: 'image'
            });

            console.log('Cloudinary delete result:', deleteResult);

            // Check if deletion was successful
            if (deleteResult.result === 'ok') {
                console.log(`Image deleted successfully from Cloudinary: ${publicId}`);

                // Return success response
                return res.status(200).json({
                    return_code: "SUCCESS",
                    message: "Image deleted successfully",
                    deleted_image: image_name
                });
            } else if (deleteResult.result === 'not found') {
                // Image was not found in Cloudinary (might have been already deleted)
                console.log(`Image not found in Cloudinary: ${publicId}`);

                return res.status(404).json({
                    return_code: "IMAGE_NOT_FOUND",
                    message: "Image not found in cloud storage"
                });
            } else {
                // Other deletion errors
                console.error('Unexpected Cloudinary delete result:', deleteResult);

                return res.status(500).json({
                    return_code: "DELETE_ERROR",
                    message: "Failed to delete image from cloud storage"
                });
            }

        } catch (cloudinaryError) {
            console.error('Cloudinary deletion error:', cloudinaryError);

            return res.status(500).json({
                return_code: "DELETE_ERROR",
                message: "Failed to delete image from cloud storage"
            });
        }

    } catch (error) {
        console.error('Server error in delete_image:', error);

        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An internal server error occurred"
        });
    }
});

module.exports = router;
