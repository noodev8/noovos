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

// Set up routes
app.use('/login_user', login_user);
app.use('/register_user', register_user);
app.use('/search_business', search_business);
app.use('/get_categories', get_categories);

// Root route
app.get('/', (req, res) => {
    res.send('Welcome to Noovos API');
});

// Start server
app.listen(PORT, () => {
    console.log(`✅ Server running on port ${PORT}`);
});
