/*
=======================================================================================================================================
API Route: check_booking_integrity
=======================================================================================================================================
Method: POST
Purpose: Checks if there are any bookings allocated to a staff member which the staff member no longer has a rota scheduled for.
         This is used to ensure data integrity after changing staff schedules.
=======================================================================================================================================
Request Payload:
{
  "business_id": 5,                    // integer, required - Business ID to check
  "staff_id": 10                       // integer, optional - Specific staff ID to check (for faster targeted checks)
}

Success Response:
{
  "return_code": "SUCCESS",
  "orphaned_bookings": [               // Array of bookings that no longer have corresponding rota entries
    {
      "booking_id": 123,               // integer - Booking ID
      "booking_date": "2025-05-25",    // string - Date of booking
      "start_time": "14:30:00",        // string - Start time
      "end_time": "15:30:00",          // string - End time
      "service_name": "Haircut",       // string - Service name
      "staff_id": 10,                  // integer - Staff ID
      "staff_name": "John Smith",      // string - Staff name
      "customer_name": "Jane Doe"      // string - Customer name
    }
  ],
  "count": 1                           // integer - Total count of orphaned bookings
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"MISSING_FIELDS"
"INVALID_BUSINESS"
"SERVER_ERROR"
=======================================================================================================================================
*/

// Import required modules
const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth');

// Define API route
router.post('/', verifyToken, async (req, res) => {
    try {
        // Extract parameters from request body
        const { business_id, staff_id } = req.body;
        
        // Validate required parameters
        if (!business_id) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Business ID is required"
            });
        }
        
        // Validate that the business exists
        const businessQuery = await pool.query(
            `SELECT 1 FROM business WHERE id = $1`,
            [business_id]
        );
        
        if (businessQuery.rows.length === 0) {
            return res.status(400).json({
                return_code: "INVALID_BUSINESS",
                message: "The specified business does not exist"
            });
        }
        
        // Validate staff_id if provided
        if (staff_id) {
            const staffQuery = await pool.query(
                `SELECT 1 FROM appuser_business_role
                 WHERE appuser_id = $1 AND business_id = $2 
                 AND (role = 'Staff' OR role = 'business_owner') 
                 AND status = 'active'`,
                [staff_id, business_id]
            );
            
            if (staffQuery.rows.length === 0) {
                return res.status(400).json({
                    return_code: "INVALID_STAFF",
                    message: "The specified staff member does not belong to this business"
                });
            }
        }
        
        // Build the query to find orphaned bookings
        // This query finds bookings where there is no corresponding staff_rota entry
        // that covers the booking time period
        let orphanedBookingsQuery = `
            SELECT 
                b.id AS booking_id,
                b.booking_date,
                b.start_time,
                b.end_time,
                b.staff_id,
                s.service_name,
                CONCAT(au.first_name, ' ', au.last_name) AS staff_name,
                CONCAT(c.first_name, ' ', c.last_name) AS customer_name
            FROM 
                booking b
            JOIN 
                service s ON b.service_id = s.id
            JOIN 
                app_user au ON b.staff_id = au.id
            JOIN 
                app_user c ON b.customer_id = c.id
            WHERE 
                b.status = 'confirmed'
                AND s.business_id = $1
                AND booking_date >= CURRENT_DATE
                AND NOT EXISTS (
                    SELECT 1
                    FROM staff_rota sr
                    WHERE 
                        sr.staff_id = b.staff_id
                        AND sr.business_id = $1
                        AND sr.rota_date = b.booking_date
                        AND sr.start_time <= b.start_time
                        AND sr.end_time >= b.end_time
                )
        `;
        
        const queryParams = [business_id];
        
        // Add staff_id filter if provided
        if (staff_id) {
            orphanedBookingsQuery += ` AND b.staff_id = $2`;
            queryParams.push(staff_id);
        }
        
        // Order by date and time for better readability
        orphanedBookingsQuery += ` ORDER BY b.booking_date, b.start_time`;
        
        // Execute the query
        const orphanedBookingsResult = await pool.query(orphanedBookingsQuery, queryParams);
        
        // Return the results
        return res.status(200).json({
            return_code: "SUCCESS",
            orphaned_bookings: orphanedBookingsResult.rows,
            count: orphanedBookingsResult.rows.length
        });
        
    } catch (error) {
        // Log the error for debugging
        console.error("Error in check_booking_integrity:", error);
        
        // Return a generic error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while checking booking integrity"
        });
    }
});

module.exports = router; 