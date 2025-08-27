import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Smart backend configuration that automatically detects the correct URL
/// based on platform (iOS Simulator, Android Emulator, Physical Device)
class BackendConfig {
  static const int _backendPort = 5000;
  static const Duration _connectionTimeout = Duration(seconds: 3);

  // Environment-specific backend URL (for development)
  static const String _envBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  // Possible backend URLs to try in order of preference
  static List<String> get _candidateHosts {
    List<String> hosts = [
      '127.0.0.1', // iOS Simulator, macOS local development
      'localhost', // Alternative localhost
      '10.0.2.2', // Android Emulator default gateway
    ];

    // Add environment-specific URL if provided
    if (_envBackendUrl.isNotEmpty) {
      final uri = Uri.tryParse(_envBackendUrl);
      if (uri != null && uri.host.isNotEmpty) {
        hosts.insert(0, uri.host); // Prioritize environment URL
      }
    }

    // Add common network gateways for auto-discovery
    hosts.addAll([
      '192.168.1.1', // Common home router gateway
      '192.168.0.1', // Alternative home router gateway
      '10.0.1.1', // Common office/corporate gateway
      '172.16.0.1', // Private network range gateway
    ]);

    return hosts;
  }

  static String? _detectedBaseUrl;
  static String? _detectedWsUrl;

  /// Get the detected backend base URL
  static String get baseUrl {
    if (_detectedBaseUrl != null) return _detectedBaseUrl!;

    // Fallback based on platform
    if (kIsWeb) {
      return 'http://localhost:$_backendPort';
    } else if (Platform.isIOS) {
      // iOS Simulator can reach localhost directly
      return 'http://127.0.0.1:$_backendPort';
    } else if (Platform.isAndroid) {
      // Android Emulator uses special IP
      return 'http://10.0.2.2:$_backendPort';
    } else {
      return 'http://localhost:$_backendPort';
    }
  }

  /// Get the detected WebSocket URL (efficient direct WebSocket)
  static String get wsUrl {
    if (_detectedWsUrl != null) return _detectedWsUrl!;

    final host = baseUrl.replaceFirst('http://', '').split(':')[0];
    return 'ws://$host:$_backendPort/ws'; // Direct efficient WebSocket
  }

  /// Get Socket.IO URL (for compatibility if needed)
  static String get socketIOUrl {
    final host = baseUrl.replaceFirst('http://', '').split(':')[0];
    return 'ws://$host:$_backendPort/socket.io/?EIO=4&transport=websocket';
  }

  /// Auto-detect the correct backend URL by testing connections
  static Future<bool> autoDetectBackend() async {
    debugPrint('Auto-detecting backend URL...');

    // Platform-specific host order
    List<String> hostsToTry = [];

    if (kIsWeb) {
      hostsToTry = ['localhost', '127.0.0.1'];
    } else if (Platform.isIOS) {
      // iOS Simulator prefers localhost, physical device needs LAN IP
      if (_isSimulator()) {
        hostsToTry = ['127.0.0.1', 'localhost', ..._candidateHosts];
      } else {
        hostsToTry = [..._candidateHosts];
      }
    } else if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2, physical device needs LAN IP
      hostsToTry = ['10.0.2.2', '127.0.0.1', ..._candidateHosts];
    } else {
      hostsToTry = _candidateHosts;
    }

    // Remove duplicates while preserving order
    hostsToTry = hostsToTry.toSet().toList();

    for (String host in hostsToTry) {
      final testUrl = 'http://$host:$_backendPort';
      debugPrint('Testing: $testUrl');

      if (await _testConnection(testUrl)) {
        _detectedBaseUrl = testUrl;
        _detectedWsUrl = 'ws://$host:$_backendPort/ws'; // Efficient WebSocket

        debugPrint('Backend detected at: $_detectedBaseUrl');
        debugPrint('Efficient WebSocket URL: $_detectedWsUrl');

        return true;
      }
    }

    debugPrint('No backend found. Using fallback: $baseUrl');
    return false;
  }

  /// Test if a backend URL is accessible
  static Future<bool> _testConnection(String baseUrl) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/status'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(_connectionTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint(
          '$baseUrl responded: ${data.toString().substring(0, 50)}...',
        );
        return true;
      }
    } catch (e) {
      debugPrint('$baseUrl failed: ${e.toString().substring(0, 50)}...');
    }

    return false;
  }

  /// Check if running on iOS Simulator
  static bool _isSimulator() {
    if (!Platform.isIOS) return false;

    // This is a heuristic - iOS Simulator typically has these characteristics
    try {
      // On simulator, certain directories exist that don't on physical devices
      return Platform.environment['SIMULATOR_DEVICE_NAME'] != null ||
          Platform.environment['SIMULATOR_ROOT'] != null;
    } catch (e) {
      // Fallback detection
      return false;
    }
  }

  /// Get platform-specific connection info for debugging
  static Map<String, dynamic> getConnectionInfo() {
    return {
      'platform': _getPlatformName(),
      'isSimulator': kIsWeb ? false : (Platform.isIOS ? _isSimulator() : false),
      'detectedBaseUrl': _detectedBaseUrl,
      'detectedWsUrl': _detectedWsUrl,
      'fallbackBaseUrl': baseUrl,
      'fallbackWsUrl': wsUrl,
      'candidateHosts': _candidateHosts,
    };
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Reset detection (useful for retrying)
  static void resetDetection() {
    _detectedBaseUrl = null;
    _detectedWsUrl = null;
  }

  /// Get current status
  static bool get isDetected => _detectedBaseUrl != null;
}
