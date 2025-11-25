import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../utils/auth_utils.dart';

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

    // load user data if not provided
    if (widget.user == null && widget.token != null) {
      _loadUserData();
    }
    
    // load settings and role
    _loadNotificationSettings();
    _loadRoleLabel();
  }

  Future<void> _loadUserData() async {
    if (widget.token == null) return;
    try {
      // Get user profile data
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final userData = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _displayName = (userData['name'] ?? '').toString();
          _email = (userData['email'] ?? '').toString();
          _userId = userData['id'] is int 
              ? userData['id'] as int 
              : (userData['user_id'] is int 
                  ? userData['user_id'] as int 
                  : int.tryParse('${userData['id'] ?? userData['user_id']}'));
          _clubId = userData['clubId'] is int 
              ? userData['clubId'] as int 
              : (userData['club_id'] is int 
                  ? userData['club_id'] as int 
                  : int.tryParse('${userData['clubId'] ?? userData['club_id']}'));
          
          // Update controllers
          _nameCtl.text = _displayName;
          _emailCtl.text = _email;
        });
      }
    } catch (e) {
      // ignore - will use defaults
    }
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
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101922),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Gradient Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF137FEC).withOpacity(0.2),
                      const Color(0xFF1E3A8A).withOpacity(0.15),
                      const Color(0xFF101922),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'My Profile',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Profile Header
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF192734),
                                border: Border.all(
                                  color: const Color(0xFF137FEC).withOpacity(0.3),
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.grey[500],
                              ),
                            ),
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: _showEditProfileDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF137FEC),
                                    border: Border.all(
                                      color: const Color(0xFF101922),
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _email,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      if (_roleLabel.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF137FEC).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _roleLabel,
                            style: const TextStyle(
                              color: Color(0xFF137FEC),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Personal Details Card
                      _buildDetailCard(
                        title: 'Personal Details',
                        icon: Icons.person_outline,
                        items: [
                          {'label': 'Full Name', 'value': _displayName.isNotEmpty ? _displayName : '—'},
                          {'label': 'Email Address', 'value': _email.isNotEmpty ? _email : '—'},
                          {'label': 'Phone Number', 'value': _phoneCtl.text.isNotEmpty ? _phoneCtl.text : '(not set)'},
                          {'label': 'Major', 'value': _majorCtl.text.isNotEmpty ? _majorCtl.text : '(not set)'},
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Notification Preferences Card
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF192734),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF137FEC).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: Color(0xFF137FEC),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Notification Preferences',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildSwitchRow(
                                'Email Notifications',
                                'Receive updates via email',
                                _emailNotifications,
                                (value) => setState(() => _emailNotifications = value),
                              ),
                              const SizedBox(height: 12),
                              _buildSwitchRow(
                                'Push Notifications',
                                'Receive push alerts',
                                _pushNotifications,
                                (value) => setState(() => _pushNotifications = value),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveNotificationSettings,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF137FEC),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Save Settings'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await signOutAndNavigate(context);
                          },
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text('Log Out'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[400],
                            side: BorderSide(color: Colors.red[400]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_loading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF137FEC)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF137FEC),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Map<String, String>> items,
    IconData icon = Icons.info_outline,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF192734),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF137FEC),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF137FEC), size: 20),
                  onPressed: _showEditProfileDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(
              items.length,
              (index) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          items[index]['label']!,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            items[index]['value']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
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
        backgroundColor: const Color(0xFF192734),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_nameCtl, 'Full Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_emailCtl, 'Email', Icons.email_outlined),
              const SizedBox(height: 16),
              _buildTextField(_phoneCtl, 'Phone', Icons.phone_outlined),
              const SizedBox(height: 16),
              _buildTextField(_majorCtl, 'Major', Icons.school_outlined),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () => _saveProfile(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF137FEC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
        filled: true,
        fillColor: const Color(0xFF101922),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF137FEC)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _saveProfile(BuildContext dialogContext) async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Not authenticated')));
      return;
    }
    
    // Validate required fields
    if (_nameCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name is required')),
      );
      return;
    }
    
    if (_emailCtl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email is required')),
      );
      return;
    }
    
    setState(() => _loading = true);
    try {
      final payload = {
        'name': _nameCtl.text.trim(),
        'email': _emailCtl.text.trim(),
        if (_phoneCtl.text.trim().isNotEmpty) 'phone': _phoneCtl.text.trim(),
        if (_majorCtl.text.trim().isNotEmpty) 'major': _majorCtl.text.trim(),
      };
      
      // Try to update profile via API
      try {
        final resp = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
          headers: {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          },
          body: json.encode(payload),
        );
        
        if (resp.statusCode == 200 || resp.statusCode == 204) {
          // Update local state
          setState(() {
            _displayName = _nameCtl.text.trim();
            _email = _emailCtl.text.trim();
          });
          Navigator.of(dialogContext).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );
          return;
        }
      } catch (apiError) {
        // API endpoint may not exist, try alternative endpoint
        try {
          final resp = await http.put(
            Uri.parse('${ApiConfig.baseUrl}/api/users/profile'),
            headers: {
              'Authorization': 'Bearer ${widget.token}',
              'Content-Type': 'application/json',
            },
            body: json.encode(payload),
          );
          
          if (resp.statusCode == 200 || resp.statusCode == 204) {
            setState(() {
              _displayName = _nameCtl.text.trim();
              _email = _emailCtl.text.trim();
            });
            Navigator.of(dialogContext).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile updated successfully')),
            );
            return;
          }
        } catch (_) {
          // Fall through to local update
        }
      }
      
      // If API endpoints don't exist, update locally
      setState(() {
        _displayName = _nameCtl.text.trim();
        _email = _emailCtl.text.trim();
      });
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated locally. API endpoint may need to be implemented.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
