import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final String? token;

  const NotificationSettingsScreen({Key? key, this.token}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _clubAnnouncements = true;
  bool _newEventAnnouncements = true;
  bool _rsvpEventReminders = true;
  String _reminderTime = '2 hours before';
  bool _isLoading = true;
  // use ApiConfig.baseUrl

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      if (widget.token == null || widget.token!.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/settings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pushNotifications = data['pushNotifications'] ?? true;
          _emailNotifications = data['emailNotifications'] ?? false;
          _clubAnnouncements = data['clubAnnouncements'] ?? true;
          _newEventAnnouncements = data['newEventAnnouncements'] ?? true;
          _rsvpEventReminders = data['rsvpEventReminders'] ?? true;
          _reminderTime = data['reminderTime'] ?? '2 hours before';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      if (widget.token == null || widget.token!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No authentication token')),
        );
        return;
      }

      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'pushNotifications': _pushNotifications,
        'emailNotifications': _emailNotifications,
        'clubAnnouncements': _clubAnnouncements,
        'newEventAnnouncements': _newEventAnnouncements,
        'rsvpEventReminders': _rsvpEventReminders,
        'reminderTime': _reminderTime,
      });

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/notifications/settings'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preferences saved successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save preferences')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF192734),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 32.0),
              child: Text(
                'Notification Preferences',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General Notifications Section
                  Text(
                    'General Notifications',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildNotificationItem(
                    icon: Icons.notifications,
                    title: 'Push Notifications',
                    value: _pushNotifications,
                    onChanged: (value) => setState(() => _pushNotifications = value),
                  ),
                  SizedBox(height: 16),

                  _buildNotificationItem(
                    icon: Icons.email,
                    title: 'Email Notifications',
                    value: _emailNotifications,
                    onChanged: (value) => setState(() => _emailNotifications = value),
                  ),
                  SizedBox(height: 16),

                  _buildNotificationItem(
                    icon: Icons.info,
                    title: 'Club Announcements',
                    value: _clubAnnouncements,
                    onChanged: (value) => setState(() => _clubAnnouncements = value),
                  ),

                  SizedBox(height: 32),

                  // Event Reminders Section
                  Text(
                    'Event Reminders',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 16),

                  _buildNotificationItem(
                    icon: Icons.event,
                    title: 'New Event Announcements',
                    value: _newEventAnnouncements,
                    onChanged: (value) => setState(() => _newEventAnnouncements = value),
                  ),
                  SizedBox(height: 16),

                  _buildNotificationItem(
                    icon: Icons.calendar_today,
                    title: 'RSVP\'d Event Reminders',
                    value: _rsvpEventReminders,
                    onChanged: (value) => setState(() => _rsvpEventReminders = value),
                  ),

                  if (_rsvpEventReminders) ...[
                    SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, size: 16, color: Colors.grey[600]),
                              SizedBox(width: 8),
                              Text(
                                'Reminder Time',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          _buildRadioOption('1 day before'),
                          SizedBox(height: 8),
                          _buildRadioOption('2 hours before'),
                          SizedBox(height: 8),
                          _buildRadioOption('30 mins before'),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Color(0xFF192734),
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4A90E2),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _pushNotifications = true;
                  _emailNotifications = false;
                  _clubAnnouncements = true;
                  _newEventAnnouncements = true;
                  _rsvpEventReminders = true;
                  _reminderTime = '2 hours before';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reset to defaults')),
                );
              },
              child: Text(
                'Reset to Default',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[500], size: 24),
        SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Color(0xFF4A90E2),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String option) {
    bool isSelected = _reminderTime == option;
    return GestureDetector(
      onTap: () => setState(() => _reminderTime = option),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Color(0xFF4A90E2) : Colors.grey[700]!,
          ),
          borderRadius: BorderRadius.circular(6),
          color: isSelected ? Color(0xFF4A90E2).withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Color(0xFF4A90E2) : Colors.grey[600]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4A90E2),
                        ),
                      ),
                    )
                  : SizedBox(),
            ),
            SizedBox(width: 12),
            Text(
              option,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
