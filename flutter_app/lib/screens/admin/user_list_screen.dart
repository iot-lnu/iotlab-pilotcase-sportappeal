import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user.dart';
import '../../services/users_data.dart';
import '../../components/three_dots_menu.dart';
import 'dart:developer' as developer;

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late List<User> _users;
  bool _isLoading = true;
  final _searchController = TextEditingController();
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when screen becomes visible
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    developer.log(
      'Loading users: ${UsersData.getAllUsers().length} total, ${UsersData.getNonAdminUsers().length} non-admin',
      name: 'UserListScreen',
    );
    // Get users from the global list
    final users = UsersData.getNonAdminUsers();

    setState(() {
      _users = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredUsers = _users;
      });
      return;
    }

    setState(() {
      _filteredUsers =
          _users
              .where(
                (user) =>
                    user.username.toLowerCase().contains(query.toLowerCase()) ||
                    user.email.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    });
  }

  void _deleteUser(String userId) {
    UsersData.deleteUser(userId);
    _loadUsers();
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(user.username),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                  leading: const Icon(Icons.email),
                ),
                ListTile(
                  title: const Text('Role'),
                  subtitle: Text(
                    user.isAdmin ? 'Administrator' : 'Regular User',
                  ),
                  leading: const Icon(Icons.admin_panel_settings),
                ),
                ListTile(
                  title: const Text('Created'),
                  subtitle: Text(
                    '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                  ),
                  leading: const Icon(Icons.calendar_today),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('CLOSE'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button section
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back_ios,
                          color: const Color(0xFF75F94C),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'BACK',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF75F94C),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Menu icon
                  const ThreeDotsMenu(),
                ],
              ),
            ),

            // Main Content Container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1919),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30.0,
                      vertical: 25.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          'ALL USERS',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 135, height: 1, color: Colors.white),
                        const SizedBox(height: 30),

                        // Search Bar
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    Icon(Icons.search, color: Colors.grey),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        onChanged: _filterUsers,
                                        decoration: InputDecoration(
                                          hintText: 'DAVID BECKHAM',
                                          hintStyle: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 14,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              height: 40,
                              width: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF007340),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'SEARCH',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Category Label
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ALL',
                            style: GoogleFonts.montserrat(
                              color: const Color(0xFF75F94C),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Users List
                        Expanded(
                          child:
                              _isLoading
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF75F94C),
                                      ),
                                    ),
                                  )
                                  : _filteredUsers.isEmpty
                                  ? Center(
                                    child: Text(
                                      'No users found',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    itemCount: _filteredUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = _filteredUsers[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10.0,
                                        ),
                                        child: Container(
                                          height: 60,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2C3C34),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 10),
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF75F94C),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.person,
                                                    color: Colors.black,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap:
                                                      () => _showUserDetails(
                                                        user,
                                                      ),
                                                  child: Text(
                                                    user.username.toUpperCase(),
                                                    style:
                                                        GoogleFonts.montserrat(
                                                          color: Colors.white,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          letterSpacing: 1,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap:
                                                    () => _deleteUser(user.id),
                                                child: Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),

                        // Page indicator at the bottom (optional)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: const Color(0xFF75F94C),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 15.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.home, color: Colors.yellow, size: 30),
                  Icon(Icons.person, color: Colors.yellow, size: 30),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF007340),
        onPressed: () async {
          await Navigator.pushNamed(context, '/admin/add-user');
          _loadUsers();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
