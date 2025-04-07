/*
=======================================================================================================================================
API Route: search_business
=======================================================================================================================================
Method: POST
Purpose: Searches for businesses and services based on a search term. Returns a list of salons and services.
=======================================================================================================================================
Request Payload:
{
  "search_term": "massage"         // string, required - The term to search for
}

Success Response:
{
  "return_code": "SUCCESS",
  "results": [
    {
      "service_id": 123,                    // integer, unique service ID
      "service_name": "Deep Tissue Massage", // string, name of the service
      "business_name": "Relaxation Spa",    // string, name of the business
      "service_description": "A deep...",   // string, description of the service
      "service_image": "url/to/image.jpg",  // string, URL to service image
      "business_profile": "url/to/image.jpg", // string, URL to business profile image
      "cost": 75.00,                        // numeric, price of the service
      "city": "London",                     // string, city of the business
      "postcode": "W1A 1AA"                 // string, postcode of the business
    },
    // More results...
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"NO_RESULTS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const auth = require('../middleware/auth');

// POST /search_business
router.post('/', auth, async (req, res) => {
    try {
        // Extract search term and user_id from request body
        const { search_term } = req.body;
        const user_id = req.user.id;

        // Check if search term is provided
        if (!search_term || search_term.trim() === '') {
            return res.status(400).json({
                return_code: "MISSING_FIELDS",
                message: "Search term is required"
            });
        }

        // Trim the search term to remove leading/trailing whitespace
        const trimmedSearchTerm = search_term.trim();

        // Execute the search query
        const searchQuery = `
            WITH search_input AS (
                SELECT trim($1) AS search_term
            ),
            insert_log AS (
                INSERT INTO search_log (search_term, search_user)
                SELECT search_term, $2 FROM search_input
                RETURNING search_term, search_user
            ),
            search_query AS (
                SELECT plainto_tsquery('english', search_term) AS ts_query, search_term
                FROM insert_log
            )
            SELECT 
                service.id AS service_id,  
                service.service_name::TEXT,  
                business.name::TEXT AS business_name,  
                service.description::TEXT AS service_description,  
                service.service_image::TEXT AS service_image,  
                business.profile_picture::TEXT AS business_profile,  
                service.price::NUMERIC AS cost,  
                business.city::TEXT,  
                business.postcode::TEXT,  
                ts_rank(
                    to_tsvector('english', service.service_name) || to_tsvector('english', service.description), 
                    sq.ts_query
                ) AS rank_text,
                GREATEST(
                    similarity(service.service_name, sq.search_term),   
                    similarity(service.description, sq.search_term)
                ) AS rank_fuzzy,  
                GREATEST(
                    word_similarity(service.service_name, sq.search_term), 
                    word_similarity(service.description, sq.search_term)
                ) AS rank_word_similarity  
            FROM 
                service
            JOIN 
                business ON service.business_id = business.id
            CROSS JOIN
                search_query sq
            WHERE 
                GREATEST(
                    word_similarity(service.service_name, sq.search_term), 
                    word_similarity(service.description, sq.search_term)
                ) > 0.20  
                OR to_tsvector('english', service.service_name) @@ sq.ts_query
                OR GREATEST(
                    similarity(service.service_name, sq.search_term),   
                    similarity(service.description, sq.search_term)
                ) > 0.20
            ORDER BY 
                rank_word_similarity DESC, 
                rank_text DESC, 
                rank_fuzzy DESC
            LIMIT 10;
        `;

        // Execute the query with the search term and user_id parameters
        const searchResults = await pool.query(searchQuery, [trimmedSearchTerm, user_id]);

        // Check if there are any results
        if (searchResults.rows.length === 0) {
            return res.status(200).json({
                return_code: "NO_RESULTS",
                message: "No results found for the search term",
                results: []
            });
        }

        // Process the results to simplify the response
        // Remove the ranking fields as they are not needed in the response
        const processedResults = searchResults.rows.map(row => {
            // Create a new object without the ranking fields
            const {
                rank_text,
                rank_fuzzy,
                rank_word_similarity,
                ...resultWithoutRanking
            } = row;
            
            return resultWithoutRanking;
        });

        // Return success response with search results
        return res.status(200).json({
            return_code: "SUCCESS",
            results: processedResults
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Search business error:", error);
        console.error("Error details:", {
            message: error.message,
            stack: error.stack,
            code: error.code,
            detail: error.detail
        });
        
        // Return error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred during search: " + error.message
        });
    }
});

module.exports = router;
