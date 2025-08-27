import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'backend_config.dart';

class LoadcellApiService with ChangeNotifier {
  // Private variables
  bool _isConnected = false;
  bool _isTesting = false;
  Map<String, dynamic> _latestReading = {};
  Map<String, dynamic> _systemStatus = {};
  List<Map<String, dynamic>> _sessionData = []; // Store sensor history

  // Getters
  bool get isConnected => _isConnected;
  bool get isTesting => _isTesting;
  Map<String, dynamic> get latestReading => _latestReading;
  Map<String, dynamic> get systemStatus => _systemStatus;
  List<Map<String, dynamic>> get sessionData =>
      _sessionData; // Getter for session data

  /// Check if the backend server is available
  Future<bool> checkConnection() async {
    try {
      // Auto-detect backend URL if not already detected
      if (!BackendConfig.isDetected) {
        debugPrint('Auto-detecting backend...');
        await BackendConfig.autoDetectBackend();
      }

      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/status'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _systemStatus = data;
        _isConnected = data['esp_connected'] ?? false;
        _isTesting = data['is_testing'] ?? false;

        debugPrint('Connected to backend: ${BackendConfig.baseUrl}');
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Connection check failed: $e');
      debugPrint('Backend config: ${BackendConfig.getConnectionInfo()}');
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if backend is reachable without starting full connection
  Future<bool> isBackendReachable() async {
    try {
      if (!BackendConfig.isDetected) {
        await BackendConfig.autoDetectBackend();
      }

      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/status'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 2));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Start a new test session
  Future<Map<String, dynamic>> startTest() async {
    try {
      final response = await http
          .post(
            Uri.parse('${BackendConfig.baseUrl}/api/start_test'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        clearSessionData(); // Clear old session data for new test
        _isTesting = true;
        notifyListeners();
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Unknown error'};
      }
    } catch (e) {
      debugPrint('Start test failed: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Stop the current test session
  Future<Map<String, dynamic>> stopTest() async {
    try {
      final response = await http
          .post(
            Uri.parse('${BackendConfig.baseUrl}/api/stop_test'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        _isTesting = false;
        notifyListeners();
        return {
          'success': true,
          'message': data['message'],
          'sample_count': data['sample_count'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Unknown error'};
      }
    } catch (e) {
      debugPrint('Stop test failed: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Get the latest sensor reading
  Future<void> updateLatestReading() async {
    try {
      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/latest_reading'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final newReading = json.decode(response.body);
        _latestReading = newReading;

        // Add to session history for real-time display
        if (newReading.isNotEmpty && newReading['timestamp'] != null) {
          _addToSessionHistory(newReading);
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update latest reading failed: $e');
    }
  }

  /// Add new reading to session history
  void _addToSessionHistory(Map<String, dynamic> reading) {
    // Check if this is a new reading (different timestamp)
    if (_sessionData.isEmpty ||
        _sessionData.last['timestamp'] != reading['timestamp']) {
      _sessionData.add(reading);

      // Keep only last 1000 readings to prevent memory issues
      if (_sessionData.length > 1000) {
        _sessionData.removeAt(0);
      }
    }
  }

  /// Get current session data from backend
  Future<void> updateSessionData() async {
    try {
      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/session_data'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          _sessionData = List<Map<String, dynamic>>.from(data['data']);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Update session data failed: $e');
    }
  }

  /// Clear session data (call when starting new test)
  void clearSessionData() {
    _sessionData.clear();
    notifyListeners();
  }

  /// Get current sensor reading for real-time updates
  Future<Map<String, dynamic>?> getCurrentReading() async {
    try {
      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/current_reading'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get current reading failed: $e');
      return null;
    }
  }

  /// Get raw sensor data in timestamp,value1,value2 format
  Future<Map<String, dynamic>?> getRawData() async {
    try {
      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/raw_data'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get raw data failed: $e');
      return null;
    }
  }

  /// Get raw sensor data in CSV format
  Future<String?> getRawDataCSV() async {
    try {
      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/raw_data_csv'),
            headers: {'Content-Type': 'text/plain'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return response.body;
      }
      return null;
    } catch (e) {
      debugPrint('Get raw data CSV failed: $e');
      return null;
    }
  }

  /// Get current session data
  Future<Map<String, dynamic>?> getSessionData() async {
    try {
      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/session_data'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get session data failed: $e');
      return null;
    }
  }

  /// Get system status
  Future<void> updateSystemStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('${BackendConfig.baseUrl}/api/status'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _systemStatus = data;
        _isConnected = data['esp_connected'] ?? false;
        _isTesting = data['is_testing'] ?? false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Update system status failed: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Handle backend unavailability gracefully
  void handleBackendUnavailable() {
    _isConnected = false;
    _isTesting = false;
    debugPrint('Backend unavailable, stopping all updates');
    notifyListeners();
  }

  /// Start periodic status updates
  void startPeriodicUpdates() async {
    // Check if backend is reachable before starting updates
    final isReachable = await isBackendReachable();
    if (!isReachable) {
      debugPrint('Backend not reachable, skipping periodic updates');
      return;
    }

    // Only start updates if we're actually connected to backend
    if (!_isConnected) {
      return;
    }

    // Update status every 100ms for real-time sensor data
    Future.delayed(const Duration(milliseconds: 100), () async {
      // Check if we should continue updating
      if (!_isConnected) {
        return;
      }

      await updateLatestReading();
      await updateSystemStatus();

      // Update session data every 500ms to get complete history
      if (_sessionData.isEmpty || _sessionData.length % 5 == 0) {
        await updateSessionData();
      }

      // Continue only if still connected
      if (_isConnected) {
        startPeriodicUpdates(); // Schedule next update
      }
    });
  }

  /// Stop periodic updates (call when disposing)
  void stopPeriodicUpdates() {
    _isConnected = false;
    // This will prevent further updates from starting
  }
}
