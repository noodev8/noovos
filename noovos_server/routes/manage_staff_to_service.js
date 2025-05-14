/*
=======================================================================================================================================
API Route: manage_staff_to_service
=======================================================================================================================================
Method: POST
Purpose: Add or remove staff members from a service
=======================================================================================================================================
Request Payload:
{
  "service_id": 123,              // integer, required - ID of the service
  "staff_id": 456,                // integer, required - ID of the staff member
  "action": "add"                 // string, required - either "add" or "remove"
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Staff successfully added to service"  // or "Staff successfully removed from service"
}

Error Response:
{
  "return_code": "ERROR_CODE",
  "message": "Error description"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_ACTION"
"STAFF_NOT_FOUND"
"SERVICE_NOT_FOUND"
"ALREADY_ASSIGNED"
"NOT_ASSIGNED"
"SERVER_ERROR"
=======================================================================================================================================
*/

// Import required modules
const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// Function to validate request payload
function validatePayload(req) {
    // Check if all required fields are present
    if (!req.body.service_id || !req.body.staff_id || !req.body.action) {
        return {
            isValid: false,
            return_code: "MISSING_FIELDS",
            message: "Missing required fields"
        };
    }

    // Validate action value
    if (req.body.action !== "add" && req.body.action !== "remove") {
        return {
            isValid: false,
            return_code: "INVALID_ACTION",
            message: "Action must be either 'add' or 'remove'"
        };
    }

    return { isValid: true };
}

// Function to check if staff exists
async function checkStaffExists(staffId) {
    try {
        const result = await pool.query(
            'SELECT id FROM app_user WHERE id = $1',
            [staffId]
        );
        return result.rows.length > 0;
    } catch (error) {
        console.error('Error checking staff:', error);
        throw error;
    }
}

// Function to check if service exists
async function checkServiceExists(serviceId) {
    try {
        const result = await pool.query(
            'SELECT id FROM service WHERE id = $1',
            [serviceId]
        );
        return result.rows.length > 0;
    } catch (error) {
        console.error('Error checking service:', error);
        throw error;
    }
}

// Function to check if staff is already assigned to service
async function checkStaffAssignment(staffId, serviceId) {
    try {
        const result = await pool.query(
            'SELECT * FROM service_staff WHERE appuser_id = $1 AND service_id = $2',
            [staffId, serviceId]
        );
        return result.rows.length > 0;
    } catch (error) {
        console.error('Error checking staff assignment:', error);
        throw error;
    }
}

// Function to add staff to service
async function addStaffToService(staffId, serviceId) {
    try {
        await pool.query(
            'INSERT INTO service_staff (appuser_id, service_id) VALUES ($1, $2)',
            [staffId, serviceId]
        );
        return {
            return_code: "SUCCESS",
            message: "Staff successfully added to service"
        };
    } catch (error) {
        console.error('Error adding staff to service:', error);
        throw error;
    }
}

// Function to remove staff from service
async function removeStaffFromService(staffId, serviceId) {
    try {
        await pool.query(
            'DELETE FROM service_staff WHERE appuser_id = $1 AND service_id = $2',
            [staffId, serviceId]
        );
        return {
            return_code: "SUCCESS",
            message: "Staff successfully removed from service"
        };
    } catch (error) {
        console.error('Error removing staff from service:', error);
        throw error;
    }
}

// Main route handler
router.post('/', auth, async (req, res) => {
    try {
        // Validate request payload
        const validation = validatePayload(req);
        if (!validation.isValid) {
            return res.json(validation);
        }

        const { service_id, staff_id, action } = req.body;

        // Check if staff exists
        const staffExists = await checkStaffExists(staff_id);
        if (!staffExists) {
            return res.json({
                return_code: "STAFF_NOT_FOUND",
                message: "Staff member not found"
            });
        }

        // Check if service exists
        const serviceExists = await checkServiceExists(service_id);
        if (!serviceExists) {
            return res.json({
                return_code: "SERVICE_NOT_FOUND",
                message: "Service not found"
            });
        }

        // Check current assignment status
        const isAssigned = await checkStaffAssignment(staff_id, service_id);

        // Handle add action
        if (action === "add") {
            if (isAssigned) {
                return res.json({
                    return_code: "ALREADY_ASSIGNED",
                    message: "Staff is already assigned to this service"
                });
            }
            const result = await addStaffToService(staff_id, service_id);
            return res.json(result);
        }

        // Handle remove action
        if (action === "remove") {
            if (!isAssigned) {
                return res.json({
                    return_code: "NOT_ASSIGNED",
                    message: "Staff is not assigned to this service"
                });
            }
            const result = await removeStaffFromService(staff_id, service_id);
            return res.json(result);
        }

    } catch (error) {
        console.error('Server error:', error);
        return res.json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while processing your request"
        });
    }
});

module.exports = router; 