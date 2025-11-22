import 'package:flutter/material.dart';
import 'package:campus_club_manager/screens/member/club_details_screen.dart';
import 'package:campus_club_manager/screens/member/club_list_screen.dart';
import 'package:campus_club_manager/screens/member/my_event_list.dart';
import 'package:campus_club_manager/screens/notification_view_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:campus_club_manager/screens/executive/executive_events_screen.dart';
import 'package:campus_club_manager/screens/member/user_profile_management_screen.dart';
import 'package:intl/intl.dart';
import '../../config/api_config.dart';
import 'package:campus_club_manager/utils/auth_utils.dart';

class MemberDashboardScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;
  const MemberDashboardScreen({Key? key, this.token, this.user})
    : super(key: key);

  @override
  _MemberDashboardScreenState createState() => _MemberDashboardScreenState();
}

class Event {
  final int eventId;
  final String title;
  final String date;
  final String status;
  final int? attendees;

  Event({
    required this.eventId,
    required this.title,
    required this.date,
    required this.status,
    this.attendees,
  });

  factory Event.fromMap(Map<String, dynamic> m) {
    return Event(
      eventId: m['event_id'] is num ? (m['event_id'] as num).toInt() : int.tryParse('${m['event_id']}') ?? 0,
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
  List<dynamic>? _latestAnnouncement;
  List<dynamic>? _myClubs;
  bool _lastScrollWasReverse = false;
  Timer? _autoRefreshTimer;
  Set<int> _dismissedAnnouncements = {}; // Track dismissed announcements by ID
  // Api base URL

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
    // Start auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_loading) {
        _loadDashboard();
      }
    });
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      await Future.wait([_fetchEvents(), _fetchLatestAnnouncement(), _fetchMyClubs()]);
    } catch (_) {}
    setState(() => _loading = false);
  }
  
  Future<void> _fetchMyClubs() async {
    if (widget.token == null) return;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/me/clubs');
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final List<dynamic> list = json.decode(resp.body) as List<dynamic>;
        setState(() {
          _myClubs = list;
        });
      } else {
        setState(() {
          _myClubs = [];
        });
      }
    } catch (_) {
      setState(() {
        _myClubs = [];
      });
    }
  }


  Future<void> _fetchLatestAnnouncement() async {
    if (widget.token == null || _clubId == null) return;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/clubs/$_clubId/notifications/latest');
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List<dynamic>;
        setState(() {
          _latestAnnouncement = data;
        });
      } else {
        // no latest announcement or error (204 returns no content)
        setState(() {
          _latestAnnouncement = null;
        });
      }
    } catch (_) {
      setState(() {
        _latestAnnouncement = null;
      });
    }
  }

  Future<void> _fetchEvents() async {
    if (widget.token == null) return;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/users/me/upcoming-events');
      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (resp.statusCode == 200) {

        final List<dynamic> list = json.decode(resp.body) as List<dynamic>;
        setState(() {
          // If you want to show only events for the user's club, filter by _clubId
          events = list
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
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is UserScrollNotification) {
              _lastScrollWasReverse = notification.direction.toString().endsWith('.reverse');
            }
            if (notification is ScrollEndNotification) {
              if (_lastScrollWasReverse && !_loading) {
                // user swiped up (content moved up) — refresh dashboard
                _loadDashboard();
              }
            }
            return false;
          },
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
                          IconButton(
                              onPressed: _loadDashboard,
                              icon: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                              ),
                              tooltip: 'Refresh',
                            ),
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
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                              onPressed: () async {
                                await signOutAndNavigate(context);
                              },
                            tooltip: 'Logout',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_latestAnnouncement != null && _latestAnnouncement!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF192734),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[800]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Latest Announcements',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          ..._latestAnnouncement!.where((ann) {
                            final annMap = Map<String, dynamic>.from(ann as Map);
                            final annId = annMap['id'] ?? annMap['notification_id'];
                            if (annId == null) return true;
                            // Convert to int if possible
                            final idInt = annId is int ? annId : (annId is num ? annId.toInt() : int.tryParse(annId.toString()));
                            return idInt == null || !_dismissedAnnouncements.contains(idInt);
                          }).map((ann) {
                            final announcement = Announcement.fromMap(Map<String, dynamic>.from(ann as Map));
                            return _buildAnnouncementCard(announcement, ann);
                          }).toList(),
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
                      ...events.map((event) {
                            return _buildEventCard(event);
                      }).toList(),
                      SizedBox(width: 8),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                if(_myClubs != null && _myClubs!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Clubs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      ..._myClubs!.map((club) {
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ClubDetailsScreen(
                                  token: widget.token,
                                  club: Club.fromMap(Map<String, dynamic>.from(club as Map)),
                                ),
                              ),
                            );
                          },
                            child: Card(
                              color: Color(0xFF192734),
                              shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[800]!),
                              ),
                              margin: EdgeInsets.only(bottom: 12),
                              child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                // Club logo/avatar if available
                                if (club['logo'] != null && club['logo'].toString().isNotEmpty)
                                  CircleAvatar(
                                  backgroundImage: NetworkImage(club['logo'].toString()),
                                  radius: 24,
                                  backgroundColor: Colors.grey[900],
                                  )
                                else
                                  CircleAvatar(
                                  child: Icon(
                                    Club.fromMap(Map<String, dynamic>.from(club as Map)).icon,
                                    color: Colors.white54,
                                  ),
                                  radius: 24,
                                  backgroundColor: Colors.grey[900],
                                  ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                    club['name']?.toString() ?? 'Unnamed Club',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    ),
                                    SizedBox(height: 4),
                                    if (club['description'] != null && club['description'].toString().isNotEmpty)
                                    Text(
                                      club['description'].toString(),
                                      style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 13,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                    children: [
                                      Icon(Icons.people, size: 14, color: Colors.grey[400]),
                                      SizedBox(width: 4),
                                      Text(
                                      (club['members_count'] ?? club['members']?.length ?? '—').toString(),
                                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                      ),
                                      SizedBox(width: 12),
                                    ],
                                    ),
                                  ],
                                  ),
                                ),
                                ],
                              ),
                              ),
                            ),
                        );
                      }).toList(),
                    ],
                  ),
                )
                else Column(
                  
                  children: [
                    Text(
                    'You are not a member of any clubs yet.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.group_add, color: Colors.white),
                      label: Text('Join a Club', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF137FEC),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClubListScreen(token: widget.token, clubId: _clubId),
                          ),
                        );
                        await _loadDashboard();
                      },
                    ),
                  ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
          color: const Color(0xFF121212),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF121212),
          selectedItemColor: const Color(0xFF137FEC),
          unselectedItemColor: Colors.grey[600],
          currentIndex: _selectedNavIndex,
          onTap: (index) async {
            setState(() {
              _selectedNavIndex = index;
            });
            
            // Home: reload dashboard when returning to this screen
            if (index == 0) {
              await _loadDashboard();
              return;
            }
            
            // Events: open MyEventList (requires clubId and token)
            if (index == 1) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      MyEventList(token: widget.token, clubId: _clubId),
                ),
              );
              return;
            }

            // Clubs: open membership management
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Clubs'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(dynamic event) {
    // Support both raw Map objects (from API) and Event instances
    final Map<String, dynamic> data = event is Map<String, dynamic>
        ? Map<String, dynamic>.from(event)
        : {
            'event_id': event.eventId,
            'title': (event.title ?? '').toString(),
            'date': (event.date ?? '').toString(),
            'status': (event.status ?? '').toString(),
            'attendees': event.attendees,
          };

    // Helper to prettify keys
    String prettyKey(String k) {
      return k.replaceAllMapped(RegExp(r'[_\-]'), (m) => ' ').splitMapJoin(
            RegExp(r'\b\w'),
            onMatch: (m) => m.group(0)!.toUpperCase(),
            onNonMatch: (s) => s,
          );
    }

       String _formatDt(DateTime dt) {
      // Simple human-friendly format: "Mon, Jan 2 · 3:04 PM"
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      final wk = weekdays[dt.weekday - 1];
      final mon = months[dt.month - 1];
      final day = dt.day;
      final year = dt.year;
      int hour = dt.hour;
      final minute = dt.minute;
      final ampm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final minStr = minute.toString().padLeft(2, '0');
      return '$wk, $mon $day, $year · $hour:$minStr $ampm';
    }
  

    // Try to parse various datetime representations and format human-readable
    String formatDateHuman(dynamic raw) {
      if (raw == null) return '';
      // If already a DateTime
      if (raw is DateTime) {
        return _formatDt(raw.toLocal());
      }
      // If numeric (timestamp)
      if (raw is num) {
        // guess milliseconds vs seconds
        int v = raw.toInt();
        DateTime dt;
        if (v.abs() > 1000000000000) {
          // milliseconds
          dt = DateTime.fromMillisecondsSinceEpoch(v).toLocal();
        } else {
          // seconds
          dt = DateTime.fromMillisecondsSinceEpoch(v * 1000).toLocal();
        }
        return _formatDt(dt);
      }
      // If string, try parsing ISO-like or a plain number string
      final s = raw.toString();
      if (s.isEmpty) return '';
      // numeric string?
      final numVal = int.tryParse(s);
      if (numVal != null) {
        return formatDateHuman(numVal);
      }
      try {
        // DateTime.parse supports many ISO formats
        final dt = DateTime.parse(s).toLocal();
        return _formatDt(dt);
      } catch (_) {
        // try common patterns like "2023-08-12 14:30" => replace space with 'T'
        try {
          final dt = DateTime.parse(s.replaceFirst(' ', 'T')).toLocal();
          return _formatDt(dt);
        } catch (_) {
          // fallback: return original trimmed string
          return s;
        }
      }
    }

 
    // Map some common keys to icons
    final Map<String, IconData> iconForKey = {
      'date': Icons.calendar_today,
      'start': Icons.schedule,
      'end': Icons.schedule,
      'time': Icons.access_time,
      'location': Icons.location_on,
      'venue': Icons.location_on,
      'capacity': Icons.event_seat,
      'attendees': Icons.people,
      'organizer': Icons.person,
      'host': Icons.person,
      'description': Icons.notes,
      'status': Icons.info,
      'title': Icons.event_note,
    };

    final status = (data['status'] ?? 'RSVP').toString().toUpperCase();
    Color statusColor;
    switch (status) {
      case 'CONFIRMED':
      case 'ACTIVE':
        statusColor = Colors.green[600]!;
        break;
      case 'CANCELLED':
      case 'CLOSED':
        statusColor = Colors.red[600]!;
        break;
      case 'PENDING':
      case 'RSVP':
        statusColor = Colors.orange[600]!;
        break;
      default:
        statusColor = Colors.blueGrey;
    }
    // Fields to show prominently (if present)
    final title = (data['title'] ?? data['name'] ?? '').toString();
    final rawDateVal = data['date'] ?? data['timestamp'] ?? data['time'] ?? data['start'] ?? data['datetime'] ?? data['dateTime'];
    final date = formatDateHuman(rawDateVal);
    final attendees = data['attendees'] ?? data['rsvpCount'] ?? data['capacity'];
    final description = (data['description'] ?? data['details'] ?? '').toString();
    // Build a list of additional fields (exclude already shown)
    final excluded = {'title', 'name', 'date', 'timestamp', 'time', 'start', 'datetime', 'dateTime', 'status', 'attendees', 'rsvpCount', 'capacity', 'description', 'details'};

    final additionalEntries = data.entries
        .where((e) => !excluded.contains(e.key))
        .toList();

    return InkWell(
      onTap: () {
        // Navigate to all events page
        try {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MyEventList(token: widget.token, clubId: _clubId),
            ),
          );
        } catch (_) {}
      },
      child: Container(
      width: 320,
      margin: EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Color(0xFF192734),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / banner area with status badge
          Stack(
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[850],
                  image: data['image'] != null
                      ? DecorationImage(
                          image: NetworkImage(data['image'].toString()),
                          fit: BoxFit.cover,
                          colorFilter:
                              ColorFilter.mode(Colors.black26, BlendMode.darken),
                        )
                      : null,
                ),
                child: data['image'] == null
                    ? Center(
                        child: Icon(
                          Icons.event,
                          color: Colors.white24,
                          size: 56,
                        ),
                      )
                    : null,
              ),
              // Status badge
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        iconForKey['status'],
                        size: 12,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  title.isNotEmpty ? title : 'Untitled Event',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),

                // Date and attendees row
                Row(
                  children: [
                    if (date.isNotEmpty)
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                date,
                                style: TextStyle(color: Colors.grey[300], fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (attendees != null) ...[
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.people, size: 14, color: Colors.grey[300]),
                            SizedBox(width: 6),
                            Text(
                              attendees.toString(),
                              style: TextStyle(color: Colors.grey[300], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                SizedBox(height: 10),

                // Description (if present)
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      ));
  }

  Widget _buildAnnouncementCard(Announcement announcement, dynamic annData) {
    final annMap = Map<String, dynamic>.from(annData as Map);
    final annId = annMap['id'] ?? annMap['notification_id'];
    
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF192734),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!.withOpacity(0.3)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  announcement.title.isNotEmpty 
                      ? announcement.title 
                      : 'Important Announcement!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 12),
                // Description
                if (announcement.description.isNotEmpty)
                  Text(
                    announcement.description,
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                SizedBox(height: 16),
                // Learn More link
                InkWell(
                  onTap: () {
                    // Navigate to notification panel
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NotificationViewScreen(
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Learn More',
                        style: TextStyle(
                          color: Color(0xFF137FEC),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF137FEC),
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dismiss button in top right
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.grey[400],
                size: 20,
              ),
              onPressed: () {
                // Dismiss/hide this announcement
                if (annId != null) {
                  setState(() {
                    // Convert to int if possible
                    final idInt = annId is int 
                        ? annId 
                        : (annId is num 
                            ? annId.toInt() 
                            : int.tryParse(annId.toString()));
                    if (idInt != null) {
                      _dismissedAnnouncements.add(idInt);
                    }
                  });
                }
              },
              padding: EdgeInsets.all(4),
              constraints: BoxConstraints(),
              tooltip: 'Dismiss',
            ),
          ),
        ],
      ),
    );
  }
}
