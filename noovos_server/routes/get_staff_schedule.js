/*
=======================================================================================================================================
API Route: get_staff_schedule
=======================================================================================================================================
Method: POST
Purpose: Retrieves staff schedules for a business, optionally filtered by staff member
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 10,                   // integer, required - ID of the business
  "staff_id": 21                       // integer, optional - ID of the staff member to filter by
}

Success Response:
{
  "return_code": "SUCCESS",
  "schedules": [
    {
      "id": 5,                         // integer - Schedule entry ID
      "staff_id": 21,                  // integer - Staff member ID
      "staff_name": "Andreas Andreou", // string - Staff member's full name
      "staff_email": "andreas@example.com", // string - Staff member's email
      "day_of_week": "Monday",         // string - Day of the week
      "start_time": "09:00 AM",        // string - Start time (formatted)
      "end_time": "05:00 PM",          // string - End time (formatted)
      "start_date": "2023-06-01",      // string - Start date (YYYY-MM-DD)
      "end_date": "2023-12-31",        // string - End date (YYYY-MM-DD) or null if no end date
      "week": 1                        // integer - Week number in the rotation (1, 2, etc.)
    },
    ...
  ]
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Business ID is required"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "You do not have permission to view staff schedules for this business"
}
{
  "return_code": "NO_SCHEDULES_FOUND",
  "message": "No staff schedules found for this business"
}
{
  "return_code": "SERVER_ERROR",
  "message": "An error occurred while retrieving staff schedules"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /get_staff_schedule
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id, staff_id } = req.body;

        // Validate required fields
        if (!business_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID is required"
            });
        }

        // Check if the user has permission to view staff schedules for this business
        // User must be either a business owner or a staff member of the business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 
             AND (role = 'business_owner' OR role = 'staff')
             AND status = 'active'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to view staff schedules for this business"
            });
        }

        // Build the query parameters
        const queryParams = [business_id];
        let paramIndex = 2; // Start from $2 since $1 is business_id

        // Build the query with optional filters
        let query = `
            SELECT
                ss.id,
                ss.staff_id,
                u.first_name || ' ' || u.last_name AS staff_name,
                u.email AS staff_email,
                ss.day_of_week,
                TO_CHAR(ss.start_time, 'HH12:MI AM') AS start_time,
                TO_CHAR(ss.end_time, 'HH12:MI AM') AS end_time,
                TO_CHAR(ss.start_date, 'YYYY-MM-DD') AS start_date,
                CASE 
                    WHEN ss.end_date IS NOT NULL THEN TO_CHAR(ss.end_date, 'YYYY-MM-DD')
                    ELSE NULL
                END AS end_date,
                ss.week
            FROM
                staff_schedule ss
            JOIN
                app_user u ON ss.staff_id = u.id
            WHERE
                ss.business_id = $1
        `;

        // Add staff_id filter if provided
        if (staff_id) {
            query += ` AND ss.staff_id = $${paramIndex}`;
            queryParams.push(staff_id);
            paramIndex++;
        }

        // Add order by clause
        query += `
            ORDER BY
                u.last_name,
                u.first_name,
                ss.week,
                ss.day_of_week,
                ss.start_time
        `;

        // Execute the query
        const result = await pool.query(query, queryParams);

        // Check if any schedules were found
        if (result.rows.length === 0) {
            return res.status(404).json({
                return_code: "NO_SCHEDULES_FOUND",
                message: "No staff schedules found for this business"
            });
        }

        // Return success response with schedules list
        return res.status(200).json({
            return_code: "SUCCESS",
            schedules: result.rows
        });
    } catch (error) {
        console.error('Error in get_staff_schedule:', error);
        
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving staff schedules"
        });
    }
});

module.exports = router;
