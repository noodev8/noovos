const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
});

// Set timezone to UK time for all connections
pool.on('connect', (client) => {
    client.query('SET timezone = "Europe/London";');
});

// Test the database connection
pool.connect()
    .then(client => {
        console.log("✅ PostgreSQL Connected Successfully");
        // Test a simple query and show the timezone
        return client
            .query('SELECT NOW() as now, current_setting(\'TIMEZONE\') as timezone')
            .then(res => {
                console.log(`✅ Database time: ${res.rows[0].now}, Timezone: ${res.rows[0].timezone}`);
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
