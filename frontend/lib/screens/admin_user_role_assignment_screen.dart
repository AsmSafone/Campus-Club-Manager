import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManageUserRolesPage extends StatefulWidget {
  final int? clubId;
  final String? clubName;
  final String? token;
  
  const ManageUserRolesPage({
    Key? key,
    this.clubId,
    this.clubName,
    this.token,
  }) : super(key: key);

  @override
  _ManageUserRolesPageState createState() => _ManageUserRolesPageState();
}

class _ManageUserRolesPageState extends State<ManageUserRolesPage> {
  final TextEditingController _searchController = TextEditingController();
  final String _apiBaseUrl = 'http://10.0.2.2:3000';

  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClubMembers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterMembers();
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMembers = _members
          .where((member) =>
              member['name'].toLowerCase().contains(query) ||
              member['email'].toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _loadClubMembers() async {
    try {
      if (widget.clubId == null || widget.token == null) {
        setState(() {
          _errorMessage = 'Missing club or token information';
          _isLoading = false;
        });
        return;
      }

      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        Uri.parse('$_apiBaseUrl/api/clubs/${widget.clubId}/members'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _members = List<Map<String, dynamic>>.from(
            data.map((member) => {
              'membership_id': member['membership_id'],
              'user_id': member['user_id'],
              'name': member['name'],
              'email': member['email'],
              'role': member['role'],
              'join_date': member['join_date'],
            })
          );
          _filteredMembers = _members;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load club members: ${response.statusCode}';
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

  Future<void> _updateUserRole(Map<String, dynamic> member, String newRole) async {
    try {
      final headers = {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      };

      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/api/clubs/${widget.clubId}/members/${member['user_id']}/role'),
        headers: headers,
        body: json.encode({'role': newRole}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${member['name']}'s role has been updated to $newRole.")),
        );
        _loadClubMembers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clubName != null 
            ? "Manage Roles - ${widget.clubName}" 
            : "Manage User Roles"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // search logic
            },
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
                        onPressed: _loadClubMembers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: "Search by name or email...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 16),
                      Expanded(
                        child: _filteredMembers.isEmpty
                            ? Center(
                                child: Text('No members found'),
                              )
                            : ListView.builder(
                                itemCount: _filteredMembers.length,
                                itemBuilder: (context, index) {
                                  final member = _filteredMembers[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(member["name"] ?? 'Unknown'),
                                      subtitle: Text(member["email"] ?? 'No email'),
                                      trailing: Text(member["role"] ?? 'Member'),
                                      onTap: () {
                                        _showRoleDialog(member);
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  void _showRoleDialog(Map<String, dynamic> member) {
    String? tempRole = member["role"];
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Edit Role for ${member["name"]}"),
              content: DropdownButtonFormField<String>(
                value: tempRole,
                items: ["President", "Secretary", "Member"]
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (value) {
                  setDialogState(() {
                    tempRole = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text("Update Role"),
                  onPressed: () {
                    Navigator.pop(context);
                    if (tempRole != null && tempRole != member["role"]) {
                      _updateUserRole(member, tempRole!);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
