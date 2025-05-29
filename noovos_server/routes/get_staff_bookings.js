/*
=======================================================================================================================================
API Route: get_staff_bookings
=======================================================================================================================================
Method: POST
Purpose: Retrieves all bookings assigned to the logged-in staff member. This allows staff to see their own bookings and indicates their business connection.
Authentication: Required - This endpoint requires a valid JWT token. Staff can only see their own bookings.
=======================================================================================================================================
Request Payload:
{
  "business_id": 10,                     // integer, optional - Filter by specific business (if staff works for multiple businesses)
  "start_date": "2025-01-01",           // string, optional - Start date filter (YYYY-MM-DD)
  "end_date": "2025-01-31"              // string, optional - End date filter (YYYY-MM-DD)
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
      "service_currency": "GBP",         // string, service currency
      "business_name": "Hair Salon",     // string, business name where the service is provided
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
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
Postman Testing:
POST {{base_url}}/get_staff_bookings
Authorization: Bearer {{jwt_token}}
Content-Type: application/json

{
}

// With business filter:
{
  "business_id": 10
}

// With date range filter:
{
  "start_date": "2025-01-01",
  "end_date": "2025-01-31"
}

// With all filters:
{
  "business_id": 10,
  "start_date": "2025-01-01",
  "end_date": "2025-01-31"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /get_staff_bookings
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token - this is the staff member's ID
        const userId = req.user.id;

        // Extract optional parameters from request body
        const { business_id, start_date, end_date } = req.body;

        // Build the query to get bookings where the logged-in user is the staff member
        // This query joins multiple tables to get comprehensive booking information
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
                bus.name AS business_name,
                CONCAT(customer.first_name, ' ', customer.last_name) AS customer_name,
                customer.email AS customer_email,
                customer.mobile AS customer_mobile
            FROM
                booking b
            JOIN
                service s ON b.service_id = s.id
            JOIN
                business bus ON s.business_id = bus.id
            JOIN
                app_user customer ON b.customer_id = customer.id
            WHERE
                b.staff_id = $1
        `;

        // Start with the staff ID as the first parameter
        let queryParams = [userId];
        let paramIndex = 2;

        // Add business filter if provided
        if (business_id) {
            bookingsQuery += ` AND s.business_id = $${paramIndex}`;
            queryParams.push(business_id);
            paramIndex++;
        }

        // Add start date filter if provided
        if (start_date) {
            bookingsQuery += ` AND b.booking_date >= $${paramIndex}`;
            queryParams.push(start_date);
            paramIndex++;
        }

        // Add end date filter if provided
        if (end_date) {
            bookingsQuery += ` AND b.booking_date <= $${paramIndex}`;
            queryParams.push(end_date);
            paramIndex++;
        }

        // Order by booking date and time (upcoming bookings first)
        bookingsQuery += `
            ORDER BY
                b.booking_date ASC,
                b.start_time ASC
        `;

        // Execute the query
        const bookingsResult = await pool.query(bookingsQuery, queryParams);

        // Format the response to ensure consistent data types
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
            business_name: row.business_name,
            customer_name: row.customer_name,
            customer_email: row.customer_email,
            customer_mobile: row.customer_mobile,
            created_at: row.created_at
        }));

        // Return success response with bookings
        return res.status(200).json({
            return_code: "SUCCESS",
            bookings: bookings
        });

    } catch (error) {
        // Log the error for debugging purposes
        console.error('Error in get_staff_bookings:', error);
        console.error('Error details:', {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return server error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving staff bookings"
        });
    }
});

module.exports = router;
