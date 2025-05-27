/*
=======================================================================================================================================
API Route: upload_image
=======================================================================================================================================
Method: POST
Purpose: Uploads an image to Cloudinary after processing it with Sharp to reduce file size and standardize dimensions.
         Processes the image to 1000x1000 pixels maximum to reduce bandwidth and storage costs.
=======================================================================================================================================
Request Payload:
{
  "image": "base64_encoded_image_string",    // string, required - base64 encoded image data
  "folder": "services"                       // string, optional - Cloudinary folder name (default: "general")
}

Success Response:
{
  "return_code": "SUCCESS",
  "image_url": "https://res.cloudinary.com/...",  // string, full Cloudinary URL
  "public_id": "folder/filename",                  // string, Cloudinary public ID for future reference
  "width": 1000,                                   // number, processed image width
  "height": 800                                    // number, processed image height
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_IMAGE_DATA"
"PROCESSING_ERROR"
"UPLOAD_ERROR"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/upload_image
Headers:
  Content-Type: application/json
  Authorization: Bearer {{jwt_token}}
Body (raw JSON):
{
  "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD...",
  "folder": "services"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const sharp = require('sharp');
const cloudinary = require('cloudinary').v2;
const verifyToken = require('../middleware/auth');

// Configure Cloudinary with environment variables
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET
});

// POST /upload_image
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { image, folder = 'noovos' } = req.body;

        // Validate required fields
        if (!image) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Image data is required"
            });
        }

        // Validate image data format (should be base64 or data URL)
        let imageBuffer;
        try {
            // Handle data URL format (data:image/jpeg;base64,...)
            if (image.startsWith('data:image/')) {
                const base64Data = image.split(',')[1];
                if (!base64Data) {
                    throw new Error('Invalid data URL format');
                }
                imageBuffer = Buffer.from(base64Data, 'base64');
            } else {
                // Handle plain base64 string
                imageBuffer = Buffer.from(image, 'base64');
            }
        } catch (error) {
            return res.status(400).json({
                return_code: "INVALID_IMAGE_DATA",
                message: "Invalid image data format. Expected base64 or data URL."
            });
        }

        // Process image with Sharp to reduce size and standardize dimensions
        let processedImageBuffer;
        let imageMetadata;
        try {
            // Resize image to maximum 1000x1000 pixels while maintaining aspect ratio
            // Convert to JPEG with 85% quality for optimal size/quality balance
            processedImageBuffer = await sharp(imageBuffer)
                .resize(1000, 1000, {
                    fit: 'inside',           // Maintain aspect ratio, fit within bounds
                    withoutEnlargement: true // Don't enlarge smaller images
                })
                .jpeg({
                    quality: 85,             // Good quality with reasonable file size
                    progressive: true        // Progressive JPEG for better loading
                })
                .toBuffer();

            // Get metadata of processed image
            imageMetadata = await sharp(processedImageBuffer).metadata();

        } catch (error) {
            console.error('Sharp processing error:', error);
            return res.status(500).json({
                return_code: "PROCESSING_ERROR",
                message: "Failed to process image"
            });
        }

        // Upload processed image to Cloudinary
        try {
            // Generate unique filename using timestamp and user ID
            const timestamp = Date.now();
            const uniqueFilename = `${folder}_${userId}_${timestamp}`;

            // Convert buffer to base64 for Cloudinary upload
            const base64Image = `data:image/jpeg;base64,${processedImageBuffer.toString('base64')}`;

            // Upload to Cloudinary with options
            const uploadResult = await cloudinary.uploader.upload(base64Image, {
                folder: folder,                    // Organize images in folders
                public_id: uniqueFilename,        // Use unique filename
                resource_type: 'image',           // Specify resource type
                format: 'jpg',                    // Force JPEG format
                transformation: [
                    {
                        quality: 'auto:good',     // Cloudinary auto-optimization
                        fetch_format: 'auto'     // Auto-select best format for browser
                    }
                ]
            });

            // Prepare response object
            const responseData = {
                return_code: "SUCCESS",
                image_url: uploadResult.secure_url,
                public_id: uploadResult.public_id,
                image_name: uniqueFilename,       // Return the unique filename for database storage
                width: imageMetadata.width,
                height: imageMetadata.height,
                file_size: processedImageBuffer.length,
                cloudinary_bytes: uploadResult.bytes
            };

            // Return success response with image details
            return res.status(200).json(responseData);

        } catch (error) {
            console.error('Cloudinary upload error:', error);
            return res.status(500).json({
                return_code: "UPLOAD_ERROR",
                message: "Failed to upload image to cloud storage"
            });
        }

    } catch (error) {
        console.error('Upload image error:', error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "Internal server error"
        });
    }
});

module.exports = router;
