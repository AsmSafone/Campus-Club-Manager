import 'package:flutter/material.dart';
import 'package:frontend/screens/admin/admin_club_details_screen.dart';
import 'package:frontend/screens/admin/admin_user_role_assignment_screen.dart';
import 'package:frontend/screens/admin/club_management_for_admins_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDashboardScreen extends StatefulWidget {
  final String? token;
  final Map<String, dynamic>? user;
  const AdminDashboardScreen({Key? key, this.token, this.user})
    : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedView = 'Clubs';
  final TextEditingController _searchController = TextEditingController();

  // Club form controllers
  final TextEditingController _clubNameController = TextEditingController();
  final TextEditingController _clubDescriptionController =
      TextEditingController();
  final TextEditingController _clubFoundedDateController =
      TextEditingController();

  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _filteredClubs = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];

  Map<String, dynamic>? _stats;

  bool _isLoading = true;
  String? _errorMessage;

  // final String _apiBaseUrl = 'http://localhost:3000';
  final String _apiBaseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _clubNameController.dispose();
    _clubDescriptionController.dispose();
    _clubFoundedDateController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterData();
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (_selectedView == 'Clubs') {
        _filteredClubs = _clubs
            .where((club) => club['name'].toLowerCase().contains(query))
            .toList();
      } else {
        _filteredUsers = _users
            .where(
              (user) =>
                  user['name'].toLowerCase().contains(query) ||
                  user['role'].toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (widget.token == null || widget.token!.isEmpty) {
        print('DEBUG: Token is null or empty: ${widget.token}');
        setState(() {
          _errorMessage =
              'No authentication token available. Please login again.';
          _isLoading = false;
        });
        return;
      }

      print('DEBUG: Token: ${widget.token}');

      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      print('DEBUG: Headers: $headers');

      // Fetch stats, clubs, and users in parallel
      final results = await Future.wait([
        _fetchStats(headers),
        _fetchClubs(headers),
        _fetchUsers(headers),
      ]);

      print(
        'DEBUG: Results received - Stats: ${results[0]}, Clubs: ${results[1]}, Users: ${results[2]}',
      );

      setState(() {
        _stats = results[0] as Map<String, dynamic>?;
        _clubs = results[1] as List<Map<String, dynamic>>;
        _users = results[2] as List<Map<String, dynamic>>;
        _filteredClubs = _clubs;
        _filteredUsers = _users;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error loading dashboard data: $e');
      setState(() {
        _errorMessage = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchStats(Map<String, String> headers) async {
    try {
      print('DEBUG: Fetching stats from $_apiBaseUrl/api/admin/stats');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/admin/stats'),
        headers: headers,
      );

      print('DEBUG: Stats response status: ${response.statusCode}');
      print('DEBUG: Stats response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to load stats: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG: Error fetching stats: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchClubs(
    Map<String, String> headers,
  ) async {
    try {
      print('DEBUG: Fetching clubs from $_apiBaseUrl/api/clubs/list');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/clubs/list'),
        headers: headers,
      );

      print('DEBUG: Clubs response status: ${response.statusCode}');
      print('DEBUG: Clubs response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (club) => {
                'club_id': club['club_id'],
                'name': club['name'],
                'members': club['members_count'],
                'status': club['status'],
              },
            )
            .toList();
      } else {
        throw Exception(
          'Failed to load clubs: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG: Error fetching clubs: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsers(
    Map<String, String> headers,
  ) async {
    try {
      print('DEBUG: Fetching users from $_apiBaseUrl/api/users/list');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/users/list'),
        headers: headers,
      );

      print('DEBUG: Users response status: ${response.statusCode}');
      print('DEBUG: Users response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map(
              (user) => {
                'user_id': user['user_id'],
                'name': user['name'],
                'role': user['role'],
                'status': user['status'],
              },
            )
            .toList();
      } else {
        throw Exception(
          'Failed to load users: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('DEBUG: Error fetching users: $e');
      rethrow;
    }
  }

  Future<void> _approveClub(int clubId) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/api/clubs/$clubId/approve'),
        headers: headers,
        body: json.encode({'userId': 1}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club approved successfully')),
        );
        _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectClub(int clubId) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/api/clubs/$clubId/reject'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club rejected successfully')),
        );
        _loadDashboardData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddClubModal() {
    _clubNameController.clear();
    _clubDescriptionController.clear();
    _clubFoundedDateController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Club'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _clubNameController,
                  decoration: const InputDecoration(
                    labelText: 'Club Name *',
                    hintText: 'Enter club name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clubDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter club description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _clubFoundedDateController,
                  decoration: InputDecoration(
                    labelText: 'Founded Date (YYYY-MM-DD)',
                    hintText: 'Select date',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          _clubFoundedDateController.text =
                              '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                  readOnly: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _submitCreateClub(),
              child: const Text('Create Club'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitCreateClub() async {
    if (_clubNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Club name is required')));
      return;
    }

    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final body = json.encode({
        'name': _clubNameController.text.trim(),
        'description': _clubDescriptionController.text.trim(),
        'founded_date': _clubFoundedDateController.text.trim(),
      });

      print('DEBUG: Creating club with body: $body');

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/admin/clubs/create'),
        headers: headers,
        body: body,
      );

      print('DEBUG: Create club response status: ${response.statusCode}');
      print('DEBUG: Create club response body: ${response.body}');

      Navigator.pop(context);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Club created successfully')),
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to create club: ${errorData['message'] ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create club: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error creating club: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/auth', (route) => false);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
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
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Clubs',
                                value: (_stats?['totalClubs'] ?? 0).toString(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Active Users',
                                value: (_stats?['activeUsers'] ?? 0).toString(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Pending Approvals',
                                value: (_stats?['pendingApprovals'] ?? 0)
                                    .toString(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Event Sign-ups',
                                value: (_stats?['eventSignups'] ?? 0)
                                    .toString(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search clubs or users...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // View Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                label: Text('Clubs'),
                                value: 'Clubs',
                              ),
                              ButtonSegment(
                                label: Text('Users'),
                                value: 'Users',
                              ),
                            ],
                            selected: {_selectedView},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedView = newSelection.first;
                                _searchController.clear();
                                _filterData();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // List Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _selectedView == 'Clubs'
                        ? _filteredClubs.isEmpty
                              ? const Center(child: Text('No clubs found'))
                              : Column(
                                  children: _filteredClubs.map((club) {
                                    return _buildClubCard(club);
                                  }).toList(),
                                )
                        : _filteredUsers.isEmpty
                        ? const Center(child: Text('No users found'))
                        : Column(
                            children: _filteredUsers.map((user) {
                              return _buildUserCard(user);
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClubModal,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClubCard(Map<String, dynamic> club) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(radius: 24, child: Text(club['name'][0])),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${club['members']} Members',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminClubDetailsScreen(
                          clubId: club['id'],
                          // club: club,
                          token: widget.token,
                        ),
                      ),
                    );
                  },

                  child: const Text('View'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(radius: 24, child: Text(user['name'][0])),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user['role'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user['status'],
                style: const TextStyle(color: Colors.green, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
