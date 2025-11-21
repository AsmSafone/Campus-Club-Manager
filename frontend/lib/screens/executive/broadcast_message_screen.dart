import 'package:campus_club_manager/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BroadcastMessageScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;
  final int? clubId;
  BroadcastMessageScreen({Key? key, this.token, this.user, this.clubId}) : super(key: key);

  @override
  _BroadcastMessageScreenState createState() => _BroadcastMessageScreenState();
}

class _BroadcastMessageScreenState extends State<BroadcastMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  int _messageCharCount = 0;
  final String _apiBaseUrl = ApiConfig.baseUrl;
  int? _clubId;

  @override
  void initState() {
    super.initState();
    _clubId = widget.clubId ?? widget.user?['clubId'] ?? 1;
  }

  Future<void> _sendBroadcast() async {
    if (_formKey.currentState!.validate()) {
      final subject = _subjectController.text.trim();
      final message = _messageController.text.trim();

      if (widget.token != null && widget.token!.isNotEmpty) {
        try {
          final headers = {
            'Authorization': 'Bearer ${widget.token}',
            'Content-Type': 'application/json',
          };
          final uri = Uri.parse('$_apiBaseUrl/api/clubs/${_clubId}/notifications');
          final resp = await http.post(
            uri,
            headers: headers,
            body: json.encode({
              'title': subject,
              'description': message,
            }),
          );
          if (resp.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notification sent: "$subject"')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send (${resp.statusCode})')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification sent: "$subject"')),
        );
      }

      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _messageCharCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Notification'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                

                // Subject Field
                Text(
                  'Subject',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'Enter notification title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Message Field
                Text(
                  'Message',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                Stack(
                  children: [
                    TextFormField(
                      controller: _messageController,
                      maxLines: 8,
                      maxLength: 1000,
                      onChanged: (value) {
                        setState(() {
                          _messageCharCount = value.length;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Type your message here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Text(
                        '$_messageCharCount/1000',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border(
            // top: BorderSide(color: Colors.black!),
          ),
          // color: Colors.black,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF137FEC),
                ),
                onPressed: _sendBroadcast,
                child: const Text('Send Notification'),
              ),
            ),
            SizedBox(height: 8),
            const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}