import 'package:flutter/material.dart';

class BroadcastMessageScreen extends StatefulWidget {
  @override
  _BroadcastMessageScreenState createState() => _BroadcastMessageScreenState();
}

class _BroadcastMessageScreenState extends State<BroadcastMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedAudience = 'All Members';
  int _messageCharCount = 0;

  final List<String> _audienceOptions = [
    'All Members',
    'Executives',
    'New Members',
  ];

  void _sendBroadcast() {
    if (_formKey.currentState!.validate()) {
      final subject = _subjectController.text.trim();
      final audience = _selectedAudience;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Announcement sent to $audience: "$subject"')),
      );

      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedAudience = 'All Members';
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
        title: const Text('Compose Announcement'),
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
                // Audience Selector
                Text(
                  'To:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: _audienceOptions.map((audience) {
                    return ButtonSegment(label: Text(audience), value: audience);
                  }).toList(),
                  selected: {_selectedAudience},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedAudience = newSelection.first;
                    });
                  },
                ),
                SizedBox(height: 24),

                // Subject Field
                Text(
                  'Subject',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _subjectController,
                  decoration: InputDecoration(
                    hintText: 'Enter the announcement title',
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

                // Attach File Button
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attach file functionality')),
                    );
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Attach File'),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sendBroadcast,
                child: const Text('Send Announcement'),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This will be sent to 150 members.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}