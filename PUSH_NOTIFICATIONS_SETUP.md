# Push Notifications Setup Guide

This guide will help you set up push notifications for the Campus Club Manager application using Firebase Cloud Messaging (FCM).

## Prerequisites

1. A Firebase project (create one at https://console.firebase.google.com/)
2. Node.js backend with Firebase Admin SDK configured
3. Flutter app with Firebase configured

## Backend Setup

### 1. Install Dependencies

```bash
cd backend
npm install
```

This will install `firebase-admin` package.

### 2. Set Up Firebase Admin SDK

You need to get a service account key from Firebase:

1. Go to Firebase Console → Project Settings → Service Accounts
2. Click "Generate New Private Key"
3. Download the JSON file
4. Set the environment variable in your `.env` file:

```env
FIREBASE_SERVICE_ACCOUNT='{"type":"service_account","project_id":"your-project-id",...}'
```

**OR** you can store the JSON file securely and load it in your backend code.

### 3. Run Database Migration

Execute the migration script to create the `DeviceToken` table:

```sql
-- Run this SQL script in your MySQL database
SOURCE backend/migrations/add_device_tokens_table.sql;
```

Or manually run the SQL from `backend/migrations/add_device_tokens_table.sql`.

## Frontend Setup

### 1. Install Flutter Dependencies

```bash
cd frontend
flutter pub get
```

This will install `firebase_core` and `firebase_messaging` packages.

### 2. Configure Firebase for Flutter

#### Android Setup

1. Download `google-services.json` from Firebase Console
2. Place it in `frontend/android/app/`
3. Update `frontend/android/build.gradle`:

```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

4. Update `frontend/android/app/build.gradle`:

```gradle
apply plugin: 'com.google.gms.google-services'
```

#### iOS Setup

1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `frontend/ios/Runner/`
3. Update `frontend/ios/Runner/Info.plist` to include Firebase configuration

#### Web Setup

1. Add Firebase configuration to `frontend/web/index.html`
2. Include Firebase SDK scripts

### 3. Initialize Firebase in Flutter

The app is already configured to initialize Firebase in `main.dart`. Make sure you have:

1. Created a Firebase project
2. Added your app to the Firebase project (Android, iOS, Web)
3. Downloaded the configuration files as described above

## Testing Push Notifications

### 1. Test Token Registration

After logging in, the app will automatically register the device token with the backend. Check the backend logs to confirm token registration.

### 2. Send Test Notification

You can use the test endpoint to send a push notification:

```bash
POST /api/push/test
Authorization: Bearer <your-token>
Content-Type: application/json

{
  "title": "Test Notification",
  "body": "This is a test push notification"
}
```

### 3. Automatic Notifications

Push notifications are automatically sent when:
- A new event is created (to all club members)
- A new club notification/announcement is created (to all club members)

## API Endpoints

### Register Device Token
```
POST /api/push/register-token
Authorization: Bearer <token>
Content-Type: application/json

{
  "device_token": "fcm-token-here",
  "platform": "android" | "ios" | "web"
}
```

### Unregister Device Token
```
DELETE /api/push/unregister-token
Authorization: Bearer <token>
Content-Type: application/json

{
  "device_token": "fcm-token-here"
}
```

### Send Test Notification
```
POST /api/push/test
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Test Title",
  "body": "Test Body"
}
```

## Notification Settings

Users can control push notifications through the Notification Settings screen. The backend respects these preferences when sending notifications:

- `push_notifications`: Master switch for push notifications
- `club_announcements`: Whether to receive club announcements
- `new_event_announcements`: Whether to receive new event notifications

## Troubleshooting

### Backend Issues

1. **Firebase Admin not initialized**
   - Check that `FIREBASE_SERVICE_ACCOUNT` environment variable is set correctly
   - Verify the service account JSON is valid
   - Check backend logs for initialization errors

2. **Token registration fails**
   - Verify the user is authenticated (valid JWT token)
   - Check database connection
   - Ensure `DeviceToken` table exists

### Frontend Issues

1. **No FCM token received**
   - Check Firebase configuration files are in place
   - Verify Firebase project settings
   - Check app permissions (especially on iOS)

2. **Notifications not received**
   - Verify device token is registered in database
   - Check notification settings in app
   - Ensure Firebase Cloud Messaging is enabled in Firebase Console
   - For Android, check notification channels are configured

3. **Background notifications not working**
   - Ensure `firebaseMessagingBackgroundHandler` is properly set up
   - Check that the handler is a top-level function
   - Verify Firebase initialization in `main.dart`

## Security Notes

1. **Service Account Key**: Keep your Firebase service account key secure. Never commit it to version control.

2. **Token Validation**: The backend validates user authentication before registering tokens.

3. **Token Cleanup**: Invalid tokens are automatically removed from the database when sending fails.

## Next Steps

1. Set up Firebase project and download configuration files
2. Run database migration
3. Configure environment variables
4. Test push notifications using the test endpoint
5. Verify automatic notifications work when creating events/announcements

For more information, refer to:
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

