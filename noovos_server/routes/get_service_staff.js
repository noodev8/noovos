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
  "service_id": 7,                    // integer, required - ID of the service to retrieve staff for
  "staff_id": 10                     // integer, optional - ID of a specific staff member to filter by
}

Success Response:
{
  "return_code": "SUCCESS",
  "staff": [
    {
      "staff_id": 10,                 // integer - ID of the app user who is a staff member
      "appuser_id": 10,               // integer - ID of the app user associated with this staff
      "first_name": "John",           // string - First name of the staff member
      "last_name": "Smith",           // string - Last name of the staff member
      "role": "Staff",                // string - Role in the business (Staff or business_owner)
      "image_name": "john.jpg",       // string - Image name of the staff member (from media table)
      "bio": null,                    // string or null - Biography of the staff member (if available)
      "is_active": true               // boolean - Whether the staff member is active
    },
    ...
  ]
}

Note: If no staff members are found for the service, an empty staff array is returned with SUCCESS return code.
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

// POST /get_service_staff
router.post('/', async (req, res) => {
    try {
        // Extract parameters from request body
        const { service_id, staff_id } = req.body;

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
        let staffQuery = `
            SELECT
                ss.appuser_id AS staff_id,
                ss.appuser_id,
                u.first_name,
                u.last_name,
                abr.role,
                m.image_name,
                NULL AS bio,
                TRUE AS is_active
            FROM
                service_staff ss
            JOIN
                app_user u ON ss.appuser_id = u.id
            JOIN
                appuser_business_role abr ON ss.appuser_id = abr.appuser_id
            LEFT JOIN
                media m ON m.business_employee_id = ss.appuser_id AND m.position = 1
            WHERE
                ss.service_id = $1
                AND abr.business_id = $2
                AND (abr.role = 'Staff' OR abr.role = 'business_owner') -- Include both staff and business owners
        `;

        // If staff_id is provided, add it to the filter
        const queryParams = [service_id, businessId];
        if (staff_id) {
            staffQuery += `
                AND ss.appuser_id = $3
            `;
            queryParams.push(staff_id);
        }

        // Add ordering
        staffQuery += `
            ORDER BY
                u.first_name, u.last_name;
        `;

        // Execute the staff query
        const staffResult = await pool.query(staffQuery, queryParams);

        // Check if any staff members were found
        if (staffResult.rows.length === 0) {
            // Return an empty array instead of an error
            return res.status(200).json({
                return_code: "SUCCESS",
                staff: []
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
            message: "An error occurred while retrieving staff details. This may be due to recent database schema changes. Error: " + error.message
        });
    }
});

module.exports = router;

