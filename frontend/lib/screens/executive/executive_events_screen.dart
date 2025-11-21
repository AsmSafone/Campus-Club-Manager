import 'package:flutter/material.dart';
import 'package:campus_club_manager/config/api_config.dart';
import 'package:campus_club_manager/screens/event_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExecutiveEventsScreen extends StatefulWidget {
  final String? token;
  final int? clubId;

  const ExecutiveEventsScreen({Key? key, this.token, this.clubId}) : super(key: key);

  @override
  _ExecutiveEventsScreenState createState() => _ExecutiveEventsScreenState();
}

class _ExecutiveEventsScreenState extends State<ExecutiveEventsScreen> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  final String _apiBaseUrl = ApiConfig.baseUrl;

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
        Uri.parse('$_apiBaseUrl/api/clubs/${widget.clubId}/events'),
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
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('All Events'),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No events scheduled',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              DateTime eventDate = DateTime.parse(event['date']);
              String month = [
                'JAN',
                'FEB',
                'MAR',
                'APR',
                'MAY',
                'JUN',
                'JUL',
                'AUG',
                'SEP',
                'OCT',
                'NOV',
                'DEC'
              ][eventDate.month - 1];
              String day = eventDate.day.toString().padLeft(2, '0');

                return Column(
                children: [
                  InkWell(
                  onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => 
                      EventDetailsScreen(event: event, token: widget.token, clubId: widget.clubId,),
                    ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Row(
                    children: [
                      Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: const Color(0xFF137FEC).withOpacity(0.2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if ((event['isRegistered'] ?? event['registered'] ?? event['attending'] ?? event['is_registered']) == true) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF137FEC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'REGISTERED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ] else const SizedBox(height: 6),
                        Text(
                          month,
                          style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF137FEC),
                          ),
                        ),
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
                      const SizedBox(width: 12),
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
                        const SizedBox(height: 4),
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
                          const SizedBox(height: 4),
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
                      Text(
                      '${event['attendees'] ?? 0} attendees',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
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
    );
  }
}
