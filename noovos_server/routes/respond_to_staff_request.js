/*
=======================================================================================================================================
API Route: respond_to_staff_request
=======================================================================================================================================
Method: POST
Purpose: Allows business owners to accept or reject staff join requests
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "request_id": 5,                    // integer, required - ID of the appuser_business_role record
  "action": "accept"                  // string, required - Action to take (accept or reject)
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Staff request accepted successfully" // or "Staff request rejected successfully"
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Request ID and action are required"
}
{
  "return_code": "INVALID_ACTION",
  "message": "Action must be either 'accept' or 'reject'"
}
{
  "return_code": "REQUEST_NOT_FOUND",
  "message": "Staff request not found"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "You do not have permission to manage this business"
}
{
  "return_code": "NOT_PENDING",
  "message": "This request is not in a pending state"
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

// POST /respond_to_staff_request
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { request_id, action } = req.body;

        // Validate required fields
        if (!request_id || !action) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Request ID and action are required"
            });
        }

        // Validate action
        if (action !== 'accept' && action !== 'reject') {
            return res.status(400).json({
                return_code: "INVALID_ACTION",
                message: "Action must be either 'accept' or 'reject'"
            });
        }

        // Get the request details
        const requestQuery = await pool.query(
            `SELECT abr.business_id, abr.status
             FROM appuser_business_role abr
             WHERE abr.id = $1`,
            [request_id]
        );

        if (requestQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "REQUEST_NOT_FOUND",
                message: "Staff request not found"
            });
        }

        const request = requestQuery.rows[0];
        const businessId = request.business_id;

        // Check if the user has permission to manage this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, businessId]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to manage this business"
            });
        }

        // Check if the request is in a pending state
        if (request.status !== 'pending') {
            return res.status(400).json({
                return_code: "NOT_PENDING",
                message: "This request is not in a pending state"
            });
        }

        // Update the request status based on the action
        const newStatus = action === 'accept' ? 'active' : 'rejected';

        await pool.query(
            `UPDATE appuser_business_role
             SET status = $1, responded_at = NOW()
             WHERE id = $2`,
            [newStatus, request_id]
        );

        // Return success response
        const message = action === 'accept'
            ? "Staff request accepted successfully"
            : "Staff request rejected successfully";

        return res.status(200).json({
            return_code: "SUCCESS",
            message: message
        });

    } catch (error) {
        console.error("Error in respond_to_staff_request:", error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
