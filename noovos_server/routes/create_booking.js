/*
=======================================================================================================================================
API Route: create_booking
=======================================================================================================================================
Method: POST
Purpose: Creates a new booking for a customer for a specific service, staff member, date and time.
Authentication: Required - This endpoint requires a valid JWT token
=======================================================================================================================================
Request Payload:
{
  "service_id": 16,                   // integer, required - ID of the service to book
  "staff_id": 21,                     // integer, required - ID of the staff member to perform the service
  "booking_date": "2025-05-04",       // string, required - Date of the booking (YYYY-MM-DD format)
  "start_time": "09:00",              // string, required - Start time of the booking (HH:MM format)
  "end_time": "09:30"                 // string, required - End time of the booking (HH:MM format)
}

Success Response:
{
  "return_code": "SUCCESS",
  "booking": {
    "id": 123,                        // integer - Booking ID
    "service_id": 16,                 // integer - Service ID
    "service_name": "Haircut",        // string - Service name
    "staff_id": 21,                   // integer - Staff ID
    "staff_name": "Andreas Andreou",  // string - Staff name
    "booking_date": "2025-05-04",     // string - Booking date (YYYY-MM-DD)
    "start_time": "09:00:00",         // string - Start time (HH:MM:SS)
    "end_time": "09:30:00",           // string - End time (HH:MM:SS)
    "status": "confirmed",            // string - Booking status
    "created_at": "2023-06-15T14:30:45.123Z" // string - Creation timestamp
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_PARAMETERS"
"SERVICE_NOT_FOUND"
"STAFF_NOT_FOUND"
"STAFF_NOT_AVAILABLE"
"BOOKING_CONFLICT"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// POST /create_booking
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract user ID from JWT token (this will be the customer ID)
        const customerId = req.user.id;

        // Extract parameters from request body
        const { service_id, staff_id, booking_date, start_time, end_time } = req.body;

        // Validate required fields
        if (!service_id || !staff_id || !booking_date || !start_time || !end_time) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "All fields are required: service_id, staff_id, booking_date, start_time, end_time"
            });
        }

        // Validate date format (YYYY-MM-DD)
        if (!isValidDate(booking_date)) {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "Invalid booking_date format. Use YYYY-MM-DD format."
            });
        }

        // Validate time format (HH:MM)
        if (!isValidTime(start_time) || !isValidTime(end_time)) {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "Invalid time format. Use HH:MM format for start_time and end_time."
            });
        }

        // Check if start_time is before end_time
        if (!isStartBeforeEnd(start_time, end_time)) {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "start_time must be before end_time"
            });
        }

        // Check if the service exists and get its details
        const serviceQuery = `
            SELECT
                s.id,
                s.service_name,
                s.duration,
                s.buffer_time,
                s.business_id
            FROM
                service s
            WHERE
                s.id = $1 AND s.active = true
        `;

        const serviceResult = await pool.query(serviceQuery, [service_id]);

        if (serviceResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "Service not found or inactive"
            });
        }

        const service = serviceResult.rows[0];
        const businessId = service.business_id;

        // Check if the staff member exists and is assigned to this service
        const staffQuery = `
            SELECT
                au.id,
                CONCAT(au.first_name, ' ', au.last_name) AS staff_name
            FROM
                app_user au
            JOIN
                service_staff ss ON au.id = ss.appuser_id
            JOIN
                appuser_business_role abr ON au.id = abr.appuser_id AND abr.business_id = $1
            WHERE
                au.id = $2
                AND ss.service_id = $3
                AND abr.status = 'active'
        `;

        const staffResult = await pool.query(staffQuery, [businessId, staff_id, service_id]);

        if (staffResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "STAFF_NOT_FOUND",
                message: "Staff member not found, not assigned to this service, or not active for this business"
            });
        }

        const staff = staffResult.rows[0];

        // Check if the staff member is available at the requested time
        // 1. Check if they have a rota entry for that day
        const rotaQuery = `
            SELECT
                id,
                start_time,
                end_time
            FROM
                staff_rota
            WHERE
                staff_id = $1
                AND rota_date = $2
                AND business_id = $3
        `;

        const rotaResult = await pool.query(rotaQuery, [staff_id, booking_date, businessId]);

        if (rotaResult.rows.length === 0) {
            return res.status(400).json({
                return_code: "STAFF_NOT_AVAILABLE",
                message: "Staff member is not scheduled to work on this date"
            });
        }

        // Check if the booking time falls within any of the staff's rota entries
        let isAvailable = false;
        for (const rota of rotaResult.rows) {
            // Convert all times to minutes since midnight for easier comparison
            const bookingStartMinutes = convertTimeToMinutes(start_time);
            const bookingEndMinutes = convertTimeToMinutes(end_time);
            const rotaStartMinutes = convertTimeToMinutes(rota.start_time);
            const rotaEndMinutes = convertTimeToMinutes(rota.end_time);

            // Check if booking time falls within rota time
            if (bookingStartMinutes >= rotaStartMinutes && bookingEndMinutes <= rotaEndMinutes) {
                isAvailable = true;
                break;
            }
        }

        if (!isAvailable) {
            return res.status(400).json({
                return_code: "STAFF_NOT_AVAILABLE",
                message: "Staff member is not scheduled to work at the requested time"
            });
        }

        // 2. Check for booking conflicts
        const conflictQuery = `
            SELECT
                id
            FROM
                booking
            WHERE
                staff_id = $1
                AND booking_date = $2
                AND status = 'confirmed'
                AND (
                    (start_time <= $3::time AND end_time > $3::time) OR
                    (start_time < $4::time AND end_time >= $4::time) OR
                    (start_time >= $3::time AND end_time <= $4::time)
                )
        `;

        const conflictResult = await pool.query(conflictQuery, [staff_id, booking_date, start_time, end_time]);

        if (conflictResult.rows.length > 0) {
            return res.status(409).json({
                return_code: "BOOKING_CONFLICT",
                message: "Staff member already has a booking at the requested time"
            });
        }

        // All checks passed, create the booking
        const createBookingQuery = `
            INSERT INTO booking (
                customer_id,
                booking_date,
                start_time,
                end_time,
                service_id,
                staff_id,
                status
            )
            VALUES ($1, $2, $3, $4, $5, $6, 'confirmed')
            RETURNING
                id,
                customer_id,
                booking_date,
                start_time,
                end_time,
                service_id,
                staff_id,
                status,
                created_at,
                updated_at
        `;

        const createBookingResult = await pool.query(createBookingQuery, [
            customerId,
            booking_date,
            start_time,
            end_time,
            service_id,
            staff_id
        ]);

        const booking = createBookingResult.rows[0];

        // Return success response with booking details
        return res.status(201).json({
            return_code: "SUCCESS",
            booking: {
                id: booking.id,
                service_id: service_id,
                service_name: service.service_name,
                staff_id: staff_id,
                staff_name: staff.staff_name,
                booking_date: booking.booking_date.toISOString().split('T')[0],
                start_time: booking.start_time,
                end_time: booking.end_time,
                status: booking.status,
                created_at: new Date(booking.created_at).toLocaleString('en-GB', {
                    timeZone: 'Europe/London',
                    hour12: false,
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    fractionalSecondDigits: 3
                }).replace(',', ''),
                updated_at: new Date(booking.updated_at).toLocaleString('en-GB', {
                    timeZone: 'Europe/London',
                    hour12: false,
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    fractionalSecondDigits: 3
                }).replace(',', '')
            }
        });

    } catch (error) {
        console.error("Create booking error:", error);

        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while creating the booking: " + error.message
        });
    }
});

/**
 * Validate date string format (YYYY-MM-DD)
 *
 * @param {string} dateStr - Date string to validate
 * @returns {boolean} - True if valid, false otherwise
 */
function isValidDate(dateStr) {
    // Check if the string matches the YYYY-MM-DD format
    const regex = /^\d{4}-\d{2}-\d{2}$/;
    if (!regex.test(dateStr)) return false;

    // Check if it's a valid date
    const date = new Date(dateStr);
    const timestamp = date.getTime();
    if (isNaN(timestamp)) return false;

    // Check if the date parts match the input
    return date.toISOString().slice(0, 10) === dateStr;
}

/**
 * Validate time string format (HH:MM)
 *
 * @param {string} timeStr - Time string to validate
 * @returns {boolean} - True if valid, false otherwise
 */
function isValidTime(timeStr) {
    // Check if the string matches the HH:MM format
    const regex = /^([01]\d|2[0-3]):([0-5]\d)$/;
    return regex.test(timeStr);
}

/**
 * Check if start time is before end time
 *
 * @param {string} startTime - Start time string (HH:MM)
 * @param {string} endTime - End time string (HH:MM)
 * @returns {boolean} - True if start is before end, false otherwise
 */
function isStartBeforeEnd(startTime, endTime) {
    return startTime < endTime;
}

/**
 * Convert time string (HH:MM) to minutes since midnight
 * @param {string} timeStr - Time string in HH:MM format
 * @returns {number} Minutes since midnight
 */
function convertTimeToMinutes(timeStr) {
    const [hours, minutes] = timeStr.split(':').map(Number);
    return hours * 60 + minutes;
}

module.exports = router;
