/*
=======================================================================================================================================
API Route: get_service_slot_x2
=======================================================================================================================================
Method: POST
Purpose: Retrieves available back-to-back time slots for two different services.
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
  "max_gap_minutes": 30                // integer, optional - Maximum gap between services in minutes (default: 30)
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
  "combined_slots": [
    {
      "service_1": {
        "start_time": "09:00:00",
        "end_time": "10:00:00",
        "staff_id": 10,
        "staff_name": "John Smith"
      },
      "service_2": {
        "start_time": "10:00:00",
        "end_time": "10:40:00",
        "staff_id": 15,
        "staff_name": "Jane Doe"
      },
      "total_duration": 100,
      "handover_gap": 0
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
        const maxGapMinutes = max_gap_minutes !== undefined ? max_gap_minutes : 30;

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

        // Validate max_gap_minutes if provided
        if (maxGapMinutes < 0 || maxGapMinutes > 120) {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "max_gap_minutes must be between 0 and 120"
            });
        }

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

        // Get the list of staff IDs for each service
        const staffMembers1 = staffResult1.rows;
        const staffMembers2 = staffResult2.rows;
        const staffIds1 = staffMembers1.map(staff => staff.staff_id);
        const staffIds2 = staffMembers2.map(staff => staff.staff_id);

        // Get all unique staff IDs
        const allStaffIds = [...new Set([...staffIds1, ...staffIds2])];

        // Check which staff members are working on the requested date
        const rotaQuery = `
            SELECT 
                sr.staff_id,
                sr.start_time,
                sr.end_time
            FROM 
                staff_rota sr
            WHERE 
                sr.staff_id = ANY($1)
                AND sr.rota_date = $2
        `;

        // Execute the rota query
        const rotaResult = await pool.query(rotaQuery, [allStaffIds, date]);

        // If no staff members are working on the requested date, return error
        if (rotaResult.rows.length === 0) {
            return res.status(404).json({
                return_code: "NO_SLOTS_AVAILABLE",
                message: "No staff members are working on the requested date"
            });
        }

        // Get the working hours for each staff member
        const staffWorkingHours = rotaResult.rows;

        // Check existing bookings for these staff members on the requested date
        const bookingsQuery = `
            SELECT 
                b.staff_id,
                b.start_time,
                b.end_time
            FROM 
                booking b
            WHERE 
                b.staff_id = ANY($1)
                AND b.booking_date = $2
                AND b.status != 'cancelled'
        `;

        // Execute the bookings query
        const bookingsResult = await pool.query(bookingsQuery, [allStaffIds, date]);

        // Get the existing bookings
        const existingBookings = bookingsResult.rows;

        // Calculate available slots for each staff member for service 1
        const availableSlots1 = [];

        // Process each staff member's working hours for service 1
        for (const staffId of staffIds1) {
            const staffWorkingHoursForStaff = staffWorkingHours.filter(wh => wh.staff_id === staffId);
            const staffName = staffMembers1.find(s => s.staff_id === staffId).staff_name;
            
            for (const workingHour of staffWorkingHoursForStaff) {
                // Get the start and end times of the working hours
                const startTime = workingHour.start_time;
                const endTime = workingHour.end_time;
                
                // Get the bookings for this staff member
                const staffBookings = existingBookings.filter(b => b.staff_id === staffId);
                
                // Calculate available time slots
                const slots = calculateAvailableSlots(
                    startTime, 
                    endTime, 
                    staffBookings, 
                    totalDuration1
                );
                
                // Add staff information to each slot
                slots.forEach(slot => {
                    availableSlots1.push({
                        start_time: slot.start_time,
                        end_time: slot.end_time,
                        staff_id: staffId,
                        staff_name: staffName
                    });
                });
            }
        }

        // Filter slots for service 1 based on time preference
        let filteredSlots1 = availableSlots1;
        
        if (timeOfDay === "morning") {
            // Morning: slots starting before 12:00
            filteredSlots1 = availableSlots1.filter(slot => {
                const hour = parseInt(slot.start_time.split(':')[0]);
                return hour < 12;
            });
        } else if (timeOfDay === "afternoon") {
            // Afternoon: slots starting at or after 12:00
            filteredSlots1 = availableSlots1.filter(slot => {
                const hour = parseInt(slot.start_time.split(':')[0]);
                return hour >= 12;
            });
        }
        
        // Sort slots for service 1 by start time
        filteredSlots1.sort((a, b) => {
            return a.start_time.localeCompare(b.start_time);
        });

        // If no slots are available for service 1, return error
        if (filteredSlots1.length === 0) {
            let message = "No available slots found for the first service on the requested date";
            
            if (timeOfDay === "morning") {
                message = "No morning slots available for the first service on the requested date";
            } else if (timeOfDay === "afternoon") {
                message = "No afternoon slots available for the first service on the requested date";
            }
            
            return res.status(404).json({
                return_code: "NO_SLOTS_AVAILABLE",
                message: message
            });
        }

        // Calculate available slots for each staff member for service 2
        const availableSlots2 = [];

        // Process each staff member's working hours for service 2
        for (const staffId of staffIds2) {
            const staffWorkingHoursForStaff = staffWorkingHours.filter(wh => wh.staff_id === staffId);
            const staffName = staffMembers2.find(s => s.staff_id === staffId).staff_name;
            
            for (const workingHour of staffWorkingHoursForStaff) {
                // Get the start and end times of the working hours
                const startTime = workingHour.start_time;
                const endTime = workingHour.end_time;
                
                // Get the bookings for this staff member
                const staffBookings = existingBookings.filter(b => b.staff_id === staffId);
                
                // Calculate available time slots
                const slots = calculateAvailableSlots(
                    startTime, 
                    endTime, 
                    staffBookings, 
                    totalDuration2
                );
                
                // Add staff information to each slot
                slots.forEach(slot => {
                    availableSlots2.push({
                        start_time: slot.start_time,
                        end_time: slot.end_time,
                        staff_id: staffId,
                        staff_name: staffName
                    });
                });
            }
        }

        // Sort slots for service 2 by start time
        availableSlots2.sort((a, b) => {
            return a.start_time.localeCompare(b.start_time);
        });

        // If no slots are available for service 2, return error
        if (availableSlots2.length === 0) {
            return res.status(404).json({
                return_code: "NO_SLOTS_AVAILABLE",
                message: "No available slots found for the second service on the requested date"
            });
        }

        // Find combinations of slots that can be booked back-to-back
        const combinedSlots = [];

        // Check each slot for service 1
        for (const slot1 of filteredSlots1) {
            const slot1EndMinutes = timeToMinutes(slot1.end_time);
            
            // Check each slot for service 2
            for (const slot2 of availableSlots2) {
                const slot2StartMinutes = timeToMinutes(slot2.start_time);
                
                // Calculate the gap between the end of service 1 and start of service 2
                const gapMinutes = slot2StartMinutes - slot1EndMinutes;
                
                // Check if the gap is within the allowed range (0 to maxGapMinutes)
                if (gapMinutes >= 0 && gapMinutes <= maxGapMinutes) {
                    // Calculate total duration including both services and the gap
                    const totalDuration = totalDuration1 + totalDuration2 + gapMinutes;
                    
                    // Add to combined slots
                    combinedSlots.push({
                        service_1: {
                            start_time: slot1.start_time,
                            end_time: slot1.end_time,
                            staff_id: slot1.staff_id,
                            staff_name: slot1.staff_name
                        },
                        service_2: {
                            start_time: slot2.start_time,
                            end_time: slot2.end_time,
                            staff_id: slot2.staff_id,
                            staff_name: slot2.staff_name
                        },
                        total_duration: totalDuration,
                        handover_gap: gapMinutes
                    });
                }
            }
        }

        // Sort combined slots by start time of service 1
        combinedSlots.sort((a, b) => {
            return a.service_1.start_time.localeCompare(b.service_1.start_time);
        });

        // Return only the first 3 combined slots
        const limitedCombinedSlots = combinedSlots.slice(0, 3);

        // If no combined slots are available, return error
        if (limitedCombinedSlots.length === 0) {
            return res.status(404).json({
                return_code: "NO_SLOTS_AVAILABLE",
                message: "No back-to-back slots available for the requested services"
            });
        }

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
            combined_slots: limitedCombinedSlots
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
 * Calculate available time slots based on working hours and existing bookings
 * 
 * @param {string} startTime - Start time of working hours (HH:MM:SS)
 * @param {string} endTime - End time of working hours (HH:MM:SS)
 * @param {Array} bookings - Array of existing bookings with start_time and end_time
 * @param {number} duration - Total duration of the service in minutes (including buffer time)
 * @returns {Array} - Array of available time slots with start_time and end_time
 */
function calculateAvailableSlots(startTime, endTime, bookings, duration) {
    // Convert times to minutes for easier calculation
    const startMinutes = timeToMinutes(startTime);
    const endMinutes = timeToMinutes(endTime);
    
    // Convert bookings to minutes
    const bookingRanges = bookings.map(booking => ({
        start: timeToMinutes(booking.start_time),
        end: timeToMinutes(booking.end_time)
    }));
    
    // Sort bookings by start time
    bookingRanges.sort((a, b) => a.start - b.start);
    
    // Find available time ranges
    const availableRanges = [];
    let currentStart = startMinutes;
    
    // Process each booking to find gaps
    for (const booking of bookingRanges) {
        // If there's a gap before this booking, add it to available ranges
        if (booking.start - currentStart >= duration) {
            availableRanges.push({
                start: currentStart,
                end: booking.start
            });
        }
        
        // Move current start to the end of this booking
        currentStart = booking.end;
    }
    
    // Check if there's available time after the last booking
    if (endMinutes - currentStart >= duration) {
        availableRanges.push({
            start: currentStart,
            end: endMinutes
        });
    }
    
    // Convert available ranges to slots based on service duration
    const slots = [];
    
    // Use a standard interval for slot start times (e.g., every 15 or 30 minutes)
    // This makes the schedule more predictable and user-friendly
    const slotInterval = 15; // 15-minute intervals for slot start times
    
    for (const range of availableRanges) {
        const rangeStart = range.start;
        const rangeEnd = range.end;
        
        // Round the start time to the nearest slot interval
        // This ensures slots start at predictable times (e.g., 9:00, 9:15, 9:30)
        let slotStart = Math.ceil(rangeStart / slotInterval) * slotInterval;
        
        // Create slots that fit within this range
        while (slotStart + duration <= rangeEnd) {
            // Calculate the exact end time based on the service duration
            const slotEnd = slotStart + duration;
            
            slots.push({
                start_time: minutesToTime(slotStart),
                end_time: minutesToTime(slotEnd)
            });
            
            // Move to the next potential slot start time
            slotStart += slotInterval;
        }
    }
    
    return slots;
}

/**
 * Convert time string (HH:MM:SS) to minutes
 * 
 * @param {string} timeStr - Time string in HH:MM:SS format
 * @returns {number} - Time in minutes
 */
function timeToMinutes(timeStr) {
    const [hours, minutes, seconds] = timeStr.split(':').map(Number);
    return hours * 60 + minutes;
}

/**
 * Convert minutes to time string (HH:MM:SS)
 * 
 * @param {number} minutes - Time in minutes
 * @returns {string} - Time string in HH:MM:SS format
 */
function minutesToTime(minutes) {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}:00`;
}

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
