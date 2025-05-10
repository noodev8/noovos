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
const search_business = require('./routes/search_business');
const get_categories = require('./routes/get_categories');
//const search_category_service = require('./routes/search_category_service');
const search_service = require('./routes/search_service');
const create_booking_slot = require('./routes/create_booking_slot');
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
const check_schedule_conflict = require('./routes/check_schedule_conflict');
const create_auto_staff_rota = require('./routes/create_auto_staff_rota');

// Set up routes
app.use('/login_user', login_user);
app.use('/register_user', register_user);
app.use('/search_business', search_business);
app.use('/get_categories', get_categories);
//app.use('/search_category_service', search_category_service);
app.use('/search_service', search_service);
app.use('/create_booking_slot', create_booking_slot);
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
app.use('/check_schedule_conflict', check_schedule_conflict);
app.use('/create_auto_staff_rota', create_auto_staff_rota);

// Root route
app.get('/', (req, res) => {
    res.send('Welcome to Noovos API');
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Server running on port ${PORT}`);
});
