import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/three_dots_menu.dart';
import '../../components/bottom_navigation.dart';

class SettingsUnderDevelopmentScreen extends StatelessWidget {
  const SettingsUnderDevelopmentScreen({super.key});

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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title
                        Text(
                          'SETTING',
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

                        // Under Development Icon
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007340).withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF007340),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Color(0xFF75F94C),
                            size: 60,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Main Message
                        Text(
                          'UNDER DEVELOPMENT',
                          style: GoogleFonts.montserrat(
                            color: const Color(0xFF75F94C),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Description Text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'The settings page is currently under development. Here you will be able to configure app preferences, notifications, data management, and other system settings.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Action Buttons
                        Column(
                          children: [
                            // Go to Admin Dashboard Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/admin',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF007340),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  'ADMIN DASHBOARD',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 15),

                            // Go Back Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  side: const BorderSide(
                                    color: Color(0xFF75F94C),
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: Text(
                                  'GO BACK',
                                  style: GoogleFonts.montserrat(
                                    color: const Color(0xFF75F94C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            const BottomNavigation(currentRoute: '/admin/settings'),
          ],
        ),
      ),
    );
  }
}
