import 'package:flutter/material.dart';
import 'package:campus_club_manager/screens/member/club_details_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class ClubListScreen extends StatefulWidget {
  final String? token;
  final int? clubId;
  const ClubListScreen({super.key, this.token, this.clubId});
  @override
  _ClubListScreenState createState() => _ClubListScreenState();
}

class _ClubListScreenState extends State<ClubListScreen> {
  final TextEditingController _searchController = TextEditingController();
  // Api base URL
  
  late Future<List<Club>> _clubsFuture;
  List<Club> _allClubs = [];
  List<Club> _filteredClubs = [];
  String _sortBy = 'A-Z';
  String _categoryFilter = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _clubsFuture = _fetchClubs();
    _searchController.addListener(_filterClubs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Club>> _fetchClubs() async {
    if (widget.token == null) return [];
    try {
      final resp = await http.get(Uri.parse('${ApiConfig.baseUrl}/api/clubs/list'), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        final clubs = list.map((c) => Club.fromMap(c)).toList();
        setState(() => _allClubs = clubs);
        _filterClubs();
        return clubs;
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  void _filterClubs() {
    final query = _searchController.text.toLowerCase();
    var filtered = _allClubs.where((c) {
      final matchesQuery = c.name.toLowerCase().contains(query);
      final matchesCategory = _categoryFilter.isEmpty || c.category.toLowerCase() == _categoryFilter.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();

    // Sort
    if (_sortBy == 'A-Z') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'Z-A') {
      filtered.sort((a, b) => b.name.compareTo(a.name));
    }

    setState(() => _filteredClubs = filtered);
  }

  Future<void> _refreshClubs() async {
    setState(() => _clubsFuture = _fetchClubs());
    await _clubsFuture;
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
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'All Clubs',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF137FEC),
              onRefresh: _refreshClubs,
              child: FutureBuilder<List<Club>>(
                future: _clubsFuture,
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Color(0xFF137FEC)));
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text(
                            'Error loading clubs',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _clubsFuture = _fetchClubs();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF137FEC),
                            ),
                            child: Text('Retry', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }

                  final clubs = snapshot.data ?? [];
                  final filtered = _filteredClubs.isEmpty && _allClubs.isNotEmpty
                      ? _allClubs
                      : _filteredClubs;

                  return Column(
                    children: [
                      // Search and Filter Bar
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF192734),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[800]!),
                              ),
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Search clubs...',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildFilterButton('A-Z', _sortBy == 'A-Z'),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: _buildFilterButton('Z-A', _sortBy == 'Z-A'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.group_off, size: 64, color: Colors.grey[600]),
                                      SizedBox(height: 16),
                                      Text(
                                        'No clubs found',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: filtered.length,
                                itemBuilder: (ctx, idx) {
                                  final club = filtered[idx];
                                  return _buildClubCard(club);
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = label;
          _filterClubs();
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF137FEC) : Color(0xFF192734),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF137FEC) : Colors.grey[800]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[400],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClubDetailsScreen(club: club, token: widget.token),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[800],
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(club.icon, color: Colors.white70, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF137FEC).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Color(0xFF137FEC).withOpacity(0.3)),
                      ),
                      child: Text(
                        club.category,
                        style: TextStyle(
                          color: Color(0xFF137FEC),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editClub(Club club) async {
    if (widget.token == null) return;
    setState(() => _isLoading = true);
    try {
      // Placeholder: navigate to edit screen or show edit dialog
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit club: ${club.name}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveClub(Club club) async {
    if (widget.token == null) return;
    setState(() => _isLoading = true);
    try {
      final endpoint = '${ApiConfig.baseUrl}/api/clubs/${club.id}/approve';
      final resp = await http.post(Uri.parse(endpoint), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _refreshClubs();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${club.name} approved')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to approve club')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _suspendClub(Club club) async {
    // Endpoint not implemented - suspend functionality removed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Suspend functionality is not available')),
    );
  }
}

class Club {
  final int? id;
  final String name;
  final String category;
  final IconData icon;

  Club({
    this.id,
    required this.name,
    required this.category,
    required this.icon,
  });

  factory Club.fromMap(Map<String, dynamic> map) {
    return Club(
      id: map['id'] ?? map['club_id'] ?? map['clubId'],
      name: map['name'] ?? map['club_name'] ?? '',
      category: map['category'] ?? map['club_category'] ?? 'General',
      icon: _getIconForCategory(map['category'] ?? map['club_category'] ?? 'General'),
    );
  }

  static IconData _getIconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('academic') || lower.contains('writing')) return Icons.edit;
    if (lower.contains('sport') || lower.contains('soccer')) return Icons.sports_soccer;
    if (lower.contains('tech') || lower.contains('coding') || lower.contains('computer')) return Icons.computer;
    if (lower.contains('speak') || lower.contains('debate')) return Icons.mic;
    if (lower.contains('photo') || lower.contains('art')) return Icons.photo_camera;
    return Icons.groups;
  }
}
