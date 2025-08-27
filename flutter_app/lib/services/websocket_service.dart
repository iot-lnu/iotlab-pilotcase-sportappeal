import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'backend_config.dart';

/// Optional WebSocket service for true real-time loadcell data streaming
/// Use this instead of polling for millisecond-level updates
class WebSocketService with ChangeNotifier {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  Map<String, dynamic> _latestReading = {};
  final List<Map<String, dynamic>> _recentReadings = [];
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  Map<String, dynamic> get latestReading => _latestReading;
  List<Map<String, dynamic>> get recentReadings => _recentReadings;

  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_isConnected || _isConnecting) return;

    _isConnecting = true;
    notifyListeners();

    try {
      // Auto-detect backend URL if not already detected
      if (!BackendConfig.isDetected) {
        await BackendConfig.autoDetectBackend();
      }

      final wsUrl = BackendConfig.wsUrl;
      debugPrint('Connecting to WebSocket: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Send registration message as Flutter client
      _channel?.sink.add(jsonEncode({'type': 'flutter'}));

      // Listen for messages
      _subscription = _channel?.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDisconnected,
      );

      _isConnected = true;
      _isConnecting = false;
      debugPrint('WebSocket connected successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _onMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      debugPrint('WebSocket received: ${data.toString().substring(0, 100)}...');

      // Handle sensor data
      if (data['samples'] != null) {
        final samples = data['samples'] as List;

        for (var sample in samples) {
          final reading = {
            'left': sample['l'] ?? 0,
            'right': sample['r'] ?? 0,
            'timestamp': sample['t'] ?? DateTime.now().millisecondsSinceEpoch,
          };

          _latestReading = reading;
          _recentReadings.add(reading);

          // Keep only last 1000 readings to prevent memory issues
          if (_recentReadings.length > 1000) {
            _recentReadings.removeAt(0);
          }
        }

        notifyListeners();
      }

      // Handle other message types
      if (data['test_status'] != null) {
        debugPrint('Test status: ${data['test_status']}');
      }
    } catch (e) {
      debugPrint('Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _onError(error) {
    debugPrint('WebSocket error: $error');
    _isConnected = false;
    notifyListeners();
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _onDisconnected() {
    debugPrint('WebSocket disconnected');
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
    _scheduleReconnect();
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected && !_isConnecting) {
        debugPrint('Attempting WebSocket reconnection...');
        connect();
      }
    });
  }

  /// Send start test command via WebSocket
  void startTest() {
    if (_isConnected) {
      _channel?.sink.add(jsonEncode({'cmd': 'start'}));
      debugPrint('Sent start command via WebSocket');
    }
  }

  /// Send stop test command via WebSocket
  void stopTest() {
    if (_isConnected) {
      _channel?.sink.add(jsonEncode({'cmd': 'stop'}));
      debugPrint('Sent stop command via WebSocket');
    }
  }

  /// Send generic command via WebSocket
  void sendCommand(String command) {
    if (_isConnected) {
      _channel?.sink.add(jsonEncode({'cmd': command}));
      debugPrint('Sent command via WebSocket: $command');
    }
  }

  /// Get readings from the last N seconds
  List<Map<String, dynamic>> getReadingsFromLast(int seconds) {
    final cutoffTime = DateTime.now().millisecondsSinceEpoch - (seconds * 1000);
    return _recentReadings.where((reading) {
      final timestamp = reading['timestamp'] as int;
      return timestamp >= cutoffTime;
    }).toList();
  }

  /// Get readings count from current session
  int get currentSessionSampleCount => _recentReadings.length;

  /// Clear session data
  void clearSession() {
    _recentReadings.clear();
    _latestReading = {};
    notifyListeners();
  }

  /// Disconnect from WebSocket
  void disconnect() {
    debugPrint('Disconnecting WebSocket...');
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close(status.goingAway);
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Helper extension for easy data access
extension WebSocketServiceData on WebSocketService {
  /// Get L sensor value
  double get leftValue => (latestReading['left'] ?? 0).toDouble();

  /// Get R sensor value
  double get rightValue => (latestReading['right'] ?? 0).toDouble();

  /// Get latest timestamp
  int get latestTimestamp => latestReading['timestamp'] ?? 0;

  /// Check if we have recent data (within last 5 seconds)
  bool get hasRecentData {
    if (latestReading.isEmpty) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    final lastUpdate = latestTimestamp;
    return (now - lastUpdate) < 5000; // 5 seconds
  }
}
