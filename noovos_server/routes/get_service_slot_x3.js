/*
=======================================================================================================================================
API Route: get_service_slot_x3
=======================================================================================================================================
Method: POST
Purpose: Retrieves available back-to-back time slots for three different services in sequence.
Authentication: Not required - This endpoint is publicly accessible
=======================================================================================================================================
Request Payload:
{
  "service_id_1": 16,                   // integer, required - ID of the first service
  "service_id_2": 17,                   // integer, required - ID of the second service
  "service_id_3": 16,                   // integer, required - ID of the third service
  "date": "2025-04-23",                // string, required - Date to find slots for (YYYY-MM-DD format)
  "staff_id_1": null,                   // integer, optional - Preferred staff for first service
  "staff_id_2": 26,                     // integer, optional - Preferred staff for second service
  "staff_id_3": null,                   // integer, optional - Preferred staff for third service
  "time_preference": "morning"         // string, optional - Preferred time of day for first service: "morning", "afternoon", or "any" (default: "any")
}

Success Response:
{
  "return_code": "SUCCESS",
  "time_preference": "morning",
  "services": [
    {
      "id": 16,
      "name": "Service Name 1",
      "business_name": "Business Name",
      "duration": 30,
      "buffer_time": 5,
      "total_duration": 35,
      "price": 50,
      "currency": "GBP"
    },
    {
      "id": 17,
      "name": "Service Name 2",
      "business_name": "Business Name",
      "duration": 45,
      "buffer_time": 5,
      "total_duration": 50,
      "price": 75,
      "currency": "GBP"
    },
    {
      "id": 16,
      "name": "Service Name 1",
      "business_name": "Business Name",
      "duration": 30,
      "buffer_time": 5,
      "total_duration": 35,
      "price": 50,
      "currency": "GBP"
    }
  ],
  "combined_slots": [
    {
      "service_1": {
        "start_time": "09:00:00",
        "end_time": "09:35:00",
        "staff_id": 21,
        "staff_name": "Andreas Andreou",
        "service_id": 16,
        "service_name": "Service Name 1"
      },
      "service_2": {
        "start_time": "09:35:00",
        "end_time": "10:25:00",
        "staff_id": 26,
        "staff_name": "Emma Williams",
        "service_id": 17,
        "service_name": "Service Name 2"
      },
      "service_3": {
        "start_time": "10:25:00",
        "end_time": "11:00:00",
        "staff_id": 21,
        "staff_name": "Andreas Andreou",
        "service_id": 16,
        "service_name": "Service Name 1"
      },
      "total_duration": 120,
      "start_time": "09:00:00",
      "end_time": "11:00:00"
    },
    // Additional slots...
  ]
}

Implementation Notes:
- Uses a single optimized SQL query to find available slots for all three services
- Generates slots on a 15-minute grid (9:00, 9:15, 9:30, etc.)
- Returns up to 3 earliest available slot combinations
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

// POST /get_service_slot_x3
router.post('/', async (req, res) => {
    try {
        // Extract parameters from request body
        const {
            service_id_1,
            service_id_2,
            service_id_3,
            date,
            staff_id_1,
            staff_id_2,
            staff_id_3,
            time_preference
        } = req.body;

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
        if (!service_id_1 || isNaN(parseInt(service_id_1)) ||
            !service_id_2 || isNaN(parseInt(service_id_2)) ||
            !service_id_3 || isNaN(parseInt(service_id_3))) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid service_id_1, service_id_2, and service_id_3 are required"
            });
        }

        if (!date || !isValidDate(date)) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid date is required (YYYY-MM-DD format)"
            });
        }

        // Check if services exist and get their details
        // We need to get all unique service IDs
        const uniqueServiceIds = [...new Set([service_id_1, service_id_2, service_id_3])];

        // Build a parameterized query based on the number of unique IDs
        const placeholders = uniqueServiceIds.map((_, index) => `$${index + 1}`).join(', ');
        const servicesQuery = `
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
                s.id IN (${placeholders}) AND s.active = true;
        `;

        // Execute the services query
        const servicesResult = await pool.query(servicesQuery, uniqueServiceIds);

        // Check if all unique services exist
        if (servicesResult.rows.length < uniqueServiceIds.length) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "One or more services not found or inactive"
            });
        }

        // Get the service details
        const service1 = servicesResult.rows.find(s => s.id === parseInt(service_id_1));
        const service2 = servicesResult.rows.find(s => s.id === parseInt(service_id_2));

        // For service3, we need to handle the case where it's the same as service1 or service2
        let service3;
        if (parseInt(service_id_3) === parseInt(service_id_1)) {
            service3 = service1;
        } else if (parseInt(service_id_3) === parseInt(service_id_2)) {
            service3 = service2;
        } else {
            service3 = servicesResult.rows.find(s => s.id === parseInt(service_id_3));
        }

        // If any service is not found, return error
        if (!service1 || !service2 || !service3) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "One or more services not found or inactive"
            });
        }

        // Calculate total durations including buffer time
        const totalDuration1 = service1.duration + (service1.buffer_time || 0);
        const totalDuration2 = service2.duration + (service2.buffer_time || 0);
        const totalDuration3 = service3.duration + (service3.buffer_time || 0);

        // Use the optimized SQL query to find available slots for all three services
        const availableSlotsQuery = `
        WITH
          -- 1) Define your three services
          service_input(ord, service_id, duration_min, staff_id_pref) AS (
            VALUES
              (1, $1::integer, $2::integer, $3::integer),
              (2, $4::integer, $5::integer, $6::integer),
              (3, $7::integer, $8::integer, $9::integer)
          ),

          -- 2) Which staff can do each of the three
          service_opts1 AS (
            SELECT ss.appuser_id AS s1_staff, si.duration_min AS duration1
            FROM service_input si
            JOIN service_staff ss ON ss.service_id = si.service_id
            WHERE si.ord = 1
              AND (si.staff_id_pref IS NULL OR ss.appuser_id = si.staff_id_pref)
          ),
          service_opts2 AS (
            SELECT ss.appuser_id AS s2_staff, si.duration_min AS duration2
            FROM service_input si
            JOIN service_staff ss ON ss.service_id = si.service_id
            WHERE si.ord = 2
              AND (si.staff_id_pref IS NULL OR ss.appuser_id = si.staff_id_pref)
          ),
          service_opts3 AS (
            SELECT ss.appuser_id AS s3_staff, si.duration_min AS duration3
            FROM service_input si
            JOIN service_staff ss ON ss.service_id = si.service_id
            WHERE si.ord = 3
              AND (si.staff_id_pref IS NULL OR ss.appuser_id = si.staff_id_pref)
          ),

          -- 3) Free‐intervals per staff
          staff_busyness AS (
            SELECT
              staff_id,
              (rota_date + start_time)::timestamp AS busy_start,
              (rota_date + end_time)::timestamp AS busy_end
            FROM staff_rota
            WHERE rota_date = $10
          ),
          staff_bookings AS (
            SELECT
              staff_id,
              (booking_date + start_time)::timestamp AS b_start,
              (booking_date + end_time)::timestamp AS b_end
            FROM booking
            WHERE booking_date = $10
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
                  SELECT busy_start AS ts FROM staff_busyness WHERE staff_id = sb.staff_id
                  UNION ALL
                  SELECT busy_end   AS ts FROM staff_busyness WHERE staff_id = sb.staff_id
                  UNION ALL
                  SELECT b_start    AS ts FROM staff_bookings WHERE staff_id = sb.staff_id
                  UNION ALL
                  SELECT b_end      AS ts FROM staff_bookings WHERE staff_id = sb.staff_id
                ) AS all_ts
              ) AS arr,
              generate_series(1, array_length(arr.pts,1)-1) AS idx
            ) AS slot ON slot.free_start < slot.free_end
          ),

          -- 4) 15-minute grid slots for Service 1
          service1_slots AS (
            SELECT
              o1.s1_staff,
              gs                   AS s1_start,
              o1.duration1
            FROM service_opts1 o1
            JOIN staff_free fs ON fs.staff_id = o1.s1_staff
            CROSS JOIN LATERAL (
              SELECT generate_series(
                date_trunc('hour', fs.free_start)
                  + CEIL(date_part('minute', fs.free_start)::numeric/15)
                    * INTERVAL '15 minute',
                fs.free_end - (o1.duration1 * INTERVAL '1 minute'),
                INTERVAL '15 minute'
              ) AS gs
            ) AS minutes
          ),
          service1_pref AS (
            SELECT * FROM service1_slots
            WHERE
              CASE
                WHEN $11 = 'morning' THEN s1_start::time < '12:00'
                WHEN $11 = 'afternoon' THEN s1_start::time >= '12:00'
                ELSE TRUE -- 'any' time preference
              END
          ),

          -- 5) Chain Service 2 onto Service 1
          chain2 AS (
            SELECT
              s1.s1_staff,
              s1.s1_start,
              ( s1.s1_start + (s1.duration1 * INTERVAL '1 minute') ) AS s1_end,
              o2.s2_staff,

              COALESCE(
                (
                  SELECT ( s1.s1_start + (s1.duration1 * INTERVAL '1 minute') )
                  FROM staff_free f2
                  WHERE f2.staff_id = o2.s2_staff
                    AND f2.free_start
                          <= ( s1.s1_start + (s1.duration1 * INTERVAL '1 minute') )
                    AND f2.free_end >= ( s1.s1_start + (s1.duration1 * INTERVAL '1 minute') )
                                    + ( o2.duration2 * INTERVAL '1 minute' )
                  LIMIT 1
                ),
                (
                  SELECT MIN(f2.free_start)
                  FROM staff_free f2
                  WHERE f2.staff_id = o2.s2_staff
                    AND (f2.free_end - f2.free_start)
                          >= ( o2.duration2 * INTERVAL '1 minute' )
                    AND f2.free_start
                          >= ( s1.s1_start + (s1.duration1 * INTERVAL '1 minute') )
                )
              ) AS s2_start,

              o2.duration2
            FROM service1_pref s1
            CROSS JOIN service_opts2 o2
          ),

          -- 6) Chain Service 3 onto that combo
          chain3 AS (
            SELECT
              c2.s1_staff,
              c2.s1_start,
              c2.s1_end,
              c2.s2_staff,
              c2.s2_start,
              ( c2.s2_start + (c2.duration2 * INTERVAL '1 minute') ) AS s2_end,
              o3.s3_staff,

              COALESCE(
                (
                  SELECT ( c2.s2_start + (c2.duration2 * INTERVAL '1 minute') )
                  FROM staff_free f3
                  WHERE f3.staff_id = o3.s3_staff
                    AND f3.free_start
                          <= ( c2.s2_start + (c2.duration2 * INTERVAL '1 minute') )
                    AND f3.free_end >= ( c2.s2_start + (c2.duration2 * INTERVAL '1 minute') )
                                   + ( o3.duration3 * INTERVAL '1 minute' )
                  LIMIT 1
                ),
                (
                  SELECT MIN(f3.free_start)
                  FROM staff_free f3
                  WHERE f3.staff_id = o3.s3_staff
                    AND ( f3.free_end - f3.free_start )
                          >= ( o3.duration3 * INTERVAL '1 minute' )
                    AND f3.free_start
                          >= ( c2.s2_start + (c2.duration2 * INTERVAL '1 minute') )
                )
              ) AS s3_start,

              o3.duration3
            FROM chain2 c2
            CROSS JOIN service_opts3 o3
          )

        -- 7) Final: sort by earliest s1_start, then tightness
        SELECT
          ROW_NUMBER() OVER (ORDER BY s1_start, span_diff) AS rank,
          s1_staff, s1_start, s1_end,
          s2_staff, s2_start, s2_end,
          s3_staff, s3_start,
          ( s3_start + (duration3 * INTERVAL '1 minute') ) AS s3_end,
          EXTRACT(
            EPOCH FROM (
              ( s3_start + (duration3 * INTERVAL '1 minute') )
              - s1_start
            )
          )/60 AS span_minutes
        FROM (
          SELECT *,
            ( ( s3_start + (duration3 * INTERVAL '1 minute') )
              - s1_start
            ) AS span_diff
          FROM chain3
        ) AS t
        ORDER BY s1_start, span_diff
        LIMIT 3;
        `;

        // Set up query parameters
        const queryParams = [
            service_id_1,                  // $1: First service ID
            totalDuration1,                // $2: First service duration (including buffer)
            staff_id_1 || null,            // $3: Preferred staff for first service (or null)
            service_id_2,                  // $4: Second service ID
            totalDuration2,                // $5: Second service duration (including buffer)
            staff_id_2 || null,            // $6: Preferred staff for second service (or null)
            service_id_3,                  // $7: Third service ID
            totalDuration3,                // $8: Third service duration (including buffer)
            staff_id_3 || null,            // $9: Preferred staff for third service (or null)
            date,                          // $10: Date to find slots for
            timeOfDay                      // $11: Time preference (morning, afternoon, any)
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
        const staffIds = [];
        availableSlotsResult.rows.forEach(row => {
            if (row.s1_staff && !staffIds.includes(row.s1_staff)) {
                staffIds.push(row.s1_staff);
            }
            if (row.s2_staff && !staffIds.includes(row.s2_staff)) {
                staffIds.push(row.s2_staff);
            }
            if (row.s3_staff && !staffIds.includes(row.s3_staff)) {
                staffIds.push(row.s3_staff);
            }
        });

        // Get staff names
        const staffInfoResult = await pool.query(staffInfoQuery, [staffIds]);

        // Create a lookup map for staff names
        const staffInfo = {};
        staffInfoResult.rows.forEach(staff => {
            staffInfo[staff.staff_id] = staff.staff_name;
        });

        // Format the results into the expected combined_slots format
        const combinedSlots = availableSlotsResult.rows.map(row => {
            // Format times to HH:MM:SS
            const formatTime = (dateTime) => {
                const date = new Date(dateTime);
                return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:00`;
            };

            return {
                service_1: {
                    start_time: formatTime(row.s1_start),
                    end_time: formatTime(row.s1_end),
                    staff_id: row.s1_staff,
                    staff_name: staffInfo[row.s1_staff] || "Unknown Staff",
                    service_id: service1.id,
                    service_name: service1.service_name
                },
                service_2: {
                    start_time: formatTime(row.s2_start),
                    end_time: formatTime(row.s2_end),
                    staff_id: row.s2_staff,
                    staff_name: staffInfo[row.s2_staff] || "Unknown Staff",
                    service_id: service2.id,
                    service_name: service2.service_name
                },
                service_3: {
                    start_time: formatTime(row.s3_start),
                    end_time: formatTime(row.s3_end),
                    staff_id: row.s3_staff,
                    staff_name: staffInfo[row.s3_staff] || "Unknown Staff",
                    service_id: service3.id,
                    service_name: service3.service_name
                },
                total_duration: Math.round(row.span_minutes),
                start_time: formatTime(row.s1_start),
                end_time: formatTime(row.s3_end)
            };
        });

        // Return success response with available slots and service details
        return res.status(200).json({
            return_code: "SUCCESS",
            time_preference: timeOfDay,
            services: [
                {
                    id: service1.id,
                    name: service1.service_name,
                    business_name: service1.business_name,
                    duration: service1.duration,
                    buffer_time: service1.buffer_time || 0,
                    total_duration: totalDuration1,
                    price: service1.price,
                    currency: service1.currency
                },
                {
                    id: service2.id,
                    name: service2.service_name,
                    business_name: service2.business_name,
                    duration: service2.duration,
                    buffer_time: service2.buffer_time || 0,
                    total_duration: totalDuration2,
                    price: service2.price,
                    currency: service2.currency
                },
                {
                    id: service3.id,
                    name: service3.service_name,
                    business_name: service3.business_name,
                    duration: service3.duration,
                    buffer_time: service3.buffer_time || 0,
                    total_duration: totalDuration3,
                    price: service3.price,
                    currency: service3.currency
                }
            ],
            combined_slots: combinedSlots
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Get service slot x3 error:", error.message);
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
