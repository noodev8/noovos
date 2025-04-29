/*
=======================================================================================================================================
API Route: get_staff_rota
=======================================================================================================================================
Method: POST
Purpose: Retrieves staff rota entries for a business
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 5,                   // integer, required - ID of the business
  "staff_id": 10,                     // integer, optional - Filter by specific staff member
  "start_date": "2025-05-01",         // string, optional - Start date for filtering (YYYY-MM-DD)
  "end_date": "2025-05-31"            // string, optional - End date for filtering (YYYY-MM-DD)
}
=======================================================================================================================================
Response:
{
  "return_code": "SUCCESS",
  "rota": [
    {
      "id": 1,
      "staff_id": 10,
      "staff_name": "John Doe",
      "staff_email": "john.doe@example.com",
      "rota_date": "2025-05-01",
      "start_time": "09:00 AM",
      "end_time": "05:00 PM"
    },
    ...
  ]
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /get_staff_rota
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id, staff_id, start_date, end_date } = req.body;

        // Validate required fields
        if (!business_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID is required"
            });
        }

        // Check if the user has permission to view staff rota for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to view staff rota for this business"
            });
        }

        // Build the query parameters
        const queryParams = [business_id];
        let paramIndex = 2; // Start from $2 since $1 is business_id

        // Build the query with optional filters
        let query = `
            SELECT
                sr.id,
                sr.staff_id,
                u.first_name || ' ' || u.last_name AS staff_name,
                u.email AS staff_email,
                TO_CHAR(sr.rota_date, 'YYYY-MM-DD') AS rota_date,
                TO_CHAR(sr.start_time, 'HH12:MI AM') AS start_time,
                TO_CHAR(sr.end_time, 'HH12:MI AM') AS end_time
            FROM
                staff_rota sr
            JOIN
                app_user u ON sr.staff_id = u.id
            JOIN
                appuser_business_role abr ON u.id = abr.appuser_id
            WHERE
                abr.business_id = $1
        `;

        // Add staff_id filter if provided
        if (staff_id) {
            query += ` AND sr.staff_id = $${paramIndex}`;
            queryParams.push(staff_id);
            paramIndex++;
        }

        // Add start_date filter if provided
        if (start_date) {
            query += ` AND sr.rota_date >= $${paramIndex}`;
            queryParams.push(start_date);
            paramIndex++;
        }

        // Add end_date filter if provided
        if (end_date) {
            query += ` AND sr.rota_date <= $${paramIndex}`;
            queryParams.push(end_date);
            paramIndex++;
        }

        // Add order by clause
        query += `
            ORDER BY
                sr.rota_date,
                sr.start_time,
                u.last_name
        `;

        // Execute the query
        const result = await pool.query(query, queryParams);

        // Return success response with rota list
        return res.status(200).json({
            return_code: "SUCCESS",
            rota: result.rows
        });
    } catch (error) {
        console.error('Error in get_staff_rota:', error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving staff rota"
        });
    }
});

module.exports = router;
