import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final String? token;
  final int? clubId;

  const EventDetailsScreen({super.key, required this.event, required this.token, required this.clubId});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _registering = false;
  bool _registered = false;
  int _attendees = 0;

  // Api base URL

  @override
  void initState() {
    super.initState();
    // initialize attendees from passed event
    final a = widget.event['attendees'];
    _attendees = a is num ? a.toInt() : int.tryParse('$a') ?? 0;
    // if event contains a flag showing current user is registered, use it
    final regFlag = widget.event['is_registered'] ?? widget.event['registered'];
    _registered = regFlag == true || regFlag == 'true';
    // fetch registration status from server
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    if (widget.token == null) return;
    try {
      final clubId = widget.event['club_id'] ?? widget.event['clubId'];
      final eventId = widget.event['event_id'] ?? widget.event['id'] ?? widget.event['eventId'];
      if (clubId == null || eventId == null) return;

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/clubs/$clubId/events/$eventId/registration');
      final resp = await http.get(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      });

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (mounted) {
          setState(() => _registered = data['registered'] == true);
        }
      }
    } catch (e) {
      // ignore errors; rely on local state
    }
  }

  Future<void> _register() async {
    if (widget.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be signed in to register')));
      return;
    }
    if (_registered) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already registered')));
      return;
    }

    setState(() => _registering = true);
    try {
      // Prefer club-scoped registration endpoint
      // final clubId = widget.event['club_id'] ?? widget.event['clubId'] ?? widget.event['clubId'];
      final eventId = widget.event['event_id'] ?? widget.event['id'] ?? widget.event['eventId'];
      if (eventId == null) {
        throw Exception('Event ID not found');
      }
      Uri uri = Uri.parse('${ApiConfig.baseUrl}/api/events/$eventId/register');

      final resp = await http.post(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      }, body: json.encode({}));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (mounted) {
          setState(() {
            _registered = true;
            _attendees += 1;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered successfully')));
      } else {
        try {
          final body = json.decode(resp.body);
          final msg = body['message'] ?? 'Registration failed';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        } catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration failed')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration error: $e')));
    } finally {
      setState(() => _registering = false);
    }
  }

  String _formatDateRaw(dynamic raw) {
    if (raw == null) return 'TBA';
    final s = raw.toString();
    if (s.isEmpty) return 'TBA';
    try {
      final dt = DateTime.parse(s).toLocal();
      final weekdays = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final wk = weekdays[dt.weekday - 1];
      final mon = months[dt.month - 1];
      final day = dt.day;
      final year = dt.year;
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      final time = '$hh:$mm';
      // If time is midnight (00:00) treat it as all-day
      if (hh == '00' && mm == '00') {
        return '$wk, $mon $day, $year';
      }
      return '$wk, $mon $day, $year · $time';
    } catch (e) {
      return s; // fallback to raw string when parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final title = (event['title'] ?? event['name'] ?? 'Event').toString();
    final host = (event['club_name'] ?? event['club'] ?? '').toString();
    
    // Handle date and time separately - combine if time exists
    String dateRaw = event['date'] ?? event['datetime'] ?? event['date_time'] ?? '';
    final eventTime = event['time'];
    if (dateRaw.isNotEmpty && eventTime != null && eventTime.toString().isNotEmpty) {
      // Combine date and time
      dateRaw = '$dateRaw ${eventTime.toString().trim()}';
    }
    final date = _formatDateRaw(dateRaw);
    
    final venue = (event['venue'] ?? '').toString();
    final price = (event['price'] ?? event['fee'] ?? '').toString();
    final description = (event['description'] ?? '').toString();
    final status = (event['status'] ?? 'Pending').toString();
    final capacity = event['capacity'];

    // Event image
    final imageUrl = event['image'] ?? event['image_url'];
    
    // Status color
    final statusUpper = status.toUpperCase();
    Color statusColor;
    switch (statusUpper) {
      case 'CONFIRMED':
      case 'COMPLETED':
        statusColor = Colors.green;
        break;
      case 'CANCELLED':
        statusColor = Colors.red;
        break;
      case 'PENDING':
      default:
        statusColor = Colors.orange;
        break;
    }

    return Scaffold(
      backgroundColor: Color(0xFF101922),
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
                      'Event Details',
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event image if available
                  if (imageUrl != null && imageUrl.toString().isNotEmpty)
                    Container(
                      height: 200,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(imageUrl.toString()),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      statusUpper,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (host.isNotEmpty)
                    Text(
                      'Hosted by $host',
                      style: TextStyle(color: Colors.grey[300]),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(date, style: TextStyle(color: Colors.white))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          venue.isNotEmpty ? venue : 'TBA',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.sell, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        price.isNotEmpty ? price : 'Free',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  if (capacity != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.event_seat, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Capacity: $capacity ${capacity > 1 ? 'attendees' : 'attendee'}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'About this event',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isNotEmpty ? description : 'No description provided.',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$_attendees${capacity != null ? ' / $capacity' : ''} Attendees',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_registering || _registered) ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _registered ? Colors.grey : Color(0xFF137FEC),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _registering
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _registered ? 'Registered' : 'Register',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
