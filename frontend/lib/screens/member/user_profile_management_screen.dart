import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class UserProfileManagementScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;

  const UserProfileManagementScreen({Key? key, this.token, this.user}) : super(key: key);

  @override
  _UserProfileManagementScreenState createState() => _UserProfileManagementScreenState();
}

class _UserProfileManagementScreenState extends State<UserProfileManagementScreen> {
  
  bool _emailNotifications = false;
  bool _pushNotifications = false;
  bool _loading = false;
  String _displayName = 'Member';
  String _email = '';
  int? _userId;
  int? _clubId;
  String _roleLabel = '';
  // Use central ApiConfig for platform-aware base URL
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _phoneCtl = TextEditingController();
  final TextEditingController _majorCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // initialize from passed user map if available
    final user = widget.user;
    if (user != null) {
      _displayName = (user['name'] ?? user['full_name'] ?? user['displayName'] ?? user['display_name'] ?? '') as String? ?? '';
      _email = (user['email'] ?? user['email_address'] ?? '') as String? ?? '';
      _userId = (user['id'] ?? user['user_id'] ?? user['userId']) is int ? (user['id'] ?? user['user_id'] ?? user['userId']) as int : int.tryParse('${user['id'] ?? user['user_id'] ?? user['userId']}');
      _clubId = (user['club_id'] ?? user['clubId']) is int ? (user['club_id'] ?? user['clubId']) as int : int.tryParse('${user['club_id'] ?? user['clubId']}');
    }

    // seed controllers from passed user
    _nameCtl.text = _displayName;
    _emailCtl.text = _email;
    if (widget.user != null) {
      final u = widget.user!;
      _phoneCtl.text = (u['phone'] ?? u['phone_number'] ?? '') as String? ?? '';
      _majorCtl.text = (u['major'] ?? u['department'] ?? '') as String? ?? '';
    }

    // load settings and role
    _loadNotificationSettings();
    _loadRoleLabel();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _majorCtl.dispose();
    super.dispose();
  }

  Future<void> _loadNotificationSettings() async {
    if (widget.token == null) return;
    try {
      final resp = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/notifications/settings'), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          _emailNotifications = (data['email'] == true || data['email_notifications'] == true);
          _pushNotifications = (data['push'] == true || data['push_notifications'] == true);
        });
      }
    } catch (e) {
      // ignore - keep defaults
    }
  }

  Future<void> _saveNotificationSettings() async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not authenticated')));
      return;
    }
    setState(() => _loading = true);
    try {
      final body = json.encode({
        'email': _emailNotifications,
        'push': _pushNotifications,
      });
      final resp = await http.put(Uri.parse('${ApiConfig.baseUrl}/api/notifications/settings'), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      }, body: body);
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notification settings saved')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving settings')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadRoleLabel() async {
    if (widget.token == null || _clubId == null || _userId == null) return;
    try {
      final resp = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/clubs/$_clubId/members'), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body);
        if (list is List) {
          final found = list.cast<Map<String, dynamic>>().firstWhere((m) {
            final id = m['user_id'] ?? m['id'] ?? m['userId'];
            return '${id}' == '${_userId}';
          }, orElse: () => {});
          if (found.isNotEmpty) {
            setState(() {
              _roleLabel = (found['role'] ?? found['membership_role'] ?? found['role_label'] ?? 'Member') as String;
            });
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    // show loading overlay if needed
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(top: 24.0, bottom: 32.0),
                  child: Text(
                    'My Profile',
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
                    children: [
                      // Profile Header
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[800],
                          ),
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF4A90E2),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    _displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _email,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Personal Details Card (dynamic)
                  _buildDetailCard(
                    title: 'Personal Details',
                    items: [
                      {'label': 'Full Name', 'value': _displayName.isNotEmpty ? _displayName : '—'},
                      {'label': 'Email Address', 'value': _email.isNotEmpty ? _email : '—'},
                      {'label': 'Phone Number', 'value': _phoneCtl.text.isNotEmpty ? _phoneCtl.text : '(not set)'},
                      {'label': 'Major', 'value': _majorCtl.text.isNotEmpty ? _majorCtl.text : '(not set)'},
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Edit personal info
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _showEditProfileDialog,
                      icon: Icon(Icons.edit, color: Color(0xFF4A90E2)),
                      label: Text('Edit Info', style: TextStyle(color: Color(0xFF4A90E2))),
                    ),
                  ),
                  SizedBox(height: 16),

                  // My Roles Card (dynamic)
                  _buildDetailCard(
                    title: 'My Roles',
                    items: [
                      {'label': _roleLabel.isNotEmpty ? 'Role' : 'Role', 'value': _roleLabel.isNotEmpty ? _roleLabel : 'Member'},
                    ],
                  ),
                  SizedBox(height: 16),

                  // Notification Preferences Card
                  Card(
                    color: Color(0xFF1E1E1E),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Notification Preferences',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 18, color: Color(0xFF4A90E2)),
                                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Edit preferences')),
                                ),
                              ),
                            ],
                          ),
                          Divider(color: Colors.grey[800]),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Email Notifications',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              Switch(
                                value: _emailNotifications,
                                onChanged: (value) => setState(() => _emailNotifications = value),
                                activeColor: Color(0xFF4A90E2),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Push Notifications',
                                style: TextStyle(color: Colors.white, fontSize: 13),
                              ),
                              Switch(
                                value: _pushNotifications,
                                onChanged: (value) => setState(() => _pushNotifications = value),
                                activeColor: Color(0xFF4A90E2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveNotificationSettings,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF137FEC)),
                              child: const Text('Save Notification Settings'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),

                  // Account Actions
                  GestureDetector(
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Change password functionality')),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Icon(Icons.lock, size: 18, color: Color(0xFF4A90E2)),
                          SizedBox(width: 12),
                          Text(
                            'Change Password',
                            style: TextStyle(
                              color: Color(0xFF4A90E2),
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Logging out...')),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Log Out',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      if (_loading)
        Positioned.fill(
          child: Container(
            color: Colors.black45,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      ),
      
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Map<String, String>> items,
  }) {
    return Card(
      color: Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: 18, color: Color(0xFF4A90E2)),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Edit $title')),
                  ),
                ),
              ],
            ),
            Divider(color: Colors.grey[800]),
            ...List.generate(
              items.length,
              (index) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          items[index]['label']!,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          items[index]['value']!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < items.length - 1)
                    Divider(color: Colors.grey[800], height: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog() async {
    _nameCtl.text = _displayName;
    _emailCtl.text = _email;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        title: Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameCtl,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'Full name', labelStyle: TextStyle(color: Colors.grey)),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _emailCtl,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'Email', labelStyle: TextStyle(color: Colors.grey)),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _phoneCtl,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'Phone', labelStyle: TextStyle(color: Colors.grey)),
              ),
              SizedBox(height: 8),
              TextField(
                controller: _majorCtl,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'Major', labelStyle: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(onPressed: () => _saveProfile(ctx), child: Text('Save')),
        ],
      ),
    );
  }

  Future<void> _saveProfile(BuildContext dialogContext) async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not authenticated')));
      return;
    }
    setState(() => _loading = true);
    try {
      final payload = {
        'name': _nameCtl.text,
        'email': _emailCtl.text,
        'phone': _phoneCtl.text,
        'major': _majorCtl.text,
      };
      // Profile update endpoint not implemented
      // For now, just update local state
      setState(() {
        _displayName = _nameCtl.text;
        _email = _emailCtl.text;
      });
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile update functionality not yet implemented')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile')));
    } finally {
      setState(() => _loading = false);
    }
  }
}
