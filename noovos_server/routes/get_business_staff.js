/*
=======================================================================================================================================
API Route: get_business_staff
=======================================================================================================================================
Method: POST
Purpose: Retrieves all staff members for a business (including pending requests)
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "business_id": 5                    // integer, required - ID of the business
}

Success Response:
{
  "return_code": "SUCCESS",
  "staff": [
    {
      "id": 10,                       // integer - ID of the appuser_business_role record
      "appuser_id": 15,               // integer - ID of the app user
      "first_name": "John",           // string - First name of the staff member
      "last_name": "Smith",           // string - Last name of the staff member
      "email": "john@example.com",    // string - Email of the staff member
      "role": "Staff",                // string - Role in the business (Staff or business_owner)
      "status": "active",             // string - Status of the staff member (active, pending)
      "requested_at": "2023-05-01T...",// timestamp - When the request was sent
      "responded_at": "2023-05-02T..."// timestamp or null - When the request was responded to
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
  "message": "You do not have permission to view staff for this business"
}
{
  "return_code": "SERVER_ERROR",
  "message": "An error occurred while processing your request"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /get_business_staff
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { business_id } = req.body;

        // Validate required fields
        if (!business_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID is required"
            });
        }

        // Check if the user has permission to view staff for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to view staff for this business"
            });
        }

        // Query to get all staff members for the business
        const staffQuery = `
            SELECT
                abr.id,
                abr.appuser_id,
                u.first_name,
                u.last_name,
                u.email,
                abr.role,
                abr.status,
                abr.requested_at,
                abr.responded_at
            FROM
                appuser_business_role abr
            JOIN
                app_user u ON abr.appuser_id = u.id
            WHERE
                abr.business_id = $1
            ORDER BY
                abr.status DESC, -- Active first, then pending
                u.first_name,
                u.last_name
        `;

        const staffResult = await pool.query(staffQuery, [business_id]);

        // Return success response with staff list
        return res.status(200).json({
            return_code: "SUCCESS",
            staff: staffResult.rows
        });

    } catch (error) {
        console.error("Error in get_business_staff:", error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
