import '../models/user.dart';

// A global class to store users in memory
class UsersData {
  static final List<User> _users = [];

  // Initialize with demo users
  static void initializeDemoUsers() {
    if (_users.isEmpty) {
      // Add admin user
      _users.add(
        User(
          id: 'admin_001',
          username: 'Jesper',
          email: 'jesper@lnu.se',
          isAdmin: true,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
      );

      // Add regular user
      _users.add(
        User(
          id: 'user_001',
          username: 'TestUser',
          email: 'test@example.com',
          isAdmin: false,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      );
    }
  }

  /// Check if demo users exist
  static bool hasDemoUsers() {
    return _users.any((user) => user.email == 'jesper@lnu.se');
  }

  /// Get demo admin user credentials for reference
  static Map<String, String> getDemoAdminCredentials() {
    return {
      'email': 'jesper@lnu.se',
      'password': '1234567890',
      'username': 'Jesper',
      'isAdmin': 'true',
    };
  }

  static void addUser(User user) {
    // Security: Users created through admin dashboard are regular users
    // Users from home page registration keep their admin role
    // Only Jesper can have admin rights initially
    if (user.email.toLowerCase() != 'jesper@lnu.se') {
      // For non-Jesper users, check if they're being added through admin dashboard
      // If they don't have admin role already, they're regular users
      // If they have admin role, they came from home page registration
      if (!user.isAdmin) {
        // This is a user created through admin dashboard - ensure they're regular
        user = User(
          id: user.id,
          username: user.username,
          email: user.email,
          isAdmin: false, // Force regular user for admin-created users
          createdAt: user.createdAt,
        );
      }
      // If user.isAdmin is true, they came from home page registration - keep admin role
    }
    _users.add(user);
  }

  static List<User> getAllUsers() {
    return List.from(_users);
  }

  static List<User> getNonAdminUsers() {
    return _users.where((user) => !user.isAdmin).toList();
  }

  static void deleteUser(String userId) {
    _users.removeWhere((user) => user.id == userId);
  }
}
