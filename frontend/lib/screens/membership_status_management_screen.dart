import 'package:flutter/material.dart';

class Member {
  final String name;
  final String email;
  final String status;
  bool isSelected;

  Member({
    required this.name,
    required this.email,
    required this.status,
    required this.isSelected,
  });
}

class MembershipStatusManagementScreen extends StatefulWidget {
  @override
  _MembershipStatusManagementScreenState createState() => _MembershipStatusManagementScreenState();
}

class _MembershipStatusManagementScreenState extends State<MembershipStatusManagementScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<Member> _members = [
    Member(
      name: 'Jordan Smith',
      email: 'jordan.smith@university.edu',
      status: 'Active',
      isSelected: true,
    ),
    Member(
      name: 'Alex Johnson',
      email: 'alex.j@university.edu',
      status: 'Inactive',
      isSelected: false,
    ),
    Member(
      name: 'Maria Garcia',
      email: 'm.garcia@university.edu',
      status: 'Active',
      isSelected: true,
    ),
    Member(
      name: 'Chen Wei',
      email: 'chen.wei@university.edu',
      status: 'Active',
      isSelected: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF101922),
      appBar: AppBar(
        backgroundColor: Color(0xFF101922),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Manage Members',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: SizedBox.shrink()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  hintStyle: TextStyle(color: Color(0xFF999999)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF999999)),
                  filled: true,
                  fillColor: Color(0xFF1C2936),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF2C3E50)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF2C3E50)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFF137FEC)),
                  ),
                ),
              ),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Status: All', _selectedFilter == 'All', () {
                    setState(() => _selectedFilter = 'All');
                  }),
                  SizedBox(width: 8),
                  _buildFilterChip('Status: Active', _selectedFilter == 'Active', () {
                    setState(() => _selectedFilter = 'Active');
                  }),
                  SizedBox(width: 8),
                  _buildFilterChip('Status: Inactive', _selectedFilter == 'Inactive', () {
                    setState(() => _selectedFilter = 'Inactive');
                  }),
                  SizedBox(width: 8),
                  _buildSortChip('Sort by: Name', () {}),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Member List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView.builder(
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  return _buildMemberItem(_members[index]);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF137FEC),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Add new member')),
          );
        },
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF137FEC).withOpacity(0.2) : Color(0xFF1C2936),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Color(0xFF137FEC) : Color(0xFF2C3E50),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Color(0xFF137FEC) : Color(0xFF999999),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Color(0xFF1C2936),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF2C3E50)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.expand_more, size: 18, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(Member member) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1C2936),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2C3E50)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[700],
            ),
            child: Icon(Icons.person, color: Colors.grey[600], size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  member.email,
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 12,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: member.status == 'Active'
                        ? Color(0xFF22C55E).withOpacity(0.2)
                        : Color(0xFF9CA3AF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    member.status,
                    style: TextStyle(
                      color: member.status == 'Active'
                          ? Color(0xFF86EFAC)
                          : Color(0xFF9CA3AF),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                member.isSelected = !member.isSelected;
              });
            },
            child: Container(
              width: 51,
              height: 31,
              decoration: BoxDecoration(
                color: member.isSelected ? Color(0xFF137FEC) : Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedAlign(
                    duration: Duration(milliseconds: 200),
                    alignment: member.isSelected
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
