/*
=======================================================================================================================================
API Route: delete_booking
=======================================================================================================================================
Method: POST
Purpose: Deletes a booking. Only business owners can delete bookings for their business.
Authentication: Required - This endpoint requires a valid JWT token and business owner role
=======================================================================================================================================
Request Payload:
{
  "booking_id": 1                        // integer, required - ID of the booking to delete
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Booking deleted successfully",
  "deleted_booking": {
    "booking_id": 1,                     // integer, deleted booking ID
    "customer_name": "John Smith",       // string, customer name
    "service_name": "Haircut",           // string, service name
    "booking_date": "2025-01-15",        // string, booking date
    "start_time": "09:00:00"             // string, start time
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"BOOKING_NOT_FOUND"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/delete_booking
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{
  "booking_id": 1
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /delete_booking
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token
        const userId = req.user.id;

        // Extract parameters from request body
        const { booking_id } = req.body;

        // Validate required fields
        if (!booking_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Booking ID is required"
            });
        }

        // Get booking details and verify it exists, also check business ownership
        const bookingQuery = await pool.query(
            `SELECT
                b.id AS booking_id,
                b.booking_date,
                b.start_time,
                b.end_time,
                b.status,
                s.service_name,
                s.business_id,
                CONCAT(customer.first_name, ' ', customer.last_name) AS customer_name,
                CONCAT(staff.first_name, ' ', staff.last_name) AS staff_name
            FROM
                booking b
            JOIN
                service s ON b.service_id = s.id
            JOIN
                app_user customer ON b.customer_id = customer.id
            JOIN
                app_user staff ON b.staff_id = staff.id
            WHERE
                b.id = $1`,
            [booking_id]
        );

        if (bookingQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "BOOKING_NOT_FOUND",
                message: "Booking not found"
            });
        }

        const booking = bookingQuery.rows[0];
        const businessId = booking.business_id;

        // Check if the user has permission to delete bookings for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, businessId]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to delete bookings for this business"
            });
        }

        // Delete the booking
        const deleteQuery = await pool.query(
            `DELETE FROM booking WHERE id = $1`,
            [booking_id]
        );

        // Return success response with deleted booking details
        return res.status(200).json({
            return_code: "SUCCESS",
            message: "Booking deleted successfully",
            deleted_booking: {
                booking_id: booking.booking_id,
                customer_name: booking.customer_name,
                service_name: booking.service_name,
                booking_date: booking.booking_date,
                start_time: booking.start_time
            }
        });

    } catch (error) {
        console.error('Error in delete_booking:', error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while deleting the booking"
        });
    }
});

module.exports = router;
