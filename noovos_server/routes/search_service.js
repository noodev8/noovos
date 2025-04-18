/*
=======================================================================================================================================
API Route: search_service
=======================================================================================================================================
Method: POST
Purpose: Searches for services based on search term, location, and/or category. Returns a list of services with pagination.
=======================================================================================================================================
Request Payload:
{
  "search_term": "massage",         // string, optional - The term to search for
  "location": "manchester",         // string, optional - The location to filter by (city or postcode)
  "category_id": 4,                 // integer, optional - The category ID to filter by
  "page": 1,                        // integer, optional - The page number (default: 1)
  "limit": 20                       // integer, optional - The number of results per page (default: 20)
}

Success Response:
{
  "return_code": "SUCCESS",
  "total_results": 42,              // integer - Total number of results matching the search criteria
  "page": 1,                        // integer - Current page number
  "limit": 20,                      // integer - Number of results per page
  "total_pages": 3,                 // integer - Total number of pages
  "services": [
    {
      "service_id": 123,                    // integer - Unique service ID
      "service_name": "Deep Tissue Massage", // string - Name of the service
      "business_id": 456,                    // integer - ID of the business
      "business_name": "Relaxation Spa",    // string - Name of the business
      "service_description": "A deep...",   // string - Description of the service
      "service_image": "image_name.jpg",  // string - Image name from the media table (service image or business image)
      "cost": 75.00,                        // number - Price of the service
      "city": "Manchester",                 // string - City of the business
      "postcode": "M1 1AA",                 // string - Postcode of the business
      "category_name": "Massage"            // string - Name of the category
    },
    // More services...
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"INVALID_PARAMETERS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /search_service
router.post('/', async (req, res) => {
    try {
        // Extract parameters from request body
        const {
            search_term,
            location,
            category_id,
            page = 1,
            limit = 20
        } = req.body;

        // Validate page and limit parameters
        if (page < 1 || limit < 1 || limit > 100) {
            return res.status(400).json({
                return_code: "INVALID_PARAMETERS",
                message: "Invalid pagination parameters. Page must be >= 1 and limit must be between 1 and 100."
            });
        }

        // Calculate offset for pagination
        const offset = (page - 1) * limit;

        // Build the SQL query with pagination
        const searchQuery = `
            -- Parameters
            WITH params AS (
                SELECT
                    $1::TEXT AS search_term,      -- User search term (or NULL)
                    $2::TEXT AS location_input,   -- Location (or NULL)
                    $3::INT AS category_input,    -- Category ID (or NULL)
                    $4::INT AS page_input         -- Pagination: page number
            ),

            -- Dynamic threshold setup
            dynamic_threshold AS (
                SELECT
                    p.*,
                    -- If category or location is provided, tighten threshold
                    CASE
                        WHEN p.category_input IS NOT NULL OR p.location_input IS NOT NULL THEN 0.20
                        WHEN p.search_term IS NULL THEN 0.0 -- If no search term, skip similarity filter
                        ELSE 0.10
                    END AS similarity_threshold,
                    ((p.page_input - 1) * $5) AS offset_calc
                FROM params p
            ),

            -- Prepare search query
            search_query AS (
                SELECT
                    plainto_tsquery('english', dt.search_term) AS ts_query,
                    dt.search_term,
                    dt.location_input,
                    dt.category_input,
                    dt.similarity_threshold,
                    dt.offset_calc
                FROM dynamic_threshold dt
            ),

            -- Main search results
            search_results AS (
                -- Final result
                SELECT
                    s.id AS service_id,
                    s.service_name,
                    b.id AS business_id,
                    b.name AS business_name,
                    s.description AS service_description,
                    -- Get service image if available, otherwise try business image
                    COALESCE(
                        (SELECT m.image_name FROM public.media m
                         WHERE m.service_id = s.id AND m.position = 1 AND m.is_active = TRUE
                         ORDER BY m.id LIMIT 1),
                        (SELECT m.image_name FROM public.media m
                         WHERE m.business_id = b.id AND m.position = 1 AND m.is_active = TRUE
                         ORDER BY m.id LIMIT 1)
                    ) AS service_image,
                    s.price AS cost,
                    b.city,
                    b.postcode,
                    c.name AS category_name,

                    -- Rankings for ordering
                    ts_rank(
                        to_tsvector('english', s.service_name) || to_tsvector('english', s.description),
                        sq.ts_query
                    ) AS rank_text,

                    GREATEST(
                        similarity(s.service_name, sq.search_term),
                        similarity(s.description, sq.search_term),
                        similarity(b.name, sq.search_term)
                    ) AS rank_fuzzy,

                    GREATEST(
                        word_similarity(s.service_name, sq.search_term),
                        word_similarity(s.description, sq.search_term),
                        word_similarity(b.name, sq.search_term)
                    ) AS rank_word_similarity,

                    -- Location match indicators for sorting
                    CASE WHEN b.city ILIKE '%' || sq.location_input || '%' THEN 1 ELSE 0 END AS city_match,
                    CASE WHEN b.postcode ILIKE '%' || sq.location_input || '%' THEN 1 ELSE 0 END AS postcode_match

                FROM service s
                JOIN business b ON s.business_id = b.id
                LEFT JOIN category c ON s.category_id = c.id
                CROSS JOIN search_query sq

                WHERE s.active = TRUE

                -- If search term is provided, apply similarity and text search
                AND (
                    sq.search_term IS NULL
                    OR (
                        GREATEST(
                            word_similarity(s.service_name, sq.search_term),
                            word_similarity(s.description, sq.search_term),
                            word_similarity(b.name, sq.search_term)
                        ) > sq.similarity_threshold
                        OR to_tsvector('english', s.service_name) @@ sq.ts_query
                        OR to_tsvector('english', s.description) @@ sq.ts_query
                        OR to_tsvector('english', b.name) @@ sq.ts_query
                    )
                )

                -- Location filter (optional)
                AND (
                    sq.location_input IS NULL
                    OR b.city ILIKE '%' || sq.location_input || '%'
                    OR b.postcode ILIKE '%' || sq.location_input || '%'
                )

                -- Category filter (optional)
                AND (
                    sq.category_input IS NULL
                    OR s.category_id = sq.category_input
                )
            )

            -- Get total count for pagination info
            SELECT
                (SELECT COUNT(*) FROM search_results) AS total_count,
                sr.*
            FROM search_results sr
            ORDER BY
                -- Priority boost for location matches
                sr.city_match DESC,
                sr.postcode_match DESC,
                -- Then ranking relevance
                sr.rank_word_similarity DESC,
                sr.rank_text DESC,
                sr.rank_fuzzy DESC
            LIMIT $5 OFFSET (SELECT offset_calc FROM search_query);
        `;

        // Set up query parameters
        const queryParams = [
            search_term || null,
            location || null,
            category_id || null,
            page,
            limit
        ];

        // Execute the query
        const result = await pool.query(searchQuery, queryParams);

        // Extract the total count from the first row
        const totalResults = result.rows.length > 0 ? parseInt(result.rows[0].total_count) : 0;

        // Calculate total pages
        const totalPages = Math.ceil(totalResults / limit);

        // Process the results to simplify the response
        const services = result.rows.map(row => {
            // Create a new object without the ranking and sorting fields
            const {
                total_count,
                rank_text,
                rank_fuzzy,
                rank_word_similarity,
                city_match,
                postcode_match,
                ...serviceData
            } = row;

            return serviceData;
        });

        // Return success response with pagination info
        return res.status(200).json({
            return_code: "SUCCESS",
            total_results: totalResults,
            page: page,
            limit: limit,
            total_pages: totalPages,
            services: services
        });

    } catch (error) {
        // Log the error for debugging
        console.error("Search service error:", error.message);

        // Return error response
        return res.status(500).json({
            return_code: "SERVER_ERROR",
            message: "An error occurred while searching for services: " + error.message
        });
    }
});

module.exports = router;
