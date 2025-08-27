import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../components/three_dots_menu.dart';
import 'choose_test_screen.dart';

class UserProfileScreen extends StatelessWidget {
  final User user;

  const UserProfileScreen({super.key, required this.user});

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
                      horizontal: 38.0,
                      vertical: 27.0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          user.username.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Container(width: 135, height: 1, color: Colors.white),
                        const SizedBox(height: 60),

                        // Run Test Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChooseTestScreen(user: user),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007340),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'RUN TEST',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Users Report Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to users report
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007340),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'USERS REPORT',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Delete User Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Delete user functionality
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007340),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'DELETE USER',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
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
                  Icon(Icons.fitness_center, color: Colors.yellow, size: 30),
                  Icon(
                    Icons.insert_chart_outlined_rounded,
                    color: Colors.yellow,
                    size: 30,
                  ),
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
