import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'users_data.dart';

class AuthService with ChangeNotifier {
  User? _currentUser;
  bool _isLoggedIn = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Check if user is logged in
  bool checkLoginStatus() {
    return _isLoggedIn && _currentUser != null;
  }

  /// Validate user input for registration
  Map<String, String?> validateRegistration({
    required String username,
    required String email,
    required String password,
  }) {
    Map<String, String?> errors = {};

    // Username validation
    if (username.trim().isEmpty) {
      errors['username'] = 'Username cannot be empty';
    } else if (username.trim().length < 3) {
      errors['username'] = 'Username must be at least 3 characters';
    } else if (username.trim().length > 20) {
      errors['username'] = 'Username must be less than 20 characters';
    }

    // Email validation
    if (email.trim().isEmpty) {
      errors['email'] = 'Email cannot be empty';
    } else if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email.trim())) {
      errors['email'] = 'Please enter a valid email address';
    }

    // Password validation
    if (password.isEmpty) {
      errors['password'] = 'Password cannot be empty';
    } else if (password.length < 6) {
      errors['password'] = 'Password must be at least 6 characters';
    } else if (password.length > 50) {
      errors['password'] = 'Password must be less than 50 characters';
    }

    return errors;
  }

  /// Validate user input for login
  Map<String, String?> validateLogin({
    required String email,
    required String password,
  }) {
    Map<String, String?> errors = {};

    // Email validation
    if (email.trim().isEmpty) {
      errors['email'] = 'Email cannot be empty';
    } else if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email.trim())) {
      errors['email'] = 'Please enter a valid email address';
    }

    // Password validation
    if (password.isEmpty) {
      errors['password'] = 'Password cannot be empty';
    }

    return errors;
  }

  /// Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      final validationErrors = validateRegistration(
        username: username,
        email: email,
        password: password,
      );

      if (validationErrors.isNotEmpty) {
        return {
          'success': false,
          'errors': validationErrors,
          'message': 'Please fix the validation errors',
        };
      }

      // Check if user already exists
      final existingUsers = UsersData.getAllUsers();
      final userExists = existingUsers.any(
        (user) =>
            user.email.toLowerCase() == email.trim().toLowerCase() ||
            user.username.toLowerCase() == username.trim().toLowerCase(),
      );

      if (userExists) {
        return {
          'success': false,
          'message': 'User with this email or username already exists',
        };
      }

      // Create new user - Users from home page registration get admin role
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username.trim(),
        email: email.trim().toLowerCase(),
        isAdmin: true, // Home page registrations get admin role
        createdAt: DateTime.now(),
      );

      // Add user to storage
      UsersData.addUser(newUser);

      // Auto-login after successful registration
      await loginUser(email: email.trim(), password: password);

      return {
        'success': true,
        'message': 'User registered successfully',
        'user': newUser,
      };
    } catch (e) {
      debugPrint('Registration failed: $e');
      return {'success': false, 'message': 'Registration failed: $e'};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Validate input
      final validationErrors = validateLogin(email: email, password: password);

      if (validationErrors.isNotEmpty) {
        return {
          'success': false,
          'errors': validationErrors,
          'message': 'Please fix the validation errors',
        };
      }

      // Check if user exists
      final existingUsers = UsersData.getAllUsers();
      var user = existingUsers.firstWhere(
        (user) => user.email.toLowerCase() == email.trim().toLowerCase(),
        orElse:
            () => User(
              id: '',
              username: '',
              email: '',
              isAdmin: false,
              createdAt: DateTime.now(),
            ),
      );

      if (user.id.isEmpty) {
        return {
          'success': false,
          'message': 'User not found. Please register first.',
        };
      }

      // Demo user authentication
      if (email.trim().toLowerCase() == 'jesper@lnu.se') {
        // For the demo admin user, check the specific password
        if (password != '1234567890') {
          return {
            'success': false,
            'message': 'Incorrect password for demo admin user.',
          };
        }
        // Ensure Jesper has admin rights
        user = User(
          id: user.id,
          username: user.username,
          email: user.email,
          isAdmin: true, // Force admin rights for Jesper
          createdAt: user.createdAt,
        );
      } else {
        // For all other users from home page, ensure they have admin rights
        user = User(
          id: user.id,
          username: user.username,
          email: user.email,
          isAdmin: true, // Force admin rights for home page users
          createdAt: user.createdAt,
        );
      }
      // For other users, accept any password (demo purposes)
      // In a real app, you'd verify password hash here

      // Set current user and login status
      _currentUser = user;
      _isLoggedIn = true;
      notifyListeners();

      return {'success': true, 'message': 'Login successful', 'user': user};
    } catch (e) {
      debugPrint('Login failed: $e');
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  /// Logout user
  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  /// Check if user can access admin features
  bool canAccessAdmin() {
    return _isLoggedIn && _currentUser?.isAdmin == true;
  }

  /// Check if user can access protected routes
  bool canAccessProtectedRoute() {
    return _isLoggedIn && _currentUser != null;
  }

  /// Get demo user credentials for testing
  Map<String, String> getDemoCredentials() {
    return {
      'admin_email': 'jesper@lnu.se',
      'admin_password': '1234567890',
      'admin_username': 'Jesper',
      'regular_email': 'test@example.com',
      'regular_password': 'any_password', // For demo purposes
      'regular_username': 'TestUser',
    };
  }

  /// Check if current user is the demo admin
  bool get isDemoAdmin {
    return _currentUser?.email == 'jesper@lnu.se' &&
        _currentUser?.isAdmin == true;
  }
}
