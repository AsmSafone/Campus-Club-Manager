import 'package:campus_club_manager/config/api_config.dart';
import 'package:campus_club_manager/utils/auth_utils.dart';
import 'package:campus_club_manager/screens/admin/admin_club_details_screen.dart';
import 'package:flutter/material.dart';
// import 'package:campus_club_manager/screens/admin/admin_user_role_assignment_screen.dart';
// import 'package:campus_club_manager/screens/admin/club_management_for_admins_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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
  final String _apiBaseUrl = ApiConfig.baseUrl;
  
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _searchController.addListener(_onSearchChanged);
    // Start auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && !_isLoading) {
        _loadDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
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
    final userName = widget.user?['name']?.toString() ?? 'Admin';
    
    return Scaffold(
      backgroundColor: Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF101922),
        elevation: 0,
        toolbarHeight: 0,
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
          : Container(
              color: Color(0xFF101922),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Enhanced Header Section with Gradient (matching member panel)
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
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 24),
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
                                    'Welcome back,',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _loadDashboardData,
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                  tooltip: 'Refresh',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                  onPressed: () async {
                                    await signOutAndNavigate(context);
                                  },
                                  tooltip: 'Logout',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                    padding: EdgeInsets.all(8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Enhanced Stats Section with Gradients
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF137FEC).withOpacity(0.1),
                          Color(0xFF192734).withOpacity(0.3),
                          Color(0xFF101922),
                        ],
                      ),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Clubs',
                                value: (_stats?['totalClubs'] ?? 0).toString(),
                                icon: Icons.group,
                                color: Color(0xFF137FEC),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Active Users',
                                value: (_stats?['activeUsers'] ?? 0).toString(),
                                icon: Icons.people,
                                color: Colors.green,
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
                                icon: Icons.pending_actions,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Event Sign-ups',
                                value: (_stats?['eventSignups'] ?? 0)
                                    .toString(),
                                icon: Icons.event_note,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Enhanced Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF192734),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[800]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search clubs or users...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

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
                            style: SegmentedButton.styleFrom(
                              backgroundColor: Color(0xFF137FEC).withOpacity(0.2),
                              selectedBackgroundColor: Color(0xFF137FEC),
                              selectedForegroundColor: Colors.white,
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey[700]!),
                            ),
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
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32),
                                    child: Text(
                                      'No clubs found',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _filteredClubs.map((club) {
                                    return _buildClubCard(club);
                                  }).toList(),
                                )
                        : _filteredUsers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No users found',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ),
                          )
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClubModal,
        backgroundColor: Color(0xFF137FEC),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Club',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 4,
      ),
    );
  }

  Widget _buildClubCard(Map<String, dynamic> club) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF192734),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdminClubDetailsScreen(
                  clubId: club['club_id'],
                  token: widget.token!,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF137FEC).withOpacity(0.8),
                        Color(0xFF1E3A8A),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF137FEC).withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      club['name'][0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: -0.3,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.people, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '${club['members']} Members',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Guest':
        return Colors.blue;
      case 'Active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final statusColor = _getStatusColor(user['status']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF192734),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[700]!,
                    Colors.grey[900]!,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user['name'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: -0.3,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        user['role'] ?? 'No Role',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                user['status'],
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
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
  final IconData? icon;
  final Color? color;

  const _StatCard({
    required this.title,
    required this.value,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? Color(0xFF137FEC);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color(0xFF192734),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: cardColor,
                size: 20,
              ),
            ),
            SizedBox(height: 12),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
