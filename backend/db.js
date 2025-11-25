const mysql = require('mysql2/promise');
const fs = require('fs');
const path = require('path');

require('dotenv').config();

let pool;

const credentials = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
};

async function initializeDatabase() {
    // First, create a connection without specifying the database
    const initialConnection = await mysql.createConnection({
        ...credentials,
        multipleStatements: true
    });

    try {
        // Read and execute SQL file
        // const sqlPath = path.join(__dirname, 'db.sql');
        // const sqlData = fs.readFileSync(sqlPath, 'utf8');
        
        // if (!sqlData) {
        //     console.error('Error reading SQL file');
        //     return;
        // }

        // // Execute all statements at once
        // await initialConnection.query(sqlData);

        // console.log('Database initialized successfully.');
        // await initialConnection.end();

        // Now create the pool with the database specified
        pool = mysql.createPool({
            ...credentials,
            database: process.env.DB_NAME,
            waitForConnections: true,
            connectionLimit: 10,
            queueLimit: 0
        });

        // Test the connection
        const conn = await pool.getConnection();
        console.log('Database connected successfully.');
        conn.release();
    } catch (err) {
        console.error('Error initializing database:', err.message);
        throw err;
    }
}

// Initialize the database when the module loads
const initPromise = (async () => {
    try {
        await initializeDatabase();
        return pool;
    } catch (err) {
        console.error('Failed to initialize database:', err);
        process.exit(1);
    }
})();

module.exports = initPromise;