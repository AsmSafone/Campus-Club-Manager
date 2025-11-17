import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notification_settings_screen.dart';

class Notification {
  final String id;
  final String title;
  final String description;
  final String type; // 'event', 'announcement', 'message', 'member'
  final String timestamp;
  final bool isRead;
  final IconData icon;

  Notification({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.icon,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    IconData iconData = Icons.notifications;
    
    switch (json['icon']) {
      case 'event':
        iconData = Icons.event;
        break;
      case 'campaign':
        iconData = Icons.campaign;
        break;
      case 'chat_bubble':
        iconData = Icons.chat_bubble;
        break;
      case 'person_add':
        iconData = Icons.person_add;
        break;
      default:
        iconData = Icons.notifications;
    }

    return Notification(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'message',
      timestamp: json['timestamp'] ?? '',
      isRead: json['isRead'] ?? false,
      icon: iconData,
    );
  }
}

class NotificationViewScreen extends StatefulWidget {
  final String? token;

  const NotificationViewScreen({Key? key, this.token}) : super(key: key);

  @override
  _NotificationViewScreenState createState() => _NotificationViewScreenState();
}

class _NotificationViewScreenState extends State<NotificationViewScreen> {
  late Future<List<Notification>> _notificationsFuture;
  final String _apiBaseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  Future<List<Notification>> _fetchNotifications() async {
    try {
      if (widget.token == null || widget.token!.isEmpty) {
        return [];
      }

      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/notifications'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((n) => Notification.fromJson(n)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF101922),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Color(0xFF999999)),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Color(0xFF137FEC)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationSettingsScreen(token: widget.token),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('All marked as read')),
                  );
                },
                child: Text(
                  'Mark All',
                  style: TextStyle(
                    color: Color(0xFF137FEC),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Notification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xFF137FEC)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _notificationsFuture = _fetchNotifications();
                      });
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildSectionTitle('TODAY'),
              SizedBox(height: 12),
              ...notifications.map((notif) => _buildNotificationItem(notif)).toList(),
              SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Color(0xFF999999),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildNotificationItem(Notification notification) {
    Color iconBackgroundColor = Color(0xFF137FEC).withOpacity(0.1);
    Color iconColor = Color(0xFF137FEC);

    if (notification.type == 'announcement') {
      iconBackgroundColor = Color(0xFF137FEC).withOpacity(0.1);
      iconColor = Color(0xFF137FEC);
    } else if (notification.type == 'message') {
      iconBackgroundColor = Color(0xFF999999).withOpacity(0.1);
      iconColor = Color(0xFF999999);
    } else if (notification.type == 'member') {
      iconBackgroundColor = Color(0xFF999999).withOpacity(0.1);
      iconColor = Color(0xFF999999);
    }

    bool isRead = notification.isRead;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Color(0xFF1C2936).withOpacity(0.5) : Color(0xFF1C2936),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              notification.icon,
              color: iconColor,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  notification.description,
                  style: TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                notification.timestamp,
                style: TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 10,
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF137FEC),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Color(0xFF137FEC).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              color: Color(0xFF137FEC),
              size: 48,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You have no new notifications right now.\nWe\'ll let you know when something new comes up.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
