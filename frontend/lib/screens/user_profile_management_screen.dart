import 'package:flutter/material.dart';

class UserProfileManagementScreen extends StatefulWidget {
  @override
  _UserProfileManagementScreenState createState() => _UserProfileManagementScreenState();
}

class _UserProfileManagementScreenState extends State<UserProfileManagementScreen> {
  int _selectedNavIndex = 3; // Profile tab
  bool _emailNotifications = true;
  bool _pushNotifications = false;

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
                    'Alex Johnson',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'alex.j@university.edu',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 32),

                  // Personal Details Card
                  _buildDetailCard(
                    title: 'Personal Details',
                    items: [
                      {'label': 'Full Name', 'value': 'Alex Johnson'},
                      {'label': 'Email Address', 'value': 'alex.j@university.edu'},
                      {'label': 'Phone Number', 'value': '(123) 456-7890'},
                      {'label': 'Major', 'value': 'Computer Science'},
                    ],
                  ),
                  SizedBox(height: 16),

                  // My Roles Card
                  _buildDetailCard(
                    title: 'My Roles',
                    items: [
                      {'label': 'Treasurer', 'value': 'Coding Club'},
                      {'label': 'Member', 'value': 'Hiking Society'},
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF192734),
        selectedItemColor: Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Clubs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
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
}
