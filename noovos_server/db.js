const { Pool } = require('pg');
require('dotenv').config();

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
                // Log database connection details (without password)
                console.log("✅ Database connection details:", {
                    user: process.env.DB_USER,
                    host: process.env.DB_HOST,
                    database: process.env.DB_NAME,
                    port: process.env.DB_PORT
                });
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
