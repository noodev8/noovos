/*
=======================================================================================================================================
API Route: get_service_staff
=======================================================================================================================================
Method: POST
Purpose: Retrieves the list of staff members who can perform a specific service.
Authentication: Not required - This endpoint is publicly accessible
=======================================================================================================================================
Request Payload:
{
  "service_id": 7                     // integer, required - ID of the service to retrieve staff for
}

Success Response:
{
  "return_code": "SUCCESS",
  "staff": [
    {
      "staff_id": 1,                  // integer - Unique staff ID
      "appuser_id": 10,               // integer - ID of the app user associated with this staff
      "first_name": "John",           // string - First name of the staff member
      "last_name": "Smith",           // string - Last name of the staff member
      "role": "therapist",            // string - Role in the business
      "image_name": "john.jpg",       // string - Image name of the staff member
      "bio": "Experienced therapist...", // string - Biography of the staff member
      "is_active": true               // boolean - Whether the staff member is active
    },
    ...
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"SERVICE_NOT_FOUND"
"NO_STAFF_FOUND"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /get_service_staff
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

        // First, check if the service exists
        const serviceQuery = `
            SELECT id, business_id
            FROM service
            WHERE id = $1 AND active = true;
        `;

        // Execute the service query
        const serviceResult = await pool.query(serviceQuery, [service_id]);

        // Check if service exists
        if (serviceResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "Service not found or inactive"
            });
        }

        // Get the business_id from the service
        const businessId = serviceResult.rows[0].business_id;

        // Define the SQL query to get staff members for the service
        const staffQuery = `
            SELECT
                s.id AS staff_id,
                s.appuser_id,
                u.first_name,
                u.last_name,
                s.role,
                s.image_name,
                s.bio,
                s.is_active
            FROM
                staff s
            JOIN
                service_staff ss ON s.appuser_id = ss.appuser_id
            JOIN
                app_user u ON s.appuser_id = u.id
            WHERE
                ss.service_id = $1
                AND s.business_id = $2
                AND s.is_active = true
            ORDER BY
                u.first_name, u.last_name;
        `;

        // Execute the staff query
        const staffResult = await pool.query(staffQuery, [service_id, businessId]);

        // Check if any staff members were found
        if (staffResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "NO_STAFF_FOUND",
                message: "No staff members found for this service"
            });
        }

        // Return success response with staff list
        return res.status(200).json({
            return_code: "SUCCESS",
            staff: staffResult.rows
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Get service staff error:", error.message);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving staff details: " + error.message
        });
    }
});

module.exports = router;
