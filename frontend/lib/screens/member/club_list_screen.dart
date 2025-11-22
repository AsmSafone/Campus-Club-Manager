import 'package:flutter/material.dart';
import 'package:campus_club_manager/screens/club_executive_club_management_screen.dart';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
            color: const Color(0xFF101922),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Clubs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // keep space on the right to balance the back button
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshClubs,
        child: FutureBuilder<List<Club>>(
          future: _clubsFuture,
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[800]!),
                        color: const Color(0xFF192734),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Icon(Icons.search, color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search for a club...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _sortBy = _sortBy == 'A-Z' ? 'Z-A' : 'A-Z');
                              _filterClubs();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: const Color(0xFF137FEC).withOpacity(0.1),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(
                                children: [
                                  Text(
                                    'Sort: $_sortBy',
                                    style: TextStyle(
                                      color: const Color(0xFF137FEC),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: const Color(0xFF137FEC),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Clubs List
                    _filteredClubs.isEmpty
                        ? Center(child: Text('No clubs found', style: TextStyle(color: Colors.grey[500])))
                        : Column(
                            children: List.generate(
                              _filteredClubs.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: _buildClubCard(_filteredClubs[index]),
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String currentValue, Function(String) onChanged) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
        color: const Color(0xFF192734),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_drop_down,
            color: Colors.grey[600],
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClubDetailsScreen(club: club, token: widget.token),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!),
          color: const Color(0xFF192734),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[600],
              ),
              child: Icon(club.icon, color: Colors.white, size: 28),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    club.category,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    if (widget.token == null) return;
    setState(() => _isLoading = true);
    try {
      final endpoint = '${ApiConfig.baseUrl}/api/clubs/${club.id}/suspend';
      final resp = await http.post(Uri.parse(endpoint), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _refreshClubs();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${club.name} suspended')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to suspend club')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
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
