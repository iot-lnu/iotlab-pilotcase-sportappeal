// Backend Configuration
// This file contains configuration settings for the app
// Values are loaded from .env file at runtime

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Backend URL for the Flask server
  // Leave empty to use auto-detection, or specify your backend URL
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? '';

  // Alternative configuration - specify just the host IP
  // The app will automatically add :5000 port
  static String get backendHost => dotenv.env['BACKEND_HOST'] ?? '';

  // WebSocket URL (optional, will be auto-generated from backendUrl if not specified)
  static String get websocketUrl => dotenv.env['WEBSOCKET_URL'] ?? '';

  // Development mode
  static bool get devMode => dotenv.env['DEV_MODE'] == 'true';

  // Auto-detect backend - if true, app will try to find backend automatically
  static bool get autoDetectBackend =>
      dotenv.env['AUTO_DETECT_BACKEND'] == 'true';

  // Backend port
  static const int backendPort = 5000;

  // Connection timeout in seconds
  static const int connectionTimeoutSeconds = 5;

  // For physical Android devices, you'll need to set backendUrl to your computer's local IP
  // Find your IP with: ipconfig (Windows) or ifconfig (Mac/Linux)
  // Example: backendUrl = 'http://192.168.1.100:5000'

  // Quick configuration based on platform:
  // - iOS Simulator: Use 'http://127.0.0.1:5000' or 'http://localhost:5000'
  // - Android Emulator: Use 'http://10.0.2.2:5000'
  // - Physical Devices: Use 'http://YOUR_LOCAL_IP:5000' (e.g., 'http://192.168.1.100:5000')

  // To find your local IP address:
  // Windows: Open cmd and run 'ipconfig' - look for IPv4 Address
  // Mac/Linux: Open terminal and run 'ifconfig' or 'ip addr' - look for inet address
  // Usually starts with 192.168.x.x or 10.0.x.x
}
