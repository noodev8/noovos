/*
=======================================================================================================================================
API Route: get_app_version
=======================================================================================================================================
Method: POST
Purpose: Returns the minimum required app version for a specific platform.
Authentication: Not required - This endpoint is publicly accessible
=======================================================================================================================================
Request Payload:
{
  "platform": "android"               // string, required - The platform of the client app (e.g., "android", "ios", "web")
}

Success Response:
{
  "return_code": "SUCCESS",
  "minimum_version": "1.0.0"          // string - The minimum required version for the platform
}
=======================================================================================================================================
Return Codes:
"SUCCESS"               - The minimum version was successfully retrieved
"MISSING_FIELDS"        - Required fields are missing from the request
"PLATFORM_NOT_FOUND"    - The specified platform is not found in the database
"SERVER_ERROR"          - An error occurred on the server
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /get_app_version
router.post('/', async (req, res) => {
    try {
        // Extract platform from request body
        const { platform } = req.body;

        // Validate required parameter
        if (!platform) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Platform is required"
            });
        }

        // Define the SQL query to get the minimum version for the platform
        const versionQuery = `
            SELECT
                minimum_version
            FROM
                app_version_requirement
            WHERE
                platform = $1;
        `;

        // Execute the query
        const versionResult = await pool.query(versionQuery, [platform.toLowerCase()]);

        // Check if the platform exists in the database
        if (versionResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "PLATFORM_NOT_FOUND",
                message: `No version requirements found for platform: ${platform}`
            });
        }

        // Get the minimum version from the result
        const minimumVersion = versionResult.rows[0].minimum_version.toString();

        // Format the version number as a string with proper format
        const formattedMinVersion = minimumVersion.includes('.')
            ? minimumVersion
            : minimumVersion + '.0';

        // Return the result
        return res.status(200).json({
            return_code: "SUCCESS",
            minimum_version: formattedMinVersion
        });

    } catch (error) {
        console.error('Error getting app version:', error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while getting the app version",
            error: error.message
        });
    }
});

module.exports = router;
