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

// Root route
app.get('/', (req, res) => {
    res.send('Welcome to Noovos API');
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Server running on port ${PORT}`);
});
