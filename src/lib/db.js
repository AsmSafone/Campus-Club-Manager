// MySQL connection helper using mysql2/promise
// Install dependency: npm install mysql2
import mysql from 'mysql2/promise'

if (!process.env.MYSQL_HOST && !process.env.MYSQL_USER && !process.env.MYSQL_PASSWORD && !process.env.MYSQL_DATABASE) {
  console.log("MYSQL environment not found in db!");
}
let connection;
try {
  connection = await mysql.createConnection({
    host: process.env.MYSQL_HOST,
    user: process.env.MYSQL_USER,
    password: process.env.MYSQL_PASSWORD,
    database: process.env.MYSQL_DATABASE,
    multipleStatements: true
  });
} catch (error) {
  console.error("Error connecting to MySQL database in db:", error.message);

  try {
    // Try to run migrations from db.sql (assumed co-located with this file)
    const fs = await import('fs/promises');
    const sqlPath = new URL('./db.sql', import.meta.url);
    const sql = await fs.readFile(sqlPath, 'utf8');

    // Connect without selecting a database to run the SQL file (allow multiple statements)
    const tmpConn = await mysql.createConnection({
      host: process.env.MYSQL_HOST,
      user: process.env.MYSQL_USER,
      password: process.env.MYSQL_PASSWORD,
      multipleStatements: true
    });

    await tmpConn.query(sql);
    await tmpConn.end();

    // Try to connect again to the intended database
    connection = await mysql.createConnection({
      host: process.env.MYSQL_HOST,
      user: process.env.MYSQL_USER,
      password: process.env.MYSQL_PASSWORD,
      database: process.env.MYSQL_DATABASE,
      multipleStatements: true
    });

    console.log("Ran db.sql migration and reconnected to MySQL.");
  } catch (migrateError) {
    // Log migration/reconnect errors but do not throw so requests are not interrupted
    console.error("Migration or reconnection failed:", migrateError.message);
  }
}

export default connection;