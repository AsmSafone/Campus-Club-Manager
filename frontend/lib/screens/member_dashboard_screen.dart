import 'package:flutter/material.dart';

class MemberDashboardScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;
  const MemberDashboardScreen({Key? key, this.token, this.user}) : super(key: key);

  @override
  _MemberDashboardScreenState createState() => _MemberDashboardScreenState();
}

class Event {
  final String title;
  final String date;
  final String status;

  Event({
    required this.title,
    required this.date,
    required this.status,
  });
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
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  int _selectedNavIndex = 0;

  final List<Event> events = [
    Event(title: 'Annual Tech Conference', date: 'Dec 15, 6:00 PM', status: 'CONFIRMED'),
    Event(title: 'Intro to Python Workshop', date: 'Dec 18, 7:00 PM', status: 'RSVP'),
    Event(title: 'Guest Speaker: Jane Doe', date: 'Dec 22, 5:00 PM', status: 'RSVP'),
  ];

  final List<Announcement> announcements = [
    Announcement(
      title: 'Volunteer Call for Annual Charity Drive',
      description: 'We\'re looking for volunteers to help us make this year\'s charity drive a success...',
      date: 'Posted on Nov 28',
    ),
    Announcement(
      title: 'October Meeting Minutes',
      description: 'Thanks to everyone who attended! The minutes from our last meeting are now available...',
      date: 'Posted on Nov 15',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF101922),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hi, Alex!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.notifications, color: Colors.white),
                        onPressed: () {},
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
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[800],
                        child: Icon(Icons.person, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Learn more')),
                      ),
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
                          Icon(Icons.arrow_forward, size: 16, color: Color(0xFF4A90E2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Upcoming Events',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'My Status',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF192734),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Membership', style: TextStyle(color: Colors.grey[400])),
                        Text('Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(color: Colors.grey[800]),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dues', style: TextStyle(color: Colors.grey[400])),
                        Text('Unpaid', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Manage Membership')),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFF4A90E2).withOpacity(0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: Text(
                          'Manage Membership',
                          style: TextStyle(color: Color(0xFF4A90E2), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Recent Announcements',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: announcements.map((announcement) => _buildAnnouncementCard(announcement)).toList(),
              ),
            ),
            SizedBox(height: 100),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Members'),
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
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(event.status == 'CONFIRMED' ? 'View Details' : 'RSVP')),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: event.status == 'CONFIRMED' ? Color(0xFF4A90E2) : Color(0xFF4A90E2).withOpacity(0.2),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      event.status == 'CONFIRMED' ? 'View Details' : 'RSVP',
                      style: TextStyle(
                        color: event.status == 'CONFIRMED' ? Colors.white : Color(0xFF4A90E2),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
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
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8),
          Text(
            announcement.date,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
