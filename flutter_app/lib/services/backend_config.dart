import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

/// Smart backend configuration that automatically detects the correct URL
/// based on platform (iOS Simulator, Android Emulator, Physical Device)
class BackendConfig {
  static int get _backendPort => AppConfig.backendPort;
  static Duration get _connectionTimeout =>
      Duration(seconds: AppConfig.connectionTimeoutSeconds);

  // Get backend URL from config
  static String get _configBackendUrl => AppConfig.backendUrl;
  static String get _configBackendHost => AppConfig.backendHost;

  // Get local IP addresses for better Android device support
  static Future<List<String>> get _localIPAddresses async {
    List<String> ips = [];
    try {
      for (NetworkInterface interface in await NetworkInterface.list()) {
        for (InternetAddress addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ips.add(addr.address);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get local IP addresses: $e');
    }
    return ips;
  }

  // Possible backend URLs to try in order of preference
  static Future<List<String>> get _candidateHosts async {
    List<String> hosts = [];

    // Add config-specified URLs first (highest priority)
    if (_configBackendUrl.isNotEmpty) {
      final uri = Uri.tryParse(_configBackendUrl);
      if (uri != null && uri.host.isNotEmpty) {
        hosts.add(uri.host);
      }
    }

    if (_configBackendHost.isNotEmpty) {
      hosts.add(_configBackendHost);
    }

    // Add platform-specific defaults
    hosts.addAll([
      '127.0.0.1', // iOS Simulator, macOS local development
      'localhost', // Alternative localhost
      '10.0.2.2', // Android Emulator default gateway
    ]);

    // Add actual local IP addresses (critical for physical Android devices)
    final localIPs = await _localIPAddresses;
    hosts.addAll(localIPs);

    // Add common network gateways for auto-discovery
    hosts.addAll([
      '192.168.1.1', // Common home router gateway
      '192.168.0.1', // Alternative home router gateway
      '192.168.1.100', // Common development machine IP
      '192.168.1.101', // Another common development machine IP
      '192.168.0.100', // Common development machine IP
      '10.0.1.1', // Common office/corporate gateway
      '172.16.0.1', // Private network range gateway
    ]);

    // Remove duplicates while preserving order
    return hosts.toSet().toList();
  }

  static String? _detectedBaseUrl;
  static String? _detectedWsUrl;

  /// Get the detected backend base URL
  static String get baseUrl {
    if (_detectedBaseUrl != null) return _detectedBaseUrl!;

    // Use config URL if specified
    if (_configBackendUrl.isNotEmpty) {
      return _configBackendUrl;
    }

    if (_configBackendHost.isNotEmpty) {
      return 'http://$_configBackendHost:$_backendPort';
    }

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

    // Skip auto-detection if disabled in config
    if (!AppConfig.autoDetectBackend) {
      debugPrint('Auto-detection disabled in config');
      return false;
    }

    // Get candidate hosts
    List<String> hostsToTry = await _candidateHosts;

    // Platform-specific reordering for better performance
    if (kIsWeb) {
      // Web prefers localhost
      hostsToTry = [
        'localhost',
        '127.0.0.1',
        ...hostsToTry.where((h) => h != 'localhost' && h != '127.0.0.1'),
      ];
    } else if (Platform.isIOS) {
      // iOS Simulator prefers localhost, physical device needs LAN IP
      if (_isSimulator()) {
        hostsToTry = [
          '127.0.0.1',
          'localhost',
          ...hostsToTry.where((h) => h != '127.0.0.1' && h != 'localhost'),
        ];
      }
      // Physical iOS device: keep original order (local IPs first)
    } else if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2, physical device needs LAN IP
      if (_isAndroidEmulator()) {
        hostsToTry = ['10.0.2.2', ...hostsToTry.where((h) => h != '10.0.2.2')];
      }
      // Physical Android device: prioritize local IPs
    }

    // Remove duplicates while preserving order
    hostsToTry = hostsToTry.toSet().toList();

    debugPrint(
      'Testing ${hostsToTry.length} candidate hosts: ${hostsToTry.take(5).join(", ")}${hostsToTry.length > 5 ? "..." : ""}',
    );

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

  /// Check if running on Android Emulator
  static bool _isAndroidEmulator() {
    if (!Platform.isAndroid) return false;

    try {
      // Android emulator typically has these characteristics
      return Platform.environment['ANDROID_EMULATOR'] != null ||
          Platform.environment['EMULATOR'] != null;
    } catch (e) {
      // Fallback: assume emulator if we can't determine
      return false;
    }
  }

  /// Get platform-specific connection info for debugging
  static Future<Map<String, dynamic>> getConnectionInfo() async {
    return {
      'platform': _getPlatformName(),
      'isSimulator': kIsWeb ? false : (Platform.isIOS ? _isSimulator() : false),
      'isAndroidEmulator':
          kIsWeb ? false : (Platform.isAndroid ? _isAndroidEmulator() : false),
      'detectedBaseUrl': _detectedBaseUrl,
      'detectedWsUrl': _detectedWsUrl,
      'fallbackBaseUrl': baseUrl,
      'fallbackWsUrl': wsUrl,
      'configBackendUrl': _configBackendUrl,
      'configBackendHost': _configBackendHost,
      'autoDetectEnabled': AppConfig.autoDetectBackend,
      'candidateHosts': await _candidateHosts,
      'localIPs': await _localIPAddresses,
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
