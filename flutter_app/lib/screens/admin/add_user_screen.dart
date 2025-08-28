import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../../models/user.dart';
import '../../services/users_data.dart';
import '../../components/standard_page_layout.dart';
import '../../components/profile_icon.dart';
import '../../components/custom_text_field.dart';
import '../add_user_success_screen.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Get form values and trim whitespace
      final username = _usernameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Check if user already exists
      final existingUsers = UsersData.getAllUsers();
      final userExists = existingUsers.any(
        (user) =>
            user.email.toLowerCase() == email.toLowerCase() ||
            user.username.toLowerCase() == username.toLowerCase(),
      );

      if (userExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User with this email or username already exists!',
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      developer.log(
        'Creating user: $username / $email / ${password.length} chars',
        name: 'AddUserScreen',
      );

      // Create a new user
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        email: email,
        isAdmin: false, // Regular users are not admins
        createdAt: DateTime.now(),
      );

      // Add the user to the global list
      UsersData.addUser(newUser);

      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AddUserSuccessScreen(user: newUser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'ADD USER',
      currentRoute: '/admin/add-user',
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Profile Icon (same as login page)
          const ProfileIcon(size: 80),

          const SizedBox(height: 40),

          // Form Fields Section (same as login page)
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Username Field (using CustomTextField like login)
                CustomTextField(
                  label: 'ENTER USERNAME',
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (value.trim().length > 20) {
                      return 'Username must be less than 20 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Email Field (using CustomTextField like login)
                CustomTextField(
                  label: 'ENTER EMAIL',
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an email';
                    }
                    // Use same email validation as AuthService
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // Password Field (using CustomTextField like login)
                CustomTextField(
                  label: 'ENTER PASSWORD',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // Add User Button (same width as login button)
          SizedBox(
            width: 227,
            child: ElevatedButton(
              onPressed: _submitForm,
              style: AppButtonStyles.primaryButton,
              child: Text('ADD USER', style: AppTextStyles.buttonText),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
