import 'package:flutter/material.dart';
import 'package:campus_club_manager/screens/executive/club_detail_screen.dart';
import 'package:campus_club_manager/utils/auth_utils.dart';
import 'package:campus_club_manager/screens/financial_overview_screen.dart';
import 'package:http/http.dart' as http;
import 'package:campus_club_manager/config/api_config.dart';
import 'dart:convert';
import 'executive_events_screen.dart';
import '../finance_transactions_screen.dart';
import '../club_executive_club_management_screen.dart';
import '../notification_view_screen.dart';
import 'broadcast_message_screen.dart';

class ClubExecutiveDashboardScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;
  const ClubExecutiveDashboardScreen({Key? key, this.token, this.user})
    : super(key: key);

  @override
  _ClubExecutiveDashboardScreenState createState() =>
      _ClubExecutiveDashboardScreenState();
}

class _ClubExecutiveDashboardScreenState
    extends State<ClubExecutiveDashboardScreen> {
  int _selectedBottomNavIndex = 0;
  final String _apiBaseUrl = ApiConfig.baseUrl;

  Map<String, dynamic>? _clubDetails;
  Map<String, dynamic>? _financeData;
  bool _isLoading = true;
  String? _errorMessage;
  int? _clubId;

  // Event form controllers
  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventDateController = TextEditingController();
  final _eventTimeController = TextEditingController();
  final _eventVenueController = TextEditingController();

  // Member form controllers
  final _memberEmailController = TextEditingController();
  final _memberNameController = TextEditingController();

  // Finance form controllers
  final _financeTypeController = TextEditingController();
  final _financeAmountController = TextEditingController();
  final _financeDateController = TextEditingController();
  final _financeDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeClubData();
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _eventDateController.dispose();
    _eventTimeController.dispose();
    _eventVenueController.dispose();
    _memberEmailController.dispose();
    _memberNameController.dispose();
    _financeTypeController.dispose();
    _financeAmountController.dispose();
    _financeDateController.dispose();
    _financeDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeClubData() async {
    // Get clubId from user data if available
    if (widget.user != null && widget.user!['clubId'] != null) {
      _clubId = widget.user!['clubId'];
    } else {
      // Fallback to clubId = 1 if not available
      _clubId = 1;
    }
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (widget.token == null || widget.token!.isEmpty) {
        setState(() {
          _errorMessage = 'No authentication token available.';
          _isLoading = false;
        });
        return;
      }

      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      // Fetch club details and finance data in parallel
      final results = await Future.wait([
        _fetchClubDetails(headers),
        _fetchFinanceData(headers),
      ]);

      setState(() {
        _clubDetails = results[0];
        _financeData = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading dashboard: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchClubDetails(
    Map<String, String> headers,
  ) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/api/executive/club/$_clubId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Club Details Response: $data');

      // Ensure we have the correct data structure
      return {
        'name': data['name'] ?? 'Club Name',
        'member_count': data['member_count'] ?? 0,
        'upcoming_events': data['upcoming_events'] ?? 0,
        'balance': data['balance']?.toString() ?? '0.00',
      };
    } else {
      throw Exception('Failed to load club details: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> _fetchFinanceData(
    Map<String, String> headers,
  ) async {
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/api/clubs/$_clubId/finance'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Finance Data Response: $data');

      double totalIncome = 0;
      double totalExpense = 0;

      if (data['summary'] != null) {
        var incomeValue = data['summary']['totalIncome'] ?? 0;
        var expenseValue = data['summary']['totalExpense'] ?? 0;

        // Handle both String and numeric types
        totalIncome = incomeValue is String
            ? double.parse(incomeValue)
            : (incomeValue as num).toDouble();
        totalExpense = expenseValue is String
            ? double.parse(expenseValue)
            : (expenseValue as num).toDouble();
      }

      return {
        'records': data['records'] ?? [],
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
      };
    } else {
      throw Exception('Failed to load finance data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final clubName = _clubDetails?['name'] ?? 'Club Name';
    final memberCount = (_clubDetails?['member_count'] ?? 0).toString();
    final upcomingEvents = (_clubDetails?['upcoming_events'] ?? 0).toString();
    final balance = _clubDetails?['balance'] ?? '0.00';

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with club info and notifications
            Container(
              color: const Color(0xFF1E1E1E),
              padding: const EdgeInsets.all(16.0),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    // Club logo
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[400],
                      ),
                      child: const Icon(Icons.computer, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    // Club name
                    Expanded(
                      child: Text(
                        clubName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Notification icon with badge
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NotificationViewScreen(token: widget.token),
                              ),
                            );
                          },
                        ),
                        // Positioned(
                        //   top: 8,
                        //   right: 8,
                        //   child: Container(
                        //     padding: const EdgeInsets.all(4),
                        //     decoration: BoxDecoration(
                        //       color: Colors.red,
                        //       shape: BoxShape.circle,
                        //     ),
                        //     child: const Text(
                        //       '0',
                        //       style: TextStyle(
                        //         color: Colors.white,
                        //         fontSize: 10,
                        //         fontWeight: FontWeight.bold,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                    // Logout button
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () async {
                        await signOutAndNavigate(context);
                      },
                      tooltip: 'Logout',
                    ),
                  ],
                ),
              ),
            ),

            // Stats cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Members',
                      memberCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Upcoming Events',
                      upcomingEvents.toString(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard('Current Balance', '\$$balance'),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showCreateEventModal(),
                      icon: const Icon(Icons.add),
                      label: const Text('New Event'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137FEC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddMemberModal(),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add Member'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey[700]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Upcoming Events section
            _buildSection(
              title: 'Upcoming Events',
              subtitle:
                  'You have $upcomingEvents events in the next month. Manage them here.',
              children: (_clubDetails?['upcoming_events'] ?? 0) == 0
                  ? [const Center(child: Text('No upcoming events'))]
                  : [
                      Center(
                        child: Text(
                          'You have ${_clubDetails?['upcoming_events']} upcoming event(s).',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
              showViewAll: true,
            ),

            const SizedBox(height: 16),

            // Financial Overview section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1E1E1E),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Summary of your club\'s finances.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 16),
                  // Donut chart representation
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CustomPaint(
                            painter: DonutChartPainter(
                              income: _financeData?['totalIncome'] ?? 0,
                              expense: _financeData?['totalExpense'] ?? 0,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Balance',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[400]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${(_financeData?['balance'] ?? 0).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Income: \$${(_financeData?['totalIncome'] ?? 0).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Expenses: \$${(_financeData?['totalExpense'] ?? 0).toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Finance buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showAddRecordModal,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Record'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey[700]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FinancialOverviewScreen(
                                  token: widget.token,
                                  clubId: _clubId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF137FEC,
                            ).withOpacity(0.2),
                            foregroundColor: const Color(0xFF137FEC),
                          ),
                          child: const Text('View Transactions'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[800]!)),
          color: const Color(0xFF121212),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedBottomNavIndex,
          onTap: (index) {
            setState(() {
              _selectedBottomNavIndex = index;
            });

            // Navigate based on selected tab
            switch (index) {
              case 0:
                // Events - navigate to ExecutiveEventsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ExecutiveEventsScreen(token: widget.token, clubId: _clubId),
                  ),
                );
                break;
              case 1:
                // Members - navigate to ClubExecutiveClubManagementScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ClubDetailScreen(token: widget.token, clubId: _clubId),
                  ),
                );
                break;
              case 2:
                // Finances - navigate to FinanceTransactionsScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FinancialOverviewScreen(
                      token: widget.token,
                      clubId: _clubId,
                    ),
                  ),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BroadcastMessageScreen(
                      token: widget.token,
                      user: widget.user,
                      clubId: _clubId,
                    ),
                  ),
                );
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF121212),
          selectedItemColor: const Color(0xFF137FEC),
          unselectedItemColor: Colors.grey[600],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Members'),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments),
              label: 'Finances',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.send),
              label: 'Send Notification',
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventModal() {
    _eventTitleController.clear();
    _eventDescriptionController.clear();
    _eventDateController.clear();
    _eventTimeController.clear();
    _eventVenueController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Create New Event',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _eventTitleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Event Title',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF137FEC)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventDescriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF137FEC)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventDateController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Date (YYYY-MM-DD)',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF137FEC)),
                    ),
                  ),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _eventDateController.text =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventTimeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Time (HH:MM)',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF137FEC)),
                    ),
                  ),
                  onTap: () async {
                    TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      _eventTimeController.text =
                          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _eventVenueController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Venue/Location',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF137FEC)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => _submitCreateEvent(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
              ),
              child: const Text('Create Event'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitCreateEvent() async {
    if (_eventTitleController.text.isEmpty ||
        _eventDateController.text.isEmpty ||
        _eventVenueController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final body = json.encode({
        'title': _eventTitleController.text.trim(),
        'description': _eventDescriptionController.text.trim(),
        'date': _eventDateController.text.trim(),
        'time': _eventTimeController.text.trim(),
        'venue': _eventVenueController.text.trim(),
      });

      print('Creating event with body: $body');

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/clubs/$_clubId/events'),
        headers: headers,
        body: body,
      );

      print('Create event response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        await _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event created successfully')),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create event: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error creating event: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddMemberModal() {
    _memberNameController.clear();
    _memberEmailController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Add New Member',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _memberNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Member Name',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF137FEC)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _memberEmailController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF137FEC)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => _submitAddMember(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF137FEC),
              ),
              child: const Text('Add Member'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitAddMember() async {
    if (_memberNameController.text.isEmpty ||
        _memberEmailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final body = json.encode({
        'name': _memberNameController.text.trim(),
        'email': _memberEmailController.text.trim(),
      });

      print('Adding member with body: $body');

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/clubs/$_clubId/members'),
        headers: headers,
        body: body,
      );

      print('Add member response: ${response.statusCode} - ${response.body}');

      Navigator.pop(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully')),
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to add member: ${errorData['message'] ?? errorData['error'] ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add member: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error adding member: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddRecordModal() {
    _financeAmountController.clear();
    _financeDateController.clear();
    _financeDescriptionController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedType = 'Income';

        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Add Financial Record',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF2E2E2E),
                      decoration: InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF137FEC),
                          ),
                        ),
                      ),
                      items: ['Income', 'Expense']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          selectedType = value ?? 'Income';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _financeAmountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF137FEC),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _financeDateController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Date (YYYY-MM-DD)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF137FEC),
                          ),
                        ),
                      ),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          _financeDateController.text =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _financeDescriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF137FEC),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _submitAddRecord(selectedType),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF137FEC),
                  ),
                  child: const Text('Add Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitAddRecord(String type) async {
    if (_financeAmountController.text.isEmpty ||
        _financeDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/clubs/$_clubId/finance'),
        headers: headers,
        body: json.encode({
          'type': type,
          'amount': double.parse(_financeAmountController.text.trim()),
          'date': _financeDateController.text.trim(),
          'description': _financeDescriptionController.text.isNotEmpty
              ? _financeDescriptionController.text.trim()
              : null,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        await _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record added successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add record: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      print('Error adding record: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        color: const Color(0xFF1E1E1E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCardFromData(Map<String, dynamic> event) {
    // Parse the date to get month and day
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
      'DEC',
    ][eventDate.month - 1];
    String day = eventDate.day.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF137FEC).withOpacity(0.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF137FEC),
                  ),
                ),
                Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${event['venue'] ?? 'No venue'} • ${event['attendees'] ?? 0} attendees',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.alarm, color: Color(0xFF137FEC)),
                tooltip: 'Send Reminder',
                onPressed: () async {
                  final eventId = event['event_id'];
                  if (widget.token == null || eventId == null) return;
                  try {
                    final uri = Uri.parse(
                      '$_apiBaseUrl/api/events/$eventId/remind',
                    );
                    final resp = await http.post(
                      uri,
                      headers: {
                        'Authorization': 'Bearer ${widget.token}',
                        'Content-Type': 'application/json',
                      },
                      body: json.encode({}),
                    );
                    if (resp.statusCode == 201 || resp.statusCode == 200) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminders sent')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed (${resp.statusCode})')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
    bool showViewAll = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF1E1E1E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(children: children),
          ),
          if (showViewAll) ...[
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExecutiveEventsScreen(
                          token: widget.token,
                          clubId: _clubId,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF137FEC),
                    side: BorderSide(color: Colors.grey[800]!),
                  ),
                  child: const Text('View All Events'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final double income;
  final double expense;

  DonutChartPainter({this.income = 0, this.expense = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final total = income + expense;
    final incomeRatio = total > 0 ? income / total : 0.75;

    // Draw background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey[800]!
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke,
    );

    // Draw green arc (income) - proportional to income ratio
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708,
      incomeRatio * 6.283185,
      false,
      Paint()
        ..color = Colors.green
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Draw red arc (expenses) - proportional to expense ratio
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708 + (incomeRatio * 6.283185),
      (1 - incomeRatio) * 6.283185,
      false,
      Paint()
        ..color = Colors.red
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(DonutChartPainter oldDelegate) {
    return oldDelegate.income != income || oldDelegate.expense != expense;
  }
}
