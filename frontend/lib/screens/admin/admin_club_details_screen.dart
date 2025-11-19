import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminClubDetailsScreen extends StatefulWidget {
  final String token;
  final int clubId;

  const AdminClubDetailsScreen({Key? key,required this.token, required this.clubId}) : super(key: key);

  @override
  _AdminClubDetailsScreenState createState() => _AdminClubDetailsScreenState();
}

class _AdminClubDetailsScreenState extends State<AdminClubDetailsScreen> {
    final TextEditingController _addMemberEmailController = TextEditingController();
    final TextEditingController _addMemberNameController = TextEditingController();

    void _showAddMemberDialog() {
      _addMemberEmailController.clear();
      _addMemberNameController.clear();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF192734),
          title: const Text('Add Member', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addMemberEmailController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Enter member email',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4A90E2)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addMemberNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Enter member name',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF4A90E2)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: _addMember,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4A90E2)),
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }

    Future<void> _addMember() async {
      final email = _addMemberEmailController.text.trim();
      final name = _addMemberNameController.text.trim();
      if (email.isEmpty || name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email and name are required')));
        return;
      }
      try {
        final headers = {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        };
        final response = await http.post(
          Uri.parse('$_apiBaseUrl/api/clubs/${widget.clubId}/members'),
          headers: headers,
          body: jsonEncode({'email': email, 'name': name}),
        );
        Navigator.pop(context);
        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added successfully')));
          _loadClubDetailsAndMembers();
        } else {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Failed to add member')));
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  final TextEditingController _searchController = TextEditingController();
  final String _apiBaseUrl = 'http://10.0.2.2:3000';

  Map<String, dynamic>? _clubDetails;
  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClubDetailsAndMembers();
    _searchController.addListener(_filterMembers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClubDetailsAndMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final clubId = widget.clubId;
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };
      // Club details
      final clubRes = await http.get(
        Uri.parse('$_apiBaseUrl/api/clubs/$clubId'),
        headers: headers,
      );
      // Members
      final membersRes = await http.get(
        Uri.parse('$_apiBaseUrl/api/clubs/$clubId/members'),
        headers: headers,
      );
      if (clubRes.statusCode == 200 && membersRes.statusCode == 200) {
        final clubData = jsonDecode(clubRes.body);
        final List<dynamic> membersData = jsonDecode(membersRes.body);
        final members = membersData.map((m) => Member.fromJson(m)).toList();
        setState(() {
          _clubDetails = clubData;
          _members = members;
          _filteredMembers = members;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load club or members data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: $e';
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
        _filteredMembers = _members.where((m) => m.name.toLowerCase().contains(query)).toList();
      }
    });
  }

  void _showMemberOptions(Member member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: const Color(0xFF192734),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Change Role', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _changeRole(member);
              },
            ),
            ListTile(
              title: const Text('Remove Member', style: TextStyle(color: Colors.red)),
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

  Future<void> _changeRole(Member member) async {
    final roles = ['President', 'Treasurer', 'Secretary', 'Member'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF192734),
        title: const Text('Change Role', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: roles.map((role) => ListTile(
            title: Text(role, style: const TextStyle(color: Colors.white)),
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
          )).toList(),
        ),
      ),
    );
  }

  Future<void> _updateMemberRole(Member member, String newRole) async {
    try {
      final clubId = widget.clubId;
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };
      final response = await http.put(
        Uri.parse('$_apiBaseUrl/api/clubs/$clubId/members/${member.membershipId}'),
        headers: headers,
        body: jsonEncode({'role': newRole}),
      );
      if (response.statusCode == 200) {
        final index = _members.indexWhere((m) => m.membershipId == member.membershipId);
        if (index != -1) {
          _members[index].role = newRole;
          _filterMembers();
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role updated successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update role')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _confirmRemoveMember(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF192734),
        title: const Text('Remove Member?', style: TextStyle(color: Colors.white)),
        content: Text('Remove ${member.name} from the club?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

  Future<void> _removeMember(Member member) async {
    try {
      final clubId = widget.clubId;
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/api/clubs/$clubId/members/${member.membershipId}'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        setState(() {
          _members.removeWhere((m) => m.membershipId == member.membershipId);
          _filterMembers();
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed successfully')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove member')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
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
                      _clubDetails != null ? 'Manage ${_clubDetails!['name'] ?? 'Club'}' : 'Manage Club',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add),
                    color: Colors.white,
                    onPressed: _showAddMemberDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF137FEC)))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _loadClubDetailsAndMembers, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Club Profile Header
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF192734),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.grey[700],
                                  image: _clubDetails != null && _clubDetails!['logo_url'] != null
                                      ? DecorationImage(
                                          image: NetworkImage(_clubDetails!['logo_url']),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _clubDetails != null && _clubDetails!['logo_url'] == null
                                    ? const Icon(Icons.groups, color: Colors.white, size: 40)
                                    : null,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _clubDetails != null ? (_clubDetails!['name'] ?? 'Club') : 'Club',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${_members.length} Members',
                                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Icon(Icons.search, color: Colors.grey[600]),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Search members by name...',
                                    hintStyle: TextStyle(color: Colors.grey[600]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Member List
                        _filteredMembers.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text('No members found', style: TextStyle(color: Colors.grey[600])),
                                ),
                              )
                            : Column(
                                children: List.generate(
                                  _filteredMembers.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: _buildMemberCard(_filteredMembers[index]),
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
              image: member.avatarUrl != null
                  ? DecorationImage(image: NetworkImage(member.avatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: member.avatarUrl == null
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              _showMemberOptions(member);
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
  final String? avatarUrl;

  Member({
    required this.userId,
    required this.name,
    required this.email,
    required this.membershipId,
    required this.role,
    required this.roleColor,
    required this.joinDate,
    this.avatarUrl,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
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
      avatarUrl: json['avatar_url'],
    );
  }
}
