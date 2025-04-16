const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

// Test the database connection
pool.connect()
    .then(client => {
        console.log("✅ PostgreSQL Connected Successfully");
        // Test a simple query
        return client
            .query('SELECT NOW() as now')
            .then(res => {
                // console.log("✅ Database query successful:", res.rows[0]);
                client.release();
            })
            .catch(err => {
                console.error("❌ Database Query Error", err);
                client.release();
            });
    })
    .catch(err => {
        console.error("❌ Database Connection Error", err);
        console.error("Error details:", {
            message: err.message,
            code: err.code,
            detail: err.detail
        });
    });

module.exports = pool;
