/*
=======================================================================================================================================
API Route: get_service_slot_x1
=======================================================================================================================================
Method: POST
Purpose: Retrieves available time slots for a specific service booking using an optimized SQL query.
Authentication: Not required - This endpoint is publicly accessible
=======================================================================================================================================
Request Payload:
{
  "service_id": 7,                     // integer, required - ID of the service to find slots for
  "date": "2025-05-04",                // string, required - Date to find slots for (YYYY-MM-DD format)
  "staff_id": 10,                      // integer, optional - ID of the specific staff member to check
  "time_preference": "morning"         // string, optional - Preferred time of day: "morning", "afternoon", or "any" (default: "any")
}

Success Response:
{
  "return_code": "SUCCESS",
  "service": {
    "id": 7,                          // integer - Service ID
    "name": "Deep Tissue Massage",     // string - Service name
    "business_name": "Wellness Spa",   // string - Business name
    "duration": 45,                   // integer - Service duration in minutes
    "buffer_time": 15,                // integer - Buffer time in minutes
    "total_duration": 60,             // integer - Total duration (service + buffer) in minutes
    "price": 75.00,                   // decimal - Service price
    "currency": "GBP"                  // string - Currency code
  },
  "time_preference": "morning",        // string - The time preference used for filtering ("morning", "afternoon", or "any")
  "slots": [
    {
      "start_time": "09:00:00",        // string - Start time of the slot (HH:MM:SS format)
      "end_time": "10:00:00",          // string - End time of the slot (HH:MM:SS format, includes buffer time)
      "staff_id": 10,                  // integer - ID of the staff member who can perform the service
      "staff_name": "John Smith"       // string - Name of the staff member
    },
    ...
  ]
}

Implementation Notes:
- Uses a single optimized SQL query to find available slots
- Generates slots on a 15-minute grid (9:00, 9:15, 9:30, etc.)
- Returns up to 3 earliest available slots
- Handles staff preferences and time of day filtering
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_PARAMETERS"
"SERVICE_NOT_FOUND"
"NO_SLOTS_AVAILABLE"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /get_service_slot_x1
router.post('/', async (req, res) => {
    try {
        // Extract parameters from request body
        const { service_id, date, staff_id, time_preference } = req.body;

        // Set default time preference to "any" if not provided
        const timeOfDay = time_preference ? time_preference.toLowerCase() : "any";

        // Validate time preference if provided
        if (timeOfDay !== "any" && timeOfDay !== "morning" && timeOfDay !== "afternoon") {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "Time preference must be 'morning', 'afternoon', or 'any'"
            });
        }

        // Validate required parameters
        if (!service_id || isNaN(parseInt(service_id))) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid service_id is required"
            });
        }

        if (!date || !isValidDate(date)) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid date is required (YYYY-MM-DD format)"
            });
        }

        // First, check if the service exists and get its details
        const serviceQuery = `
            SELECT
                s.id,
                s.business_id,
                s.service_name,
                s.duration,
                s.buffer_time,
                s.price,
                s.currency,
                b.name AS business_name
            FROM
                service s
            JOIN
                business b ON s.business_id = b.id
            WHERE
                s.id = $1 AND s.active = true;
        `;

        // Execute the service query
        const serviceResult = await pool.query(serviceQuery, [service_id]);

        // Check if service exists
        if (serviceResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "Service not found or inactive"
            });
        }

        // Get the service details
        const service = serviceResult.rows[0];
        const serviceDuration = service.duration; // Duration in minutes
        const bufferTime = service.buffer_time || 0; // Buffer time in minutes
        const totalDuration = serviceDuration + bufferTime; // Total time needed for the service

        // Use the optimized SQL query to find available slots
        const availableSlotsQuery = `
        WITH
          -- 1) Your single service (cast staff_id_pref to integer)
          service_input(ord, service_id, duration_min, staff_id_pref) AS (
            VALUES
              (1, $1::integer, $2::integer, $3::integer)
          ),

          -- 2) Which staff can do it
          service_opts AS (
            SELECT
              ss.appuser_id AS staff_id,
              si.duration_min
            FROM service_input si
            JOIN service_staff ss
              ON ss.service_id = si.service_id
            WHERE si.ord = 1
              AND (si.staff_id_pref IS NULL OR ss.appuser_id = si.staff_id_pref)
          ),

          -- 3) Build each staff member's free intervals on the target date
          staff_busyness AS (
            SELECT
              staff_id,
              (rota_date + start_time)::timestamp AS busy_start,
              (rota_date + end_time)::timestamp AS busy_end
            FROM staff_rota
            WHERE rota_date = $4
          ),
          staff_bookings AS (
            SELECT
              staff_id,
              (booking_date + start_time)::timestamp AS b_start,
              (booking_date + end_time)::timestamp AS b_end
            FROM booking
            WHERE booking_date = $4
              AND status != 'cancelled'
          ),
          staff_free AS (
            SELECT
              sb.staff_id,
              slot.free_start,
              slot.free_end
            FROM staff_busyness sb
            LEFT JOIN LATERAL (
              SELECT
                pts[idx]   AS free_start,
                pts[idx+1] AS free_end
              FROM (
                SELECT array_agg(ts ORDER BY ts) AS pts
                FROM (
                  SELECT busy_start AS ts FROM staff_busyness   WHERE staff_id = sb.staff_id
                  UNION ALL
                  SELECT busy_end   AS ts FROM staff_busyness   WHERE staff_id = sb.staff_id
                  UNION ALL
                  SELECT b_start    AS ts FROM staff_bookings   WHERE staff_id = sb.staff_id
                  UNION ALL
                  SELECT b_end      AS ts FROM staff_bookings   WHERE staff_id = sb.staff_id
                ) AS all_ts
              ) AS arr,
              generate_series(1, array_length(arr.pts,1)-1) AS idx
            ) AS slot ON slot.free_start < slot.free_end
          ),

          -- 4) Generate 15-minute grid starts for the service
          service1_slots AS (
            SELECT
              o.staff_id,
              gs AS slot_start,
              o.duration_min,
              (gs + (o.duration_min * INTERVAL '1 minute')) AS slot_end
            FROM service_opts o
            JOIN staff_free fs ON fs.staff_id = o.staff_id
            CROSS JOIN LATERAL (
              SELECT generate_series(
                -- round UP free_start to next quarter hour:
                date_trunc('hour', fs.free_start)
                  + CEIL(date_part('minute', fs.free_start)::numeric/15)
                    * INTERVAL '15 minute',
                -- last possible start so it fits entirely before free_end:
                fs.free_end - (o.duration_min * INTERVAL '1 minute'),
                INTERVAL '15 minute'
              ) AS gs
            ) AS minutes
            WHERE
              -- Apply time preference filter if specified
              CASE
                WHEN $5 = 'morning' THEN gs::time < '12:00'
                WHEN $5 = 'afternoon' THEN gs::time >= '12:00'
                ELSE TRUE -- 'any' time preference
              END
          )

        -- 5) Pick the earliest 3 slots, ordered by start time
        SELECT
          ROW_NUMBER() OVER (ORDER BY slot_start) AS rank,
          staff_id,
          slot_start,
          slot_end
        FROM service1_slots
        ORDER BY slot_start
        LIMIT 3;
        `;

        // Set up query parameters
        const queryParams = [
            service_id,                  // $1: Service ID
            totalDuration,               // $2: Total duration (including buffer)
            staff_id || null,            // $3: Preferred staff (or null)
            date,                        // $4: Date to find slots for
            timeOfDay                    // $5: Time preference (morning, afternoon, any)
        ];

        // Execute the query to get available slots
        const availableSlotsResult = await pool.query(availableSlotsQuery, queryParams);

        // If no slots are found, return appropriate message
        if (availableSlotsResult.rows.length === 0) {
            let message = "No available slots found for the requested date";

            // Add more specific message based on time preference
            if (timeOfDay === "morning") {
                message = "No morning slots available for the requested date";
            } else if (timeOfDay === "afternoon") {
                message = "No afternoon slots available for the requested date";
            }

            return res.status(404).json({
                return_code: "NO_SLOTS_AVAILABLE",
                message: message
            });
        }

        // Get staff information for display
        const staffInfoQuery = `
            SELECT
                au.id AS staff_id,
                CONCAT(au.first_name, ' ', au.last_name) AS staff_name
            FROM
                app_user au
            WHERE
                au.id = ANY($1);
        `;

        // Extract all staff IDs from the results
        const staffIds = availableSlotsResult.rows.map(row => row.staff_id);

        // Get staff names
        const staffInfoResult = await pool.query(staffInfoQuery, [staffIds]);

        // Create a lookup map for staff names
        const staffInfo = {};
        staffInfoResult.rows.forEach(staff => {
            staffInfo[staff.staff_id] = staff.staff_name;
        });

        // Format the results into the expected slots format
        const formattedSlots = availableSlotsResult.rows.map(row => {
            // Format times to HH:MM:SS
            const formatTime = (dateTime) => {
                const date = new Date(dateTime);
                return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:00`;
            };

            return {
                start_time: formatTime(row.slot_start),
                end_time: formatTime(row.slot_end),
                staff_id: row.staff_id,
                staff_name: staffInfo[row.staff_id] || "Unknown Staff"
            };
        });

        // Return success response with available slots and service details
        return res.status(200).json({
            return_code: "SUCCESS",
            service: {
                id: service.id,
                name: service.service_name,
                business_name: service.business_name,
                duration: service.duration,
                buffer_time: service.buffer_time,
                total_duration: totalDuration,
                price: service.price,
                currency: service.currency
            },
            time_preference: timeOfDay,
            slots: formattedSlots
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Get service slot x1 error:", error.message);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving available slots: " + error.message
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

module.exports = router;

