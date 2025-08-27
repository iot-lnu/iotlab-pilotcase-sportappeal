// Backend Configuration Example for Developers
//
// This file shows how to configure the backend URL for local development.
// The BackendConfig class will automatically detect the backend in most cases,
// but you can override it for specific development scenarios.

// Method 1: Environment Variable (Recommended)
// Set BACKEND_URL when running flutter:
// flutter run --dart-define=BACKEND_URL=http://192.168.1.100:3000

// Method 2: Find Your Mac's IP Address
// Run this command in terminal:
// ifconfig | grep "inet " | grep -v 127.0.0.1
//
// Examples:
// Home WiFi:    192.168.1.XXX
// Office WiFi:  10.0.1.XXX
// Corporate:    172.16.0.XXX

// Method 3: ESP32 Configuration
// Update your ESP32 main.cpp with your Mac's IP:
// const char* websocket_host = "192.168.1.XXX";  // Your Mac's IP
// const uint16_t websocket_port = 3000;

// The Flutter app will automatically try these in order:
// 1. Environment variable (if set)
// 2. 127.0.0.1 (iOS Simulator)
// 3. 10.0.2.2 (Android Emulator)
// 4. Common router gateways
// 5. Auto-detection by testing connections

class DevelopmentConfig {
  // Uncomment and set your IP for manual override:
  // static const String manualBackendHost = '192.168.1.100';

  static String getQuickSetupInstructions() {
    return '''
Quick Setup for New Developers:

1. Find your Mac's IP:
   ifconfig | grep "inet " | grep -v 127.0.0.1

2. Update ESP32 code (main.cpp):
   const char* websocket_host = "YOUR_MAC_IP";

3. Start backend:
   cd backend && make run

4. Run Flutter app:
   flutter run
   
   Or with specific backend:
   flutter run --dart-define=BACKEND_URL=http://YOUR_MAC_IP:3000

The app will auto-detect the backend in most cases!
''';
  }
}
