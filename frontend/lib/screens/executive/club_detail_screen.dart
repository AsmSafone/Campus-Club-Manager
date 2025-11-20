import 'package:flutter/material.dart';
import 'package:frontend/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ClubDetailScreen extends StatefulWidget {
  final String? token;
  final int? clubId;

  const ClubDetailScreen({Key? key, this.token, this.clubId}) : super(key: key);

  @override
  _ClubDetailState createState() => _ClubDetailState();
}

class _ClubDetailState extends State<ClubDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final String _apiBaseUrl = ApiConfig.baseUrl;

  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  Map<String, dynamic>? _clubDetails;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClubMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClubMembers() async {
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

      final clubId = widget.clubId ?? 1;
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/clubs/$clubId/members'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final members = data.map((m) => Member.fromJson(m)).toList();

        setState(() {
          _members = members;
          _filteredMembers = members;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load members';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading members: $e';
        _isLoading = false;
      });
    }
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _members;
      } else {
        _filteredMembers = _members
            .where(
              (m) =>
                  m.name.toLowerCase().contains(query) ||
                  m.email.toLowerCase().contains(query),
            )
            .toList();
      }
    });
  }

  Future<void> _changeRole(Member member) async {
    final roles = ['President', 'Treasurer', 'Secretary', 'Member'];
    final currentRoleIndex = roles.indexOf(member.role);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF192734),
        title: const Text('Change Role', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles
              .map(
                (role) => ListTile(
                  title: Text(role, style: TextStyle(color: Colors.white)),
                  leading: Radio<String>(
                    value: role,
                    groupValue: member.role,
                    onChanged: (value) {
                      Navigator.pop(context);
                      if (value != null && value != member.role) {
                        _updateMemberRole(member, value);
                      }
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _updateMemberRole(Member member, String newRole) async {
    try {
      final clubId = widget.clubId ?? 1;
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.put(
        Uri.parse(
          '$_apiBaseUrl/api/clubs/$clubId/members/${member.membershipId}',
        ),
        headers: headers,
        body: jsonEncode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        // Update local state
        final index = _members.indexWhere(
          (m) => m.membershipId == member.membershipId,
        );
        if (index != -1) {
          _members[index].role = newRole;
          _filterMembers();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to update role')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _removeMember(Member member) async {
    try {
      final clubId = widget.clubId ?? 1;
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.delete(
        Uri.parse(
          '$_apiBaseUrl/api/clubs/$clubId/members/${member.membershipId}',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          _members.removeWhere((m) => m.membershipId == member.membershipId);
          _filterMembers();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove member')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showMemberOptions(BuildContext context, Member member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: const Color(0xFF192734),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'Change Role',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _changeRole(member);
              },
            ),
            ListTile(
              title: const Text(
                'Remove Member',
                style: TextStyle(color: Colors.red),
              ),
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveMember(member);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF192734),
        title: const Text(
          'Remove Member?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Remove ${member.name} from the club?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeMember(member);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
            color: const Color(0xFF192734),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Manage Club Members',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF4A90E2)),
                    onPressed: _loadClubMembers,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF137FEC)),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadClubMembers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Members Count
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Total Members: ${_filteredMembers.length}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ),

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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Icon(Icons.search, color: Colors.grey[600]),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Search members by name or email...',
                                hintStyle: TextStyle(color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Members List
                    _filteredMembers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'No members found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(
                              _filteredMembers.length,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildMemberCard(
                                  _filteredMembers[index],
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
        color: const Color(0xFF192734),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(member.roleColor),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  member.email,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Color(member.roleColor).withOpacity(0.2),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    member.role,
                    style: TextStyle(
                      color: Color(member.roleColor),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {
              _showMemberOptions(context, member);
            },
          ),
        ],
      ),
    );
  }
}

class Member {
  final int userId;
  final String name;
  final String email;
  final int membershipId;
  String role;
  final int roleColor;
  final String joinDate;

  Member({
    required this.userId,
    required this.name,
    required this.email,
    required this.membershipId,
    required this.role,
    required this.roleColor,
    required this.joinDate,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    // Map role to color
    final roleToColor = {
      'President': 0xFFF5A623,
      'Treasurer': 0xFF7ED321,
      'Secretary': 0xFF4A90E2,
      'Member': 0xFF9dabb9,
    };

    return Member(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      membershipId: json['membership_id'] ?? 0,
      role: json['role'] ?? 'Member',
      roleColor: roleToColor[json['role']] ?? 0xFF9dabb9,
      joinDate: json['join_date'] ?? '',
    );
  }
}
