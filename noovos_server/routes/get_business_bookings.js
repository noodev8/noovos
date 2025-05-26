/*
=======================================================================================================================================
API Route: get_business_bookings
=======================================================================================================================================
Method: POST
Purpose: Retrieves all bookings for a specific business with optional staff filtering. Shows customer details for contact purposes.
Authentication: Required - This endpoint requires a valid JWT token and business owner role
=======================================================================================================================================
Request Payload:
{
  "business_id": 10,                     // integer, required - ID of the business
  "staff_id": 21                         // integer, optional - Filter by specific staff member
}

Success Response:
{
  "return_code": "SUCCESS",
  "bookings": [
    {
      "booking_id": 1,                   // integer, booking ID
      "booking_date": "2025-01-15",      // string, booking date (YYYY-MM-DD)
      "start_time": "09:00:00",          // string, start time (HH:MM:SS)
      "end_time": "10:30:00",            // string, end time (HH:MM:SS)
      "status": "confirmed",             // string, booking status
      "service_name": "Haircut",         // string, name of the service
      "service_duration": 30,            // integer, service duration in minutes
      "service_price": 20.00,            // number, service price
      "staff_name": "Andreas Andreou",   // string, staff member name
      "staff_email": "andreas@example.com", // string, staff member email
      "customer_name": "John Smith",     // string, customer name
      "customer_email": "john@example.com", // string, customer email
      "customer_mobile": "07123456789",  // string, customer mobile (can be null)
      "created_at": "2025-01-10T10:30:00Z" // string, booking creation timestamp
    }
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"BUSINESS_NOT_FOUND"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/get_business_bookings
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{
  "business_id": 10
}

// With staff filter:
{
  "business_id": 10,
  "staff_id": 21
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /get_business_bookings
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

        // Check if the user has permission to view bookings for this business
        const permissionQuery = await pool.query(
            `SELECT 1 FROM appuser_business_role
             WHERE appuser_id = $1 AND business_id = $2 AND role = 'business_owner'`,
            [userId, business_id]
        );

        if (permissionQuery.rows.length === 0) {
            return res.status(403).json({
                return_code: "UNAUTHORIZED",
                message: "You do not have permission to view bookings for this business"
            });
        }

        // Verify that the business exists
        const businessQuery = await pool.query(
            `SELECT 1 FROM business WHERE id = $1`,
            [business_id]
        );

        if (businessQuery.rows.length === 0) {
            return res.status(404).json({
                return_code: "BUSINESS_NOT_FOUND",
                message: "Business not found"
            });
        }

        // Build the query to get bookings with customer and staff details
        let bookingsQuery = `
            SELECT
                b.id AS booking_id,
                b.booking_date,
                b.start_time,
                b.end_time,
                b.status,
                b.created_at,
                s.service_name,
                s.duration AS service_duration,
                s.price AS service_price,
                s.currency AS service_currency,
                CONCAT(staff.first_name, ' ', staff.last_name) AS staff_name,
                staff.email AS staff_email,
                CONCAT(customer.first_name, ' ', customer.last_name) AS customer_name,
                customer.email AS customer_email,
                customer.mobile AS customer_mobile
            FROM
                booking b
            JOIN
                service s ON b.service_id = s.id
            JOIN
                app_user staff ON b.staff_id = staff.id
            JOIN
                app_user customer ON b.customer_id = customer.id
            WHERE
                s.business_id = $1
        `;

        let queryParams = [business_id];

        // Add staff filter if provided
        if (staff_id) {
            bookingsQuery += ` AND b.staff_id = $2`;
            queryParams.push(staff_id);
        }

        // Order by booking date and time (most recent first)
        bookingsQuery += `
            ORDER BY
                b.booking_date DESC,
                b.start_time DESC
        `;

        // Execute the query
        const bookingsResult = await pool.query(bookingsQuery, queryParams);

        // Format the response
        const bookings = bookingsResult.rows.map(row => ({
            booking_id: row.booking_id,
            booking_date: row.booking_date,
            start_time: row.start_time,
            end_time: row.end_time,
            status: row.status,
            service_name: row.service_name,
            service_duration: row.service_duration,
            service_price: parseFloat(row.service_price),
            service_currency: row.service_currency || 'GBP',
            staff_name: row.staff_name,
            staff_email: row.staff_email,
            customer_name: row.customer_name,
            customer_email: row.customer_email,
            customer_mobile: row.customer_mobile,
            created_at: row.created_at
        }));

        // Return success response
        return res.status(200).json({
            return_code: "SUCCESS",
            bookings: bookings
        });

    } catch (error) {
        console.error('Error in get_business_bookings:', error);
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving bookings"
        });
    }
});

module.exports = router;
