/*
=======================================================================================================================================
API Route: respond_to_staff_invitation
=======================================================================================================================================
Method: POST
Purpose: Allows users to accept or reject staff invitations
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "invitation_id": 5,                 // integer, required - ID of the appuser_business_role record
  "action": "accept"                  // string, required - Action to take (accept or reject)
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Invitation accepted successfully" // or "Invitation rejected successfully"
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Invitation ID and action are required"
}
{
  "return_code": "INVALID_ACTION",
  "message": "Action must be either 'accept' or 'reject'"
}
{
  "return_code": "INVITATION_NOT_FOUND",
  "message": "Invitation not found"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "You do not have permission to respond to this invitation"
}
{
  "return_code": "NOT_PENDING",
  "message": "This invitation is not in a pending state"
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

// POST /respond_to_staff_invitation
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { invitation_id, action } = req.body;

        // Validate required fields
        if (!invitation_id || !action) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Invitation ID and action are required"
            });
        }

        // Validate action
        if (action !== 'accept' && action !== 'reject') {
            return res.status(400).json({
                return_code: "INVALID_ACTION",
                message: "Action must be either 'accept' or 'reject'"
            });
        }

        // Get the invitation details
        const invitationQuery = await pool.query(
            `SELECT status, appuser_id FROM appuser_business_role WHERE id = $1`,
            [invitation_id]
        );

        if (invitationQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "INVITATION_NOT_FOUND",
                message: "Invitation not found"
            });
        }

        const invitation = invitationQuery.rows[0];

        // Check if the invitation belongs to the user
        if (invitation.appuser_id !== userId) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to respond to this invitation"
            });
        }

        // Check if the invitation is in a pending state
        if (invitation.status !== 'pending') {
            return res.status(400).json({
                return_code: "NOT_PENDING",
                message: "This invitation is not in a pending state"
            });
        }

        // Update the invitation status based on the action
        const newStatus = action === 'accept' ? 'active' : 'rejected';

        await pool.query(
            `UPDATE appuser_business_role
             SET status = $1, responded_at = NOW()
             WHERE id = $2`,
            [newStatus, invitation_id]
        );

        // Return success response
        const message = action === 'accept'
            ? "Invitation accepted successfully"
            : "Invitation rejected successfully";

        return res.status(200).json({
            return_code: "SUCCESS",
            message: message
        });

    } catch (error) {
        console.error("Error in respond_to_staff_invitation:", error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router;
