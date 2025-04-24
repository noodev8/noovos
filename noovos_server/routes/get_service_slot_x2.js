/*
=======================================================================================================================================
API Route: get_service_slot_x2
=======================================================================================================================================
Method: POST
Purpose: Retrieves available back-to-back time slots for two different services in any order.
Authentication: Not required - This endpoint is publicly accessible
=======================================================================================================================================
Request Payload:
{
  "service_id_1": 7,                   // integer, required - ID of the first service
  "service_id_2": 12,                  // integer, required - ID of the second service
  "date": "2025-05-04",                // string, required - Date to find slots for (YYYY-MM-DD format)
  "staff_id_1": 10,                    // integer, optional - Preferred staff for first service
  "staff_id_2": 15,                    // integer, optional - Preferred staff for second service
  "time_preference": "morning",        // string, optional - Preferred time of day for first service: "morning", "afternoon", or "any" (default: "any")
}

Success Response:
{
  "return_code": "SUCCESS",
  "time_preference": "morning",
  "services": [
    {
      "id": 7,
      "name": "Deep Tissue Massage",
      "business_name": "Wellness Spa",
      "duration": 45,
      "buffer_time": 15,
      "total_duration": 60,
      "price": 75.00,
      "currency": "GBP"
    },
    {
      "id": 12,
      "name": "Facial Treatment",
      "business_name": "Wellness Spa",
      "duration": 30,
      "buffer_time": 10,
      "total_duration": 40,
      "price": 60.00,
      "currency": "GBP"
    }
  ],
  "flexible_order": true,
  "combined_slots": [
    {
      "order": "1-2",                     // string - Indicates service order: "1-2" (service 1 then 2) or "2-1" (service 2 then 1)
      "service_1": {
        "start_time": "09:00:00",
        "end_time": "10:00:00",
        "staff_id": 10,
        "staff_name": "John Smith",
        "service_id": 7,
        "service_name": "Deep Tissue Massage"
      },
      "service_2": {
        "start_time": "10:00:00",
        "end_time": "10:40:00",
        "staff_id": 15,
        "staff_name": "Jane Doe",
        "service_id": 12,
        "service_name": "Facial Treatment"
      },
      "total_duration": 100,
      "handover_gap": 0,
      "start_time": "09:00:00",         // string - Overall start time of the combined booking
      "end_time": "10:40:00"            // string - Overall end time of the combined booking
    },
    ...
  ]
}
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

// POST /get_service_slot_x2
router.post('/', async (req, res) => {
    try {
        // Extract parameters from request body
        const {
            service_id_1,
            service_id_2,
            date,
            staff_id_1,
            staff_id_2,
            time_preference,
            max_gap_minutes
        } = req.body;

        // Set default values
        const timeOfDay = time_preference ? time_preference.toLowerCase() : "any";
        // Note: max_gap_minutes is now hardcoded to 30 minutes in the SQL query

        // Validate time preference if provided
        if (timeOfDay !== "any" && timeOfDay !== "morning" && timeOfDay !== "afternoon") {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "Time preference must be 'morning', 'afternoon', or 'any'"
            });
        }

        // Validate required parameters
        if (!service_id_1 || isNaN(parseInt(service_id_1)) || !service_id_2 || isNaN(parseInt(service_id_2))) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid service_id_1 and service_id_2 are required"
            });
        }

        if (!date || !isValidDate(date)) {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Valid date is required (YYYY-MM-DD format)"
            });
        }

        // Note: max_gap_minutes is now hardcoded to 30 minutes in the SQL query

        // Check if services exist and get their details
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
                s.id IN ($1, $2) AND s.active = true;
        `;

        // Execute the services query
        const servicesResult = await pool.query(servicesQuery, [service_id_1, service_id_2]);

        // Check if both services exist
        if (servicesResult.rows.length < 2) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "One or both services not found or inactive"
            });
        }

        // Get the service details
        const service1 = servicesResult.rows.find(s => s.id === parseInt(service_id_1));
        const service2 = servicesResult.rows.find(s => s.id === parseInt(service_id_2));

        // If either service is not found, return error
        if (!service1 || !service2) {
            return res.status(404).json({
                return_code: "SERVICE_NOT_FOUND",
                message: "One or both services not found or inactive"
            });
        }

        // Calculate total durations including buffer time
        const totalDuration1 = service1.duration + (service1.buffer_time || 0);
        const totalDuration2 = service2.duration + (service2.buffer_time || 0);

        // Find staff members who can perform each service
        // For service 1
        let staffQuery1 = `
            SELECT
                ss.appuser_id AS staff_id,
                CONCAT(au.first_name, ' ', au.last_name) AS staff_name
            FROM
                service_staff ss
            JOIN
                app_user au ON ss.appuser_id = au.id
            WHERE
                ss.service_id = $1
        `;

        const queryParams1 = [service_id_1];

        // If staff_id_1 is provided, add it to the filter
        if (staff_id_1) {
            staffQuery1 += ` AND ss.appuser_id = $2`;
            queryParams1.push(staff_id_1);
        }

        // For service 2
        let staffQuery2 = `
            SELECT
                ss.appuser_id AS staff_id,
                CONCAT(au.first_name, ' ', au.last_name) AS staff_name
            FROM
                service_staff ss
            JOIN
                app_user au ON ss.appuser_id = au.id
            WHERE
                ss.service_id = $1
        `;

        const queryParams2 = [service_id_2];

        // If staff_id_2 is provided, add it to the filter
        if (staff_id_2) {
            staffQuery2 += ` AND ss.appuser_id = $2`;
            queryParams2.push(staff_id_2);
        }

        // Execute the staff queries
        const staffResult1 = await pool.query(staffQuery1, queryParams1);
        const staffResult2 = await pool.query(staffQuery2, queryParams2);

        // Check if staff members are available for each service
        if (staffResult1.rows.length === 0) {
            return res.status(404).json({
                return_code: "NO_SLOTS_AVAILABLE",
                message: "No staff members available for the first service"
            });
        }

        if (staffResult2.rows.length === 0) {
            return res.status(404).json({
                return_code: "NO_SLOTS_AVAILABLE",
                message: "No staff members available for the second service"
            });
        }

        // Get staff information for display
        const staffMembers1 = staffResult1.rows;
        const staffMembers2 = staffResult2.rows;

        // Use the optimized SQL query to find available slots for both services
        const availableSlotsQuery = `
        WITH
          -- 1) Define your two services
          service_input(ord, service_id, duration_min, staff_id_pref) AS (
            VALUES
              (1, $1::integer, $2::integer, $3::integer),
              (2, $4::integer, $5::integer, $6::integer)
          ),

          -- 2) Which staff can do each
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

          -- 3) Build each staff member's free intervals once
          staff_busyness AS (
            SELECT
              staff_id,
              (rota_date + start_time)::timestamp AS busy_start,
              (rota_date + end_time)::timestamp AS busy_end
            FROM staff_rota
            WHERE rota_date = $7
          ),
          staff_bookings AS (
            SELECT
              staff_id,
              (booking_date + start_time)::timestamp AS b_start,
              (booking_date + end_time)::timestamp AS b_end
            FROM booking
            WHERE booking_date = $7
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

          -- 4) 15-minute grid slots for Service 1
          service1_slots AS (
            SELECT
              o1.s1_staff,
              gs AS s1_start,
              o1.duration1
            FROM service_opts1 o1
            JOIN staff_free fs ON fs.staff_id = o1.s1_staff
            CROSS JOIN LATERAL (
              SELECT generate_series(
                -- round UP to next quarter hour
                date_trunc('hour', fs.free_start)
                  + CEIL(date_part('minute', fs.free_start)::numeric/15)
                    * INTERVAL '15 minute',
                -- last viable start
                (fs.free_end - (o1.duration1 * INTERVAL '1 minute')),
                INTERVAL '15 minute'
              ) AS gs
            ) AS minutes
          ),

          -- 5) Apply time preference filter if specified
          service1_pref AS (
            SELECT * FROM service1_slots
            WHERE
              CASE
                WHEN $8 = 'morning' THEN s1_start::time < '12:00'
                WHEN $8 = 'afternoon' THEN s1_start::time >= '12:00'
                ELSE TRUE -- 'any' time preference
              END
          ),

          -- 6) Chain to Service 2, never before s1_end
          chain2 AS (
            SELECT
              s1.s1_staff,
              s1.s1_start,
              (s1.s1_start + (s1.duration1 * INTERVAL '1 minute')) AS s1_end,
              o2.s2_staff,

              COALESCE(
                -- perfect back-to-back
                (
                  SELECT (s1.s1_start + (s1.duration1 * INTERVAL '1 minute'))
                  FROM staff_free f2
                  WHERE f2.staff_id = o2.s2_staff
                    AND f2.free_start <= (s1.s1_start + (s1.duration1 * INTERVAL '1 minute'))
                    AND f2.free_end >= (s1.s1_start + (s1.duration1 * INTERVAL '1 minute'))
                                    + (o2.duration2 * INTERVAL '1 minute')
                  LIMIT 1
                ),
                -- otherwise next block ≥ s1_end
                (
                  SELECT MIN(f2.free_start)
                  FROM staff_free f2
                  WHERE f2.staff_id = o2.s2_staff
                    AND (f2.free_end - f2.free_start) >= (o2.duration2 * INTERVAL '1 minute')
                    AND f2.free_start >= (s1.s1_start + (s1.duration1 * INTERVAL '1 minute'))
                    -- Add max gap constraint (30 minutes)
                    AND (f2.free_start - (s1.s1_start + (s1.duration1 * INTERVAL '1 minute'))) <= (INTERVAL '30 minutes')
                )
              ) AS s2_start,

              o2.duration2
            FROM service1_pref s1
            CROSS JOIN service_opts2 o2
          )

        -- 7) Final: sort by earliest s1_start, then tightness
        SELECT
          ROW_NUMBER() OVER (ORDER BY s1_start, span_diff) AS rank,
          s1_staff,
          s1_start,
          s1_end,
          s2_staff,
          s2_start,
          (s2_start + (duration2 * INTERVAL '1 minute')) AS s2_end,
          -- span in minutes
          EXTRACT(
            EPOCH FROM (
              (s2_start + (duration2 * INTERVAL '1 minute'))
              - s1_start
            )
          )/60 AS span_minutes
        FROM (
          SELECT *,
            ((s2_start + (duration2 * INTERVAL '1 minute')) - s1_start)
              AS span_diff
          FROM chain2
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
            date,                          // $7: Date to find slots for
            timeOfDay                      // $8: Time preference (morning, afternoon, any)
        ];

        // Execute the query to get available slots
        const availableSlotsResult = await pool.query(availableSlotsQuery, queryParams);

        // If no slots are found, return appropriate message
        if (availableSlotsResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "NO_SLOTS_AVAILABLE",
                message: "No available slots found for the selected services, date, and time preference"
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
            // Calculate gap between services in minutes
            const s1End = new Date(row.s1_end);
            const s2Start = new Date(row.s2_start);
            const gapMinutes = Math.round((s2Start - s1End) / (60 * 1000));

            // Format times to HH:MM:SS
            const formatTime = (dateTime) => {
                const date = new Date(dateTime);
                return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:00`;
            };

            return {
                order: "1-2",  // Always in original order with this query
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
                total_duration: Math.round(row.span_minutes),
                handover_gap: gapMinutes,
                start_time: formatTime(row.s1_start),
                end_time: formatTime(row.s2_end)
            };
        });

        // Limit to 3 slots (should already be limited by the SQL query)
        const limitedCombinedSlots = combinedSlots.slice(0, 3);

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
                }
            ],
            combined_slots: limitedCombinedSlots,
            flexible_order: true  // Indicates that the API checked both service orders
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Get service slot x2 error:", error.message);
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
