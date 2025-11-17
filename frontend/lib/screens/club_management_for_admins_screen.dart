import 'package:flutter/material.dart';

class ClubManagementForAdminsScreen extends StatefulWidget {
  @override
  _ClubManagementForAdminsScreenState createState() => _ClubManagementForAdminsScreenState();
}

class _ClubManagementForAdminsScreenState extends State<ClubManagementForAdminsScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  late final List<Club> _clubs = [
    Club(name: 'Creative Writing Club', category: 'Academic', icon: Icons.edit),
    Club(name: 'University Soccer Team', category: 'Sports', icon: Icons.sports_soccer),
    Club(name: 'Coding & Tech Society', category: 'Technology', icon: Icons.computer),
    Club(name: 'Debate Club', category: 'Public Speaking', icon: Icons.mic),
    Club(name: 'Photography Club', category: 'Arts & Culture', icon: Icons.photo_camera),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {},
                  ),
                  Text(
                    'Manage Clubs',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
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
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFF137FEC).withOpacity(0.1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'Sort: A-Z',
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
                    const SizedBox(width: 8),
                    _buildFilterChip('Category'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Status'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Newest'),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Clubs List
              Column(
                children: List.generate(
                  _clubs.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildClubCard(_clubs[index]),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Create new club')),
          );
        },
        backgroundColor: const Color(0xFF137FEC),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
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
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            onPressed: () {
              _showClubMenu(club);
            },
          ),
        ],
      ),
    );
  }

  void _showClubMenu(Club club) {
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
            title: const Text('View Details'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Club'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Approve'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.orange),
            title: const Text('Suspend'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class Club {
  final String name;
  final String category;
  final IconData icon;

  Club({
    required this.name,
    required this.category,
    required this.icon,
  });
}
