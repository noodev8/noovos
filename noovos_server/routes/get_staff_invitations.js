/*
=======================================================================================================================================
API Route: get_staff_invitations
=======================================================================================================================================
Method: POST
Purpose: Retrieves pending staff invitations for the authenticated user
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  // No additional parameters required, user ID is extracted from JWT token
}

Success Response:
{
  "return_code": "SUCCESS",
  "invitations": [
    {
      "id": 10,                       // integer - ID of the appuser_business_role record
      "business_id": 5,               // integer - ID of the business
      "business_name": "Zen Den",     // string - Name of the business
      "role": "Staff",                // string - Role in the business (Staff or business_owner)
      "requested_at": "2023-05-01T...",// timestamp - When the request was sent
      "business_image": "image.jpg"   // string or null - Business image
    },
    ...
  ]
}

Error Responses:
{
  "return_code": "UNAUTHORIZED",
  "message": "Authentication required"
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

// POST /get_staff_invitations
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Query to get pending invitations for the user
        const query = `
            SELECT
                abr.id,
                abr.business_id,
                b.name AS business_name,
                abr.role,
                abr.requested_at,
                (
                    SELECT m.image_name
                    FROM media m
                    WHERE m.business_id = b.id AND m.position = 1 AND m.is_active = TRUE
                    LIMIT 1
                ) AS business_image
            FROM
                appuser_business_role abr
            JOIN
                business b ON abr.business_id = b.id
            WHERE
                abr.appuser_id = $1
                AND abr.status = 'pending'
            ORDER BY
                abr.requested_at DESC
        `;

        // Execute the query
        const result = await pool.query(query, [userId]);

        // Return success response with invitations
        return res.status(200).json({
            return_code: "SUCCESS",
            invitations: result.rows
        });

    } catch (error) {
        console.error("Error in get_staff_invitations:", error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
