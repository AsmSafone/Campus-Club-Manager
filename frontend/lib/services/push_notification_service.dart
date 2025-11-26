import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Title: ${message.notification?.title}');
  debugPrint('Body: ${message.notification?.body}');
  debugPrint('Data: ${message.data}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _deviceToken;
  String? _authToken;

  /// Initialize push notification service
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for push notifications');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
        return;
      }

      // Get FCM token
      _deviceToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_deviceToken');

      if (_deviceToken != null) {
        // Register token with backend
        await _registerTokenWithBackend(_deviceToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _deviceToken = newToken;
        _registerTokenWithBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages (when app is in background but not terminated)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a terminated state via notification
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  /// Register device token with backend
  Future<void> _registerTokenWithBackend(String token) async {
    try {
      // Get auth token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');

      if (_authToken == null || _authToken!.isEmpty) {
        debugPrint('No auth token found. Token registration will be retried after login.');
        return;
      }

      // Determine platform
      String platform = 'android';
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      } else if (kIsWeb) {
        platform = 'web';
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/push/register-token'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_token': token,
          'platform': platform,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Device token registered successfully');
      } else {
        debugPrint('Failed to register device token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error registering device token: $e');
    }
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // You can show a local notification or update UI here
    // For now, we'll just log it
  }

  /// Handle when user taps on a notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Navigate to appropriate screen based on notification data
    // This will be handled by the app's navigation system
  }

  /// Unregister device token
  Future<void> unregisterToken() async {
    try {
      if (_deviceToken == null) return;

      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');

      if (_authToken == null || _authToken!.isEmpty) {
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/push/unregister-token'),
        headers: {
          'Authorization': 'Bearer $_authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'device_token': _deviceToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Device token unregistered successfully');
        _deviceToken = null;
      }
    } catch (e) {
      debugPrint('Error unregistering device token: $e');
    }
  }

  /// Get current device token
  String? get deviceToken => _deviceToken;

  /// Update auth token (called after login)
  Future<void> updateAuthToken(String? token) async {
    _authToken = token;
    if (_deviceToken != null && _authToken != null) {
      await _registerTokenWithBackend(_deviceToken!);
    }
  }
}

