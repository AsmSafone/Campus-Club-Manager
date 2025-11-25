import 'package:flutter/material.dart';
import 'package:campus_club_manager/screens/event_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class MyEventList extends StatefulWidget {
  final String? token;
  final int? clubId;

  const MyEventList({Key? key, this.token, this.clubId}) : super(key: key);

  @override
  _MyEventListState createState() => _MyEventListState();
}

class _MyEventListState extends State<MyEventList> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  // Api base URL from ApiConfig
  
  @override
  void initState() {
    super.initState();
    _eventsFuture = _fetchAllEvents();
  }

  Future<List<Map<String, dynamic>>> _fetchAllEvents() async {
    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me/events'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF101922),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF137FEC).withOpacity(0.2),
                  Color(0xFF1E3A8A).withOpacity(0.15),
                  Color(0xFF101922),
                ],
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'All Events',
                      style: TextStyle(
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
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _eventsFuture,
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
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _eventsFuture = _fetchAllEvents();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF137FEC),
                          ),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                final events = snapshot.data ?? [];

                if (events.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey[600]),
                          SizedBox(height: 16),
                          Text(
                            'No events scheduled',
                            style: TextStyle(color: Colors.grey[400], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    // Safe date parsing; use placeholders when missing or invalid
                    final DateTime? eventDate = (() {
                      try {
                        final raw = event['date'] ?? event['datetime'] ?? event['date_time'];
                        if (raw == null) return null;

                        DateTime toLocalDateTime(dynamic dt) {
                          if (dt is DateTime) return dt.toLocal();
                          return DateTime.fromMillisecondsSinceEpoch(dt).toLocal();
                        }

                        if (raw is int) {
                          final s = raw.toString();
                          // if timestamp looks like seconds (10 digits) convert to ms
                          if (s.length <= 10) {
                            return toLocalDateTime(raw * 1000);
                          }
                          return toLocalDateTime(raw);
                        }

                        final rawStr = raw.toString();
                        if (RegExp(r'^\d+$').hasMatch(rawStr)) {
                          final v = int.parse(rawStr);
                          if (rawStr.length <= 10) {
                            return toLocalDateTime(v * 1000);
                          }
                          return toLocalDateTime(v);
                        }

                        // Parse ISO string and convert to local time to match details screen
                        return DateTime.parse(rawStr).toLocal();
                      } catch (_) {
                        return null;
                      }
                    })();

                    const List<String> _monthNames = [
                      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
                      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
                    ];

                    final String month = eventDate != null ? _monthNames[eventDate.month - 1] : 'TBD';
                    final String day = eventDate != null ? eventDate.day.toString().padLeft(2, '0') : '--';

                    final dynamic regFlag = event['isRegistered'] ?? event['registered'] ?? event['attending'] ?? event['is_registered'];
                    final bool isRegistered = regFlag == true || regFlag?.toString().toLowerCase() == 'true';

                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailsScreen(event: event, token: widget.token, clubId: widget.clubId),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[800]!),
                              color: Color(0xFF192734),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Date box with optional REGISTERED badge
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFF0B1620),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              month,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF137FEC),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              day,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: Color(0xFF137FEC),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // registered badge moved to right column
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Event info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event['title'] ?? 'Untitled Event',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        event['venue'] ?? 'No venue',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[400],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (event['description'] != null && event['description'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          event['description'] ?? '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Right column: registered badge + attendees
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (isRegistered)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF137FEC),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'REGISTERED',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    else
                                      const SizedBox(height: 0),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${event['attendees'] ?? 0} attendees',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (index < events.length - 1) const SizedBox(height: 12),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
