// MySQL connection helper using mysql2/promise
// Install dependency: npm install mysql2
import mysql from 'mysql2/promise'

export default await mysql.createConnection({
  host: process.env.MYSQL_HOST,
  user: process.env.MYSQL_USER,
  password: process.env.MYSQL_PASSWORD,
  database: process.env.MYSQL_DATABASE
});
