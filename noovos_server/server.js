/*
=======================================================================================================================================
Noovos Server
=======================================================================================================================================
Main server file for the Noovos application
Sets up Express.js server with routes for authentication and other API endpoints
=======================================================================================================================================
*/

// Import required modules
const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
require('dotenv').config();

// Create Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Import database connection
const pool = require('./db');

// Import routes
const login_user = require('./routes/login_user');
const register_user = require('./routes/register_user');
const reset_password = require('./routes/reset_password');
const verify_email = require('./routes/verify_email');
const resend_verification = require('./routes/resend_verification');
const web_verify_email = require('./routes/web_verify_email');
const web_reset_password = require('./routes/web_reset_password');
const get_user_profile = require('./routes/get_user_profile');
const delete_user_data = require('./routes/delete_user_data');
const register_business = require('./routes/register_business');
const update_business = require('./routes/update_business');
const search_business = require('./routes/search_business');
const get_categories = require('./routes/get_categories');
//const search_category_service = require('./routes/search_category_service');
const search_service = require('./routes/search_service');
// DEPRECATED: Uses outdated 'available_slot' table which has been replaced by staff_schedule and staff_rota
// const create_booking_slot = require('./routes/create_booking_slot');
const get_service = require('./routes/get_service');
const get_service_staff = require('./routes/get_service_staff');
const get_service_slot_x1 = require('./routes/get_service_slot_x1');
const get_service_slot_x2 = require('./routes/get_service_slot_x2');
const get_service_slot_x3 = require('./routes/get_service_slot_x3');
const get_app_version = require('./routes/get_app_version');
const get_user_businesses = require('./routes/get_user_businesses');
const get_business_staff = require('./routes/get_business_staff');
const request_staff_join = require('./routes/request_staff_join');
const respond_to_staff_request = require('./routes/respond_to_staff_request');
const remove_staff = require('./routes/remove_staff');
const get_staff_invitations = require('./routes/get_staff_invitations');
const respond_to_staff_invitation = require('./routes/respond_to_staff_invitation');
const get_staff_rota = require('./routes/get_staff_rota');
const add_staff_rota = require('./routes/add_staff_rota');
const update_staff_rota = require('./routes/update_staff_rota');
const delete_staff_rota = require('./routes/delete_staff_rota');
const set_staff_schedule = require('./routes/set_staff_schedule');
// Removed check_schedule_conflict - functionality integrated into set_staff_schedule
const create_auto_staff_rota = require('./routes/create_auto_staff_rota');
const get_staff_schedule = require('./routes/get_staff_schedule');
const create_booking = require('./routes/create_booking');
const manage_staff_to_service = require('./routes/manage_staff_to_service');
const get_business_services = require('./routes/get_business_services');
const check_booking_integrity = require('./routes/check_booking_integrity');
const create_service = require('./routes/create_service');
const update_service = require('./routes/update_service');
const delete_service = require('./routes/delete_service');

// Set up routes
app.use('/login_user', login_user);
app.use('/register_user', register_user);
app.use('/reset_password', reset_password);
app.use('/verify_email', verify_email);
app.use('/resend_verification', resend_verification);
app.use('/verify-email', web_verify_email);
app.use('/reset-password', web_reset_password);
app.use('/get_user_profile', get_user_profile);
app.use('/delete_user_data', delete_user_data);
app.use('/register_business', register_business);
app.use('/update_business', update_business);
app.use('/search_business', search_business);
app.use('/get_categories', get_categories);
//app.use('/search_category_service', search_category_service);
app.use('/search_service', search_service);
// DEPRECATED: Uses outdated 'available_slot' table which has been replaced by staff_schedule and staff_rota
// app.use('/create_booking_slot', create_booking_slot);
app.use('/get_service', get_service);
app.use('/get_service_staff', get_service_staff);
app.use('/get_service_slot_x1', get_service_slot_x1);
app.use('/get_service_slot_x2', get_service_slot_x2);
app.use('/get_service_slot_x3', get_service_slot_x3);
app.use('/get_app_version', get_app_version);
app.use('/get_user_businesses', get_user_businesses);
app.use('/get_business_staff', get_business_staff);
app.use('/request_staff_join', request_staff_join);
app.use('/respond_to_staff_request', respond_to_staff_request);
app.use('/remove_staff', remove_staff);
app.use('/get_staff_invitations', get_staff_invitations);
app.use('/respond_to_staff_invitation', respond_to_staff_invitation);
app.use('/get_staff_rota', get_staff_rota);
app.use('/add_staff_rota', add_staff_rota);
app.use('/update_staff_rota', update_staff_rota);
app.use('/delete_staff_rota', delete_staff_rota);
app.use('/set_staff_schedule', set_staff_schedule);
// Removed check_schedule_conflict route - functionality integrated into set_staff_schedule
app.use('/create_auto_staff_rota', create_auto_staff_rota);
app.use('/get_staff_schedule', get_staff_schedule);
app.use('/create_booking', create_booking);
app.use('/manage_staff_to_service', manage_staff_to_service);
app.use('/get_business_services', get_business_services);
app.use('/check_booking_integrity', check_booking_integrity);
app.use('/create_service', create_service);
app.use('/update_service', update_service);
app.use('/delete_service', delete_service);

// Root route
app.get('/', (req, res) => {
    res.send('Welcome to Noovos API');
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Server running on port ${PORT}`);
});
