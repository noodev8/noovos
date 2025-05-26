/*
=======================================================================================================================================
API Route: delete_service
=======================================================================================================================================
Method: POST
Purpose: Soft deletes a service by setting active=false. Only business owners and staff can delete services for their business.
=======================================================================================================================================
Request Payload:
{
  "service_id": 456                      // integer, required - ID of the service to delete
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Service deleted successfully",
  "service": {
    "id": 456,                           // integer, service ID
    "business_id": 123,                  // integer, business ID
    "service_name": "Hair Cut",          // string, service name
    "description": "Professional haircut", // string, description
    "duration": 60,                      // integer, duration
    "price": 25.50,                      // number, price
    "currency": "GBP",                   // string, currency
    "active": false,                     // boolean, now set to false
    "buffer_time": 15,                   // integer, buffer time
    "category_id": 5,                    // integer, category ID
    "created_at": "2024-01-15T10:30:00Z", // timestamp
    "updated_at": "2024-01-15T12:00:00Z"  // timestamp, updated
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"UNAUTHORIZED"
"SERVICE_NOT_FOUND"
"SERVICE_ALREADY_DELETED"
"SERVICE_HAS_BOOKINGS"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{baseUrl}}/delete_service
Headers:
  Authorization: Bearer {{token}}
  Content-Type: application/json
Body:
{
  "service_id": 1
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /delete_service
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { service_id } = req.body;

        // Validate required fields
        if (!service_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Service ID is required"
            });
        }

        // Get the current service and verify it exists
        const currentServiceQuery = await pool.query(
            `SELECT * FROM service WHERE id = $1`,
            [service_id]
        );

        if (currentServiceQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "Service not found"
            });
        }

        const currentService = currentServiceQuery.rows[0];

        // Check if service is already deleted (inactive)
        if (!currentService.active) {
            return res.status(400).json({
                return_code: "SERVICE_ALREADY_DELETED",
                message: "Service is already deleted"
            });
        }

        // Check if the user has permission to delete services for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 
             AND (role = 'business_owner' OR role = 'Staff') 
             AND status = 'active'`,
            [userId, currentService.business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to delete services for this business"
            });
        }

        // Check if the service has any active bookings
        // We should not allow deletion of services with future bookings
        const bookingQuery = await pool.query(
            `SELECT COUNT(*) as booking_count 
             FROM booking 
             WHERE service_id = $1 
             AND booking_date >= CURRENT_DATE 
             AND status NOT IN ('cancelled', 'completed')`,
            [service_id]
        );

        const bookingCount = parseInt(bookingQuery.rows[0].booking_count);

        if (bookingCount > 0) {
            return res.status(400).json({
                return_code: "SERVICE_HAS_BOOKINGS",
                message: `Cannot delete service. It has ${bookingCount} active or future booking(s). Please cancel or complete all bookings first.`
            });
        }

        // Soft delete the service by setting active = false
        const deleteServiceQuery = `
            UPDATE service 
            SET active = false, updated_at = NOW()
            WHERE id = $1
            RETURNING *
        `;

        const deletedServiceQuery = await pool.query(deleteServiceQuery, [service_id]);
        const deletedService = deletedServiceQuery.rows[0];

        console.log(`Service soft deleted successfully: ID ${service_id}, Name: ${deletedService.service_name}`);

        // Return success response with deleted service data
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Service deleted successfully",
            service: deletedService
        });

    } catch (error) {
        // Log the error for debugging purposes
        console.error("Delete service error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return a server error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while deleting the service: " + error.message
        });
    }
});

module.exports = router;
