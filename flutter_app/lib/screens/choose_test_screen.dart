import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../components/three_dots_menu.dart';
import '../components/bottom_navigation.dart';
import 'user_test_dashboard.dart';
import 'not_implemented_screen.dart';

class ChooseTestScreen extends StatelessWidget {
  final User user;

  const ChooseTestScreen({super.key, required this.user});

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
                    color: const Color(
                      0xFF1A1919,
                    ), // Dark background like other pages
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
                        // Title - "CHOOSE TEST" with underline
                        Text(
                          'CHOOSE TEST',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(width: 135, height: 1, color: Colors.white),
                        const SizedBox(height: 40),

                        // IMTP Button
                        _buildTestButton(
                          context: context,
                          label: 'IMTP',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => UserTestDashboard(
                                      user: user,
                                      testType: 'IMTP',
                                    ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Iso squat Button
                        _buildTestButton(
                          context: context,
                          label: 'Iso squat',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => NotImplementedScreen(
                                      user: user,
                                      testType: 'Iso squat',
                                    ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Bench press Button
                        _buildTestButton(
                          context: context,
                          label: 'Bench press',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => NotImplementedScreen(
                                      user: user,
                                      testType: 'Bench press',
                                    ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Custom Button
                        _buildTestButton(
                          context: context,
                          label: 'Custom',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => NotImplementedScreen(
                                      user: user,
                                      testType: 'Custom',
                                    ),
                              ),
                            );
                          },
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            const BottomNavigation(currentRoute: '/choose-test'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF007340), // Dark green button like other buttons
        borderRadius: BorderRadius.circular(
          25,
        ), // Rounded corners like other buttons
      ),
      width: double.infinity,
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
