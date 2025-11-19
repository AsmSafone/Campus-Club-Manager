import 'package:flutter/material.dart';
import 'package:frontend/screens/member/club_details_screen.dart';
import 'package:frontend/screens/member/club_list_screen.dart';
import 'package:frontend/screens/member/my_event_list.dart';
import 'package:frontend/screens/notification_view_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/screens/club_events_screen.dart';
import 'package:frontend/screens/membership_status_management_screen.dart';
import 'package:frontend/screens/user_profile_management_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;
  const MemberDashboardScreen({Key? key, this.token, this.user})
    : super(key: key);

  @override
  _MemberDashboardScreenState createState() => _MemberDashboardScreenState();
}

class Event {
  final String title;
  final String date;
  final String status;
  final int? attendees;

  Event({
    required this.title,
    required this.date,
    required this.status,
    this.attendees,
  });

  factory Event.fromMap(Map<String, dynamic> m) {
    return Event(
      title: (m['title'] ?? m['name'] ?? '').toString(),
      date: (m['date'] ?? '').toString(),
      status: ((m['status'] ?? 'RSVP').toString()),
      attendees: m['attendees'] is num ? (m['attendees'] as num).toInt() : null,
    );
  }
}

class Announcement {
  final String title;
  final String description;
  final String date;

  Announcement({
    required this.title,
    required this.description,
    required this.date,
  });

  factory Announcement.fromMap(Map<String, dynamic> m) {
    return Announcement(
      title: (m['title'] ?? '').toString(),
      description: (m['description'] ?? '').toString(),
      date: (m['timestamp'] ?? m['date'] ?? '').toString(),
    );
  }
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  int _selectedNavIndex = 0;
  // dynamic state
  List<Event> events = [];
  List<Announcement> announcements = [];
  int _unreadNotifications = 0;
  bool _loading = false;
  String _userName = 'Member';
  String? _userEmail;
  int? _clubId;
  List<Map<String, dynamic>> _notifications = [];
  final String _apiBaseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    // initialize from passed user if available
    if (widget.user != null) {
      _userName = widget.user!['name']?.toString() ?? _userName;
      _userEmail = widget.user!['email']?.toString();
      if (widget.user!['clubId'] != null) {
        _clubId = widget.user!['clubId'] is int
            ? widget.user!['clubId'] as int
            : int.tryParse('${widget.user!['clubId']}');
      }
    }
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_fetchNotifications(), _fetchEvents()]);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _fetchNotifications() async {
    if (widget.token == null) return;
    try {
      final uri = Uri.parse('$_apiBaseUrl/api/notifications');
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final List<dynamic> list = json.decode(resp.body) as List<dynamic>;
        final items = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _notifications = items;
          _unreadNotifications = items
              .where((n) => n['isRead'] == false)
              .length;
          announcements = items
              .where((n) => (n['type'] ?? '') == 'announcement')
              .map((n) => Announcement.fromMap(n))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchEvents() async {
    if (widget.token == null) return;
    try {
      final uri = Uri.parse('$_apiBaseUrl/api/users/me/upcoming-events');
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final List<dynamic> list = json.decode(resp.body) as List<dynamic>;
        setState(() {
          // If you want to show only events for the user's club, filter by _clubId
          final filtered = _clubId != null
              ? list.where((e) => (e['club_id']?.toString() ?? '') == _clubId.toString()).toList()
              : list;
          events = filtered
              .map((e) => Event.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF101922),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFF137FEC),
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hi, $_userName',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // notifications with badge
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => NotificationViewScreen(
                                      token: widget.token,
                                    ),
                                  ),
                                );
                              },
                            ),
                            if (_unreadNotifications > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$_unreadNotifications',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/auth',
                              (route) => false,
                            );
                          },
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF192734),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Important Announcement!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Our next general body meeting has been rescheduled. See the new date and time.',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey[600]),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Learn more'))),
                        child: Row(
                          children: [
                            Text(
                              'Learn More',
                              style: TextStyle(
                                color: Color(0xFF4A90E2),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: Color(0xFF4A90E2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              events.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Text(
                        'Upcoming Events',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    ...events.map((event) => _buildEventCard(event)).toList(),
                    SizedBox(width: 8),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF192734),
        selectedItemColor: Color(0xFF4A90E2),
        unselectedItemColor: Colors.grey[600],
        currentIndex: _selectedNavIndex,
        onTap: (index) async {
          // Home: keep on this screen
          if (index == 0) {
            setState(() => _selectedNavIndex = 0);
            return;
          }
          print(index);
          // Events: open ClubEventsScreen (requires clubId and token)
          if (index == 1) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    MyEventList(token: widget.token, clubId: _clubId),
              ),
            );
            return;
          }

          // Members: open membership management
          if (index == 2) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ClubListScreen(token: widget.token, clubId: _clubId),
              ),
            );
            return;
          }

          // Profile: open user profile management
          if (index == 3) {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => UserProfileManagementScreen()),
            );
            return;
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Clubs'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      width: 288,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Color(0xFF192734),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  color: Colors.grey[800],
                ),
              ),
              if (event.status == 'CONFIRMED')
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CONFIRMED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  event.date,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(Announcement announcement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF192734),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            announcement.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            announcement.description,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Text(
            announcement.date,
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
          ),
        ],
      ),
    );
  }
}
