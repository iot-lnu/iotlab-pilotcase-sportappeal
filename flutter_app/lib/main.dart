import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/add_user_screen.dart';
import 'screens/admin/user_list_screen.dart';
import 'screens/admin/settings_under_development_screen.dart';

import 'screens/user_profile_screen.dart';
import 'screens/realtime_loadcell_dashboard.dart';
import 'screens/test_results_screen.dart';
import 'screens/printable_results_screen.dart';

import 'screens/choose_test_screen.dart';
import 'services/loadcell_api_service.dart';
import 'services/auth_service.dart';
import 'services/users_data.dart';
import 'components/auth_guard.dart';

// Custom HTTP overrides to handle certificate issues - only for native platforms
class MyHttpOverrides extends io.HttpOverrides {
  @override
  io.HttpClient createHttpClient(io.SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (io.X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // Set HTTP overrides for all mobile platforms
  io.HttpOverrides.global = MyHttpOverrides();

  // Initialize demo users
  UsersData.initializeDemoUsers();

  runApp(
    MultiProvider(
      providers: [
        // Remove MQTT service - not needed for loadcell app
        // ChangeNotifierProvider(create: (_) => MqttService()),
        ChangeNotifierProvider(create: (_) => LoadcellApiService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const IdrrottApp(),
    ),
  );
}

class IdrrottApp extends StatelessWidget {
  const IdrrottApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Idrott App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF007340)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/admin': (context) => const AuthGuard(child: AdminDashboard()),
        '/admin/add-user': (context) => const AuthGuard(child: AddUserScreen()),
        '/admin/users': (context) => const AuthGuard(child: UserListScreen()),
        '/choose-test':
            (context) => AuthGuard(
              child: ChooseTestScreen(
                user: ModalRoute.of(context)!.settings.arguments as dynamic,
              ),
            ),
        '/realtime-loadcell':
            (context) => const AuthGuard(child: RealtimeLoadcellDashboard()),
        '/user-profile':
            (context) => AuthGuard(
              child: UserProfileScreen(
                user: ModalRoute.of(context)!.settings.arguments as dynamic,
              ),
            ),
        '/admin/settings':
            (context) =>
                const AuthGuard(child: SettingsUnderDevelopmentScreen()),
        '/test-results':
            (context) => AuthGuard(
              child: TestResultsScreen(
                user: ModalRoute.of(context)!.settings.arguments as dynamic,
              ),
            ),
        '/printable-results':
            (context) => AuthGuard(
              child: PrintableResultsScreen(
                user: ModalRoute.of(context)!.settings.arguments as dynamic,
              ),
            ),
      },
    );
  }
}
