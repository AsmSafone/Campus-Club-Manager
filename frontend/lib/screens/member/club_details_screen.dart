import 'package:flutter/material.dart';
import 'package:frontend/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'club_list_screen.dart';

class ClubDetailsScreen extends StatefulWidget {
  final Club club;
  final String? token;

  const ClubDetailsScreen({Key? key, required this.club, this.token}) : super(key: key);

  @override
  _ClubDetailsScreenState createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Member> _members = [];
  List<Member> _filtered = [];
  bool _loading = false;
  bool _isMember = false;
  bool _actionLoading = false;
  final String _apiBase = ApiConfig.baseUrl;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    _loadMembers();
    _checkMembership();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _members.where((m) => m.name.toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _loadMembers() async {
    if (widget.token == null) return;
    setState(() => _loading = true);
    try {
      final clubId = widget.club.id;
      if (clubId == null) return;
      final resp = await http.get(Uri.parse('$_apiBase/api/clubs/$clubId/members'), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List;
        final members = list.map((m) => Member.fromMap(m)).toList();
        setState(() {
          _members = members;
          _filtered = members;
        });
      }
    } catch (e) {
      // ignore errors for now
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _checkMembership() async {
    if (widget.token == null) return;
    try {
      final clubId = widget.club.id;
      if (clubId == null) return;
      final resp = await http.get(Uri.parse('$_apiBase/api/clubs/$clubId/membership'), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        if (data is Map && (data['member'] != null)) {
          setState(() => _isMember = data['member'] == true);
        }
      }
    } catch (e) {
      // ignore - membership endpoint optional
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    return Scaffold(
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
                        'Club Details',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club header card (icon, name, count)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF162028),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade700,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.group, size: 30, color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(club.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${_members.length} Members', style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF162028),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade800),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search members by name...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14,horizontal: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Members list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? Center(child: Text('No members', style: TextStyle(color: Colors.grey[500])))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final m = _filtered[i];
                            return _buildMemberTile(m);
                          },
                        ),
            ),
            const SizedBox(height: 72),
          ],
        ),
      ),
      // bottom join/leave button
      floatingActionButton: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 220,
            child: ElevatedButton(
              onPressed: _actionLoading ? null : () => _isMember ? _leaveClub() : _joinClub(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMember ? Colors.red : const Color(0xFF137FEC),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _actionLoading
                  ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isMember ? 'Leave Club' : 'Join Club', style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberTile(Member m) {
    final badge = _roleBadge(m.role ?? 'Member');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF162028),
        borderRadius: BorderRadius.circular(8),
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade700,
            backgroundImage: m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
            child: m.avatarUrl == null ? Text(_initials(m.name), style: const TextStyle(color: Colors.white)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Container()
              ],
            ),
          ),
          badge,
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _roleBadge(String role) {
    Color bg;
    switch ((role).toLowerCase()) {
      case 'president':
        bg = const Color(0xFF8B5B00); // amber/dark
        break;
      case 'treasurer':
        bg = const Color(0xFF2E7D32); // green
        break;
      case 'secretary':
        bg = const Color(0xFF1565C0); // blue
        break;
      default:
        bg = const Color(0xFF4B5563); // gray
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(role, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  void _showMemberMenu(Member member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF192734),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Profile'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('View ${member.name}')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Role'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit role for ${member.name}')));
            },
          ),
          ListTile(
            leading: const Icon(Icons.remove_circle, color: Colors.red),
            title: const Text('Remove Member'),
            onTap: () {
              Navigator.pop(context);
              _removeMember(member);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(Member member) async {
    if (widget.token == null || widget.club.id == null) return;
    setState(() => _loading = true);
    try {
      final endpoint = '$_apiBase/api/clubs/${widget.club.id}/members/${member.id}/remove';
      final resp = await http.post(Uri.parse(endpoint), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _loadMembers();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${member.name} removed')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove member')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _joinClub() async {
    if (widget.token == null || widget.club.id == null) return;
    setState(() => _actionLoading = true);
    try {
      final endpoint = '$_apiBase/api/clubs/${widget.club.id}/join';
      final resp = await http.post(Uri.parse(endpoint), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 204) {
        setState(() => _isMember = true);
        await _loadMembers();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You joined ${widget.club.name}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to join club')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  Future<void> _leaveClub() async {
    if (widget.token == null || widget.club.id == null) return;
    setState(() => _actionLoading = true);
    try {
      final endpoint = '$_apiBase/api/clubs/${widget.club.id}/leave';
      final resp = await http.post(Uri.parse(endpoint), headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      });
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        setState(() => _isMember = false);
        await _loadMembers();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You left ${widget.club.name}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to leave club')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _actionLoading = false);
    }
  }
}

class Member {
  final int? id;
  final String name;
  final String? role;
  final String? avatarUrl;

  Member({this.id, required this.name, this.role, this.avatarUrl});

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] ?? map['user_id'] ?? map['member_id'],
      name: map['name'] ?? map['full_name'] ?? '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}',
      role: map['role'] ?? map['membership_role'] ?? 'Member',
      avatarUrl: map['avatar'] ?? map['avatar_url'] ?? map['photo'],
    );
  }
}

class MemberTile extends StatelessWidget {
  final String name;
  final String role;
  final VoidCallback? onMore;

  const MemberTile({Key? key, required this.name, required this.role, this.onMore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(role),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: onMore ?? () {},
      ),
    );
  }
}


