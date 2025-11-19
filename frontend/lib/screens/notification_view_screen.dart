import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notification_settings_screen.dart';
import 'package:intl/intl.dart';

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
      isRead: (json['isRead'] == true || json['isRead'] == 1),
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
  List<Notification> _notifications = [];
  final String _apiBaseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _fetchNotifications();
  }

  String formatTimestamp(String timestamp) {
  try {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final aDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (aDate == today) {
      // Show only time if today
      return DateFormat('hh:mm a').format(dateTime);
    } else {
      // Show date and time if not today
      return DateFormat('MMM d, yyyy hh:mm a').format(dateTime);
    }
  } catch (e) {
    return timestamp; // fallback to raw if parsing fails
  }
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

  Future<void> _refreshNotifications() async {
    final notifications = await _fetchNotifications();
    setState(() {
      _notifications = notifications;
      _notificationsFuture = Future.value(notifications);
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((n) => Notification(
        id: n.id,
        title: n.title,
        description: n.description,
        type: n.type,
        timestamp: n.timestamp,
        isRead: true,
        icon: n.icon,
      )).toList();
      _notificationsFuture = Future.value(_notifications);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All marked as read')),
    );
  }

  void _markAsRead(String id) {
    setState(() {
      _notifications = _notifications.map((n) =>
        n.id == id ? Notification(
          id: n.id,
          title: n.title,
          description: n.description,
          type: n.type,
          timestamp: n.timestamp,
          isRead: true,
          icon: n.icon,
        ) : n
      ).toList();
      _notificationsFuture = Future.value(_notifications);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101922),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Color(0xFF999999)),
        ),
        title: const Text(
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
            icon: const Icon(Icons.settings, color: Color(0xFF137FEC)),
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
                onTap: _markAllAsRead,
                child: const Text(
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
      body: RefreshIndicator(
        color: const Color(0xFF137FEC),
        onRefresh: _refreshNotifications,
        child: FutureBuilder<List<Notification>>(
          future: _notificationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF137FEC)),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading notifications',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshNotifications,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            _notifications = snapshot.data ?? [];

            if (_notifications.isEmpty) {
              return _buildEmptyState();
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('TODAY'),
                const SizedBox(height: 12),
                ..._notifications.map((notif) => GestureDetector(
                  onTap: () => _markAsRead(notif.id),
                  child: _buildNotificationItem(notif),
                )),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
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
                formatTimestamp(notification.timestamp),
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
