/*
=======================================================================================================================================
API Route: get_categories
=======================================================================================================================================
Method: POST
Purpose: Retrieves all categories from the category table. Returns a list of categories with their IDs, names, descriptions, and image URLs.
=======================================================================================================================================
Request Payload:
{}  // No payload required

Success Response:
{
  "return_code": "SUCCESS",
  "categories": [
    {
      "id": 1,                      // integer, unique category ID
      "name": "Hair",               // string, category name
      "description": "Hair services", // string, category description (may be null)
      "icon_url": "hair.jpg"       // string, icon URL for the category (may be null)
    },
    // More categories...
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"NO_CATEGORIES"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// POST /get_categories
router.post('/', async (req, res) => {
    try {
        // Define the SQL query to get all categories
        // We're selecting all fields from the category table
        // and ordering by name for a consistent response
        const categoriesQuery = `
            SELECT
                id,
                name,
                description,
                icon_url
            FROM
                category
            ORDER BY
                name ASC;
        `;

        // Execute the query to get all categories
        const categoriesResult = await pool.query(categoriesQuery);

        // Check if there are any categories in the database
        if (categoriesResult.rows.length === 0) {
            // If no categories found, return a specific response
            return res.status(200).json({
                return_code: "NO_CATEGORIES",
                message: "No categories found in the database",
                categories: []
            });
        }

        // If categories were found, return them in the response
        return res.status(200).json({
            return_code: "SUCCESS",
            categories: categoriesResult.rows
        });

    } catch (error) {
        // Log the error for debugging purposes
        console.error("Get categories error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });

        // Return a server error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while retrieving categories: " + error.message
        });
    }
});

module.exports = router;
