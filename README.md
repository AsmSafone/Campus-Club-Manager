# Smart Campus Club Management System

A comprehensive digital platform for managing campus clubs, members, events, and financial activities. Built with Flutter (frontend) and Node.js/Express (backend) with MySQL database.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Backend Setup](#backend-setup)
- [Frontend Setup](#frontend-setup)
- [Database Setup](#database-setup)
- [Running the Application](#running-the-application)
- [Configuration](#configuration)
- [API Endpoints](#api-endpoints)
- [Troubleshooting](#troubleshooting)

## Features

- **User Management**: 
  - Role-based authentication (Admin, Executive, Member, Guest)
  - Admin can delete users with cascading data removal
  - User profile management and settings
- **Club Management**: 
  - Create, approve, reject, and manage clubs
  - Club details with member management
  - Club search and filtering
- **Membership Management**: 
  - Join requests with approval workflow
  - Role assignment (Member, Executive)
  - Member removal capabilities
- **Event Management**: 
  - Create and manage events
  - Event registration and attendance tracking
  - Event details and notifications
- **Financial Management**: 
  - Track income and expenses
  - Generate financial reports
  - Financial overview dashboard
- **Notification System**: 
  - Broadcast messages and announcements
  - Notification settings and preferences
  - Real-time notification updates
- **Dashboard Views**: 
  - Role-specific dashboards (Admin, Executive, Member)
  - Modern dark theme UI with gradient headers
  - Statistics cards and quick actions
  - Responsive design for all screen sizes

## Prerequisites

Before you begin, ensure you have the following installed:

### Backend Prerequisites
- **Node.js** (v14 or higher) - [Download](https://nodejs.org/)
- **npm** (comes with Node.js) or **yarn**
- **MySQL** (v5.7 or higher) - [Download](https://dev.mysql.com/downloads/mysql/)
  - **OR** **XAMPP** (includes MySQL/MariaDB and phpMyAdmin) - [Download](https://www.apachefriends.org/)
- **Git** - [Download](https://git-scm.com/)

### Frontend Prerequisites
- **Flutter SDK** (v3.9.2 or higher) - [Installation Guide](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** (for Android development) or **Xcode** (for iOS development, macOS only)
- **VS Code** or **Android Studio** (recommended IDEs)

## Project Structure

```
campus-club-manager/
├── backend/                 # Node.js/Express backend
│   ├── db.js               # Database connection configuration
│   ├── campus_club_management_db.sql  # Database schema and initial data
│   ├── index.js            # Main server file
│   ├── package.json        # Backend dependencies
│   └── node_modules/       # Backend dependencies (generated)
│
├── frontend/               # Flutter frontend
│   ├── lib/
│   │   ├── config/         # API configuration
│   │   ├── screens/        # Application screens
│   │   ├── utils/          # Utility functions
│   │   └── main.dart       # Entry point
│   ├── pubspec.yaml        # Flutter dependencies
│   └── assets/             # Images and other assets
│
└── README.md               # This file
```

## Backend Setup

### 1. Navigate to Backend Directory

```bash
cd backend
```

### 2. Install Dependencies

```bash
npm install
```

This will install all required packages:
- express
- mysql2
- bcrypt
- jsonwebtoken
- cors
- dotenv
- nodemon (dev dependency)

### 3. Environment Configuration

Create a `.env` file in the `backend` directory:

```bash
# Database Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=campus_club_management_db

# JWT Secret Key (use a strong random string in production)
JWT_SECRET=your-secret-key-change-this-in-production

# Server Port (optional, defaults to 3000)
PORT=3000
```

**Important**: Replace the placeholder values with your actual MySQL credentials and generate a secure JWT secret key.

### 4. Database Setup

See [Database Setup](#database-setup) section below for detailed instructions.

## Frontend Setup

### 1. Navigate to Frontend Directory

```bash
cd frontend
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

This will install all required packages:
- http
- shared_preferences
- path_provider
- intl
- flutter_launcher_icons
- flutter_native_splash

### 3. Configure API Endpoint

Edit `frontend/lib/config/api_config.dart` to set the backend API URL:

```dart
class ApiConfig {
  static String get baseUrl {
    // For local development
    return 'http://localhost:3000';
    
    // For Android Emulator
    // return 'http://10.0.2.2:3000';
    
    // For production/remote server
    // return 'https://your-api-domain.com';
  }
}
```

**Note**: 
- Use `http://localhost:3000` for web, iOS simulator, and desktop
- Use `http://10.0.2.2:3000` for Android emulator (maps to host's localhost)
- Use your production URL for deployed backend

## Database Setup

### Using XAMPP (Recommended for Beginners)

XAMPP is a popular local development environment that includes MySQL/MariaDB, phpMyAdmin, and Apache.

#### Step 1: Install XAMPP

1. Download XAMPP from [https://www.apachefriends.org/](https://www.apachefriends.org/)
2. Install XAMPP (default installation path: `C:\xampp` on Windows, `/Applications/XAMPP` on macOS)
3. Start XAMPP Control Panel
4. Start **Apache** and **MySQL** services (click "Start" buttons)

#### Step 2: Access phpMyAdmin

1. Open your web browser
2. Navigate to: `http://localhost/phpmyadmin`
3. You should see the phpMyAdmin interface

#### Step 3: Create Database

1. In phpMyAdmin, click on **"New"** in the left sidebar
2. Enter database name: `campus_club_management_db`
3. Select collation: `utf8mb4_general_ci` (default)
4. Click **"Create"** button

#### Step 4: Import SQL File

1. Select the newly created database `campus_club_management_db` from the left sidebar
2. Click on the **"Import"** tab at the top
3. Click **"Choose File"** or **"Browse"** button
4. Navigate to your project folder and select: `backend/campus_club_management_db.sql`
5. Scroll down and click **"Go"** or **"Import"** button
6. Wait for the import to complete (you should see a success message)

#### Step 5: Verify Import

1. In the left sidebar, expand `campus_club_management_db`
2. You should see the following tables:
   - `club`
   - `clubrequest`
   - `event`
   - `finance`
   - `membership`
   - `notification`
   - `registration`
   - `user`

#### Step 6: Configure Backend .env File

Update your `backend/.env` file with XAMPP MySQL credentials:

```bash
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=          # Leave empty (XAMPP default has no password)
DB_NAME=campus_club_management_db
JWT_SECRET=your-secret-key-change-this-in-production
PORT=3000
```

**Note**: By default, XAMPP MySQL has no password for the `root` user. If you've set a password, include it in `DB_PASSWORD`.

---

### Alternative Setup Methods

#### Option A: Using MySQL Command Line

1. **Create Database:**
   ```bash
   mysql -u root -p
   CREATE DATABASE IF NOT EXISTS campus_club_management_db;
   EXIT;
   ```

2. **Import SQL File:**
   ```bash
   mysql -u root -p campus_club_management_db < backend/campus_club_management_db.sql
   ```

#### Option B: Using MySQL Workbench

1. Open MySQL Workbench
2. Connect to your MySQL server
3. Create a new schema named `campus_club_management_db`
4. Right-click on the schema → **"Table Data Import Wizard"**
5. Select `backend/campus_club_management_db.sql`
6. Follow the import wizard

#### Option C: Manual Execution via phpMyAdmin

1. Open phpMyAdmin (`http://localhost/phpmyadmin`)
2. Select `campus_club_management_db` database
3. Click on **"SQL"** tab
4. Open `backend/campus_club_management_db.sql` in a text editor
5. Copy all SQL content
6. Paste into the SQL text area
7. Click **"Go"** to execute

### 3. Verify Database Setup

The database should contain the following tables:
- `User`
- `Club`
- `Membership`
- `Event`
- `Registration`
- `Finance`
- `Notification`
- `ClubRequest`

### 4. Default Test Accounts

The database includes default test accounts (password: `asdfasdf` for all):

- **Admin**: `admin@gmail.com`
- **Executive**: `executive@gmail.com`
- **Member**: `member@gmail.com`

**Note**: In production, change these default passwords immediately.

## Running the Application

### Backend Server

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Start the server:**
   
   For development (with auto-reload):
   ```bash
   npm run dev
   ```
   
   For production:
   ```bash
   npm start
   ```

3. **Verify server is running:**
   - You should see: `Server is running on port http://localhost:3000`
   - You should see: `Database connected successfully.`

### Frontend Application

1. **Navigate to frontend directory:**
   ```bash
   cd frontend
   ```

2. **Run the Flutter app:**
   
   **For Web:**
   ```bash
   flutter run -d chrome
   ```
   
   **For Android:**
   ```bash
   flutter run -d android
   ```
   
   **For iOS (macOS only):**
   ```bash
   flutter run -d ios
   ```
   
   **For Desktop:**
   ```bash
   flutter run -d windows    # Windows
   flutter run -d macos       # macOS
   flutter run -d linux       # Linux
   ```

3. **List available devices:**
   ```bash
   flutter devices
   ```

## Configuration

### Backend Configuration

The backend uses environment variables from `.env` file:

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | MySQL server host | `localhost` |
| `DB_USER` | MySQL username | `root` |
| `DB_PASSWORD` | MySQL password | (empty) |
| `DB_NAME` | Database name | (required) |
| `JWT_SECRET` | Secret key for JWT tokens | `your-secret-key` |
| `PORT` | Server port | `3000` |

### Frontend Configuration

The frontend API endpoint is configured in `lib/config/api_config.dart`. Update the `baseUrl` based on your deployment:

- **Local Development**: `http://localhost:3000`
- **Android Emulator**: `http://10.0.2.2:3000`
- **Production**: Your production API URL

## API Endpoints

### Authentication
- `POST /api/auth/signup` - User registration
- `POST /api/auth/signin` - User login

### Clubs
- `GET /api/clubs/list` - Get all clubs
- `GET /api/clubs/:clubId` - Get club details
- `POST /api/admin/clubs/create` - Create club (Admin only)
- `PATCH /api/clubs/:clubId/approve` - Approve club (Admin only)
- `PATCH /api/clubs/:clubId/reject` - Reject club (Admin only)
- `DELETE /api/clubs/:clubId` - Delete club (Admin only)

### Membership
- `GET /api/clubs/:clubId/members` - Get club members
- `POST /api/clubs/:clubId/members` - Add member
- `PUT /api/clubs/:clubId/members/:membershipId` - Update member role
- `DELETE /api/clubs/:clubId/members/:membershipId` - Remove member
- `POST /api/clubs/:clubId/join` - Request to join club
- `GET /api/clubs/:clubId/requests` - Get join requests (Executive only)
- `POST /api/clubs/:clubId/requests/:requestId/accept` - Accept request
- `POST /api/clubs/:clubId/requests/:requestId/reject` - Reject request

### Events
- `GET /api/clubs/:clubId/events` - Get club events
- `POST /api/clubs/:clubId/events` - Create event (Executive only)
- `DELETE /api/clubs/:clubId/events/:eventId` - Delete event (Executive only)
- `POST /api/clubs/:clubId/events/:eventId/register` - Register for event
- `GET /api/users/me/events` - Get user's events

### Finance
- `GET /api/clubs/:clubId/finance` - Get financial records
- `POST /api/clubs/:clubId/finance` - Add financial record (Executive only)

### Notifications
- `GET /api/notifications` - Get user notifications
- `POST /api/clubs/:clubId/notifications` - Create notification (Executive only)
- `GET /api/notifications/settings` - Get notification settings
- `PUT /api/notifications/settings` - Update notification settings

### Admin
- `GET /api/admin/stats` - Get system statistics
- `GET /api/users/list` - Get all users
- `DELETE /api/admin/users/:userId` - Delete user (Admin only, cascading delete)
  - **Note**: Deleting a user will automatically remove:
    - User's memberships
    - User's club requests
    - User's event registrations
    - User's notification settings
    - User's notifications
    - The user account itself
  - Admins cannot delete their own account

**Note**: Most endpoints require authentication via JWT token in the Authorization header: `Bearer <token>`

## Troubleshooting

### Backend Issues

**Problem: Database connection failed**
- **For XAMPP users:**
  - Verify MySQL is running in XAMPP Control Panel (green status)
  - Check `.env` file: `DB_PASSWORD` should be empty (unless you set a password)
  - Access phpMyAdmin at `http://localhost/phpmyadmin` to verify database exists
  - Default XAMPP MySQL port is 3306 (should work with `localhost`)
- **For standalone MySQL:**
  - Verify MySQL is running: `mysql -u root -p`
  - Check `.env` file has correct credentials
  - Ensure database exists: `SHOW DATABASES;`
  - Verify database name matches `DB_NAME` in `.env`

**Problem: Port already in use**
- Change `PORT` in `.env` file
- Or kill the process using port 3000:
  ```bash
  # Windows
  netstat -ano | findstr :3000
  taskkill /PID <PID> /F
  
  # macOS/Linux
  lsof -ti:3000 | xargs kill
  ```

**Problem: Module not found errors**
- Delete `node_modules` and `package-lock.json`
- Run `npm install` again

### Frontend Issues

**Problem: Cannot connect to backend API**
- Verify backend server is running
- Check API URL in `api_config.dart`
- For Android emulator, use `http://10.0.2.2:3000`
- Check firewall/antivirus settings

**Problem: Flutter dependencies issues**
- Run `flutter clean`
- Run `flutter pub get`
- Run `flutter pub upgrade`

**Problem: Build errors**
- Ensure Flutter SDK is up to date: `flutter upgrade`
- Check Dart SDK version matches `pubspec.yaml` requirements
- Run `flutter doctor` to check for issues

**Problem: Web build fails with "Couldn't resolve the package 'frontend'"**
- This is a build cache issue. Clean and rebuild:
  ```bash
  flutter clean
  flutter pub get
  flutter build web
  ```
- If the issue persists, delete the `.dart_tool` folder and rebuild:
  ```bash
  # Windows
  rmdir /s /q .dart_tool
  # macOS/Linux
  rm -rf .dart_tool
  
  flutter pub get
  flutter build web
  ```
- For web builds, you can also try:
  ```bash
  flutter build web --no-wasm-dry-run
  ```

**Problem: Android/iOS build fails**
- For Android: Ensure Android SDK is installed and configured
- For iOS: Ensure Xcode is installed (macOS only)
- Run `flutter doctor` for detailed diagnostics

### Database Issues

**Problem: Tables not created**
- **For XAMPP users:**
  - Verify import was successful in phpMyAdmin (check for success message)
  - Refresh phpMyAdmin and check if tables appear in left sidebar
  - If import failed, check for error messages in phpMyAdmin
  - Try importing again or use SQL tab to execute manually
- **For all users:**
  - Verify SQL script executed successfully
  - Check MySQL user has CREATE privileges
  - Manually verify tables exist: `SHOW TABLES;` or check in phpMyAdmin

**Problem: Foreign key constraint errors**
- Ensure all tables are created in correct order
- Check `campus_club_management_db.sql` for proper table creation sequence
- In phpMyAdmin, make sure you're importing the complete SQL file

**Problem: XAMPP MySQL won't start**
- Check if port 3306 is already in use by another MySQL instance
- Stop any other MySQL services running on your system
- In XAMPP Control Panel, check the error log for specific issues
- Try restarting XAMPP Control Panel as Administrator (Windows)
- On Windows, ensure no other service is using port 3306:
  ```bash
  netstat -ano | findstr :3306
  ```

**Problem: phpMyAdmin access denied or can't connect**
- Ensure Apache is running in XAMPP Control Panel
- Try accessing `http://127.0.0.1/phpmyadmin` instead of `localhost`
- Clear browser cache and cookies
- Check XAMPP error logs in `xampp/apache/logs/error.log`

## Recent Updates

### UI/UX Improvements
- **Modern Dark Theme**: Consistent dark theme across all screens with gradient headers
- **Enhanced Dashboards**: 
  - Statistics cards with icons and color coding
  - Quick action buttons
  - Improved navigation and layout
- **Better User Experience**:
  - Confirmation dialogs for destructive actions
  - Loading states and error handling
  - Responsive design for mobile and desktop
  - Smooth animations and transitions

### New Features
- **User Deletion**: Admins can delete users with automatic cascading deletion of related data
- **Announcement System**: Most recent announcements displayed prominently
- **Enhanced Search**: Improved search functionality across clubs and users
- **Status Indicators**: Visual status badges for users and clubs

## Development Tips

1. **Hot Reload**: Flutter supports hot reload. Press `r` in the terminal while the app is running to reload changes.

2. **Backend Auto-reload**: Use `npm run dev` for automatic server restart on file changes.

3. **Database Management**: Use MySQL Workbench or phpMyAdmin for easier database management.

4. **API Testing**: Use Postman or Insomnia to test API endpoints before integrating with frontend.

5. **Logs**: Check console logs for both backend and frontend to debug issues.

6. **UI Theme**: The app uses a consistent dark theme. Customize colors in individual screen files or create a centralized theme file.

## Production Deployment

### Backend
- Use environment variables for all sensitive data
- Set a strong `JWT_SECRET`
- Use a production-grade MySQL server
- Enable HTTPS
- Set up proper CORS policies
- Use process managers like PM2

### Frontend
- Update API URL to production endpoint
- Build release version:
  ```bash
  # Clean build cache first
  flutter clean
  flutter pub get
  
  # Build for different platforms
  flutter build web
  flutter build apk --release
  flutter build ios --release
  ```
- **Note**: If you encounter package resolution errors during web build, use:
  ```bash
  flutter build web --no-wasm-dry-run
  ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For issues and questions:
- Check the [Troubleshooting](#troubleshooting) section
- Review the codebase documentation
- Open an issue on the repository

---

**Happy Coding! 🚀**

