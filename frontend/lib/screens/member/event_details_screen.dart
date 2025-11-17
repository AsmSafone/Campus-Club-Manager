import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;
  final String? token;

  const EventDetailsScreen({super.key, required this.event, this.token});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _registering = false;
  bool _registered = false;
  int _attendees = 0;

  final String _apiBase = 'http://10.0.2.2:3000';

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

      final uri = Uri.parse('$_apiBase/api/clubs/$clubId/events/$eventId/registration');
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
      final clubId = widget.event['club_id'] ?? widget.event['clubId'] ?? widget.event['clubId'];
      final eventId = widget.event['event_id'] ?? widget.event['id'] ?? widget.event['eventId'];
      Uri uri;
      if (clubId != null && eventId != null) {
        uri = Uri.parse('$_apiBase/api/clubs/$clubId/events/$eventId/register');
      } else if (eventId != null) {
        uri = Uri.parse('$_apiBase/api/events/$eventId/register');
      } else {
        throw Exception('Invalid event id');
      }

      final resp = await http.post(uri, headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json'
      }, body: json.encode({}));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() {
          _registered = true;
          _attendees += 1;
        });
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
    final dateRaw = event['date'] ?? event['datetime'] ?? event['date_time'] ?? '';
    final date = _formatDateRaw(dateRaw);
    final venue = (event['venue'] ?? '').toString();
    final price = (event['price'] ?? event['fee'] ?? '').toString();
    final description = (event['description'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (host.isNotEmpty) Text('Hosted by $host'),
          const SizedBox(height: 16),
          Row(children: [const Icon(Icons.calendar_month), const SizedBox(width: 8), Expanded(child: Text(date))]),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.location_on), const SizedBox(width: 8), Expanded(child: Text(venue.isNotEmpty ? venue : 'TBA'))]),
          const SizedBox(height: 8),
          Row(children: [const Icon(Icons.sell), const SizedBox(width: 8), Text(price.isNotEmpty ? price : 'Free')]),
          const SizedBox(height: 16),
          const Text('About this event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description.isNotEmpty ? description : 'No description provided.'),
          const SizedBox(height: 16),
          Text('$_attendees Attendees', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registering ? null : _register,
              child: _registering
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_registered ? 'Registered' : 'Register'),
            ),
          ),
        ]),
      ),
    );
  }
}
