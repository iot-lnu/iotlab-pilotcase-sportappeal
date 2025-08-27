import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;
import '../../models/user.dart';
import '../../services/users_data.dart';
import '../../components/three_dots_menu.dart';
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
  final bool _isTestUser = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Create a new user object
      final username = _usernameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;

      developer.log(
        'Creating user: $username / $email / ${password.length} chars / isTest: $_isTestUser',
        name: 'AddUserScreen',
      );

      // Create a new user
      final newUser = User(
        id:
            DateTime.now().millisecondsSinceEpoch
                .toString(), // Simple unique ID
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
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      resizeToAvoidBottomInset: false, // Prevent automatic resizing
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title
                            Text(
                              'ADD USER',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 135,
                              height: 1,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 40),

                            // Username Field
                            TextField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'ENTER USERNAME',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: const Color(0xFF75F94C),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Email Field
                            TextField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'ENTER EMAIL',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: const Color(0xFF75F94C),
                                  ),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 30),

                            // Password Field (Hidden as it's not in the design but needed for functionality)
                            Opacity(
                              opacity: 0,
                              child: TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 80,
                            ), // Fixed height instead of Spacer
                            // Add User Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007340),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'ADD USER',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ), // Add some bottom padding
                          ],
                        ),
                      ),
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
    );
  }
}
