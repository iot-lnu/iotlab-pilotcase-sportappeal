import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../services/backend_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';

class RealtimeLoadcellDashboard extends StatefulWidget {
  const RealtimeLoadcellDashboard({super.key});

  @override
  State<RealtimeLoadcellDashboard> createState() =>
      _RealtimeLoadcellDashboardState();
}

class _RealtimeLoadcellDashboardState extends State<RealtimeLoadcellDashboard> {
  final WebSocketService _wsService = WebSocketService();
  final Logger _logger = Logger('RealtimeLoadcellDashboard');
  bool _isTestRunning = false;
  final List<Map<String, dynamic>> _testData = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connectToWebSocket() async {
    await _wsService.connect();
    _wsService.addListener(_onDataUpdate);
  }

  void _onDataUpdate() {
    if (mounted) {
      _logger.info(
        '📊 WebSocket data update: ${_wsService.recentReadings.length} readings',
      );
      _logger.info('📊 Latest reading: ${_wsService.latestReading}');
      _logger.info('📊 Test data: ${_testData.length} samples');

      setState(() {
        // Auto-scroll to bottom when new data arrives
        if (_scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      });
    }
  }

  Future<void> _startTest() async {
    try {
      _logger.info('🟢 Starting test...');

      // Send start command to backend
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}/api/start_test'),
        headers: {'Content-Type': 'application/json'},
      );

      _logger.info(
        '🟢 Backend response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _isTestRunning = true;
          _testData.clear();
        });

        // Clear WebSocket data and start fresh
        _wsService.clearSession();

        // Send start command via WebSocket
        _wsService.sendCommand('start');

        _logger.info('🟢 Test started successfully!');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test started successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to start test: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('🔴 Error starting test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopTest() async {
    try {
      _logger.info('🔴 Stopping test...');

      // Send stop command to backend
      final response = await http.post(
        Uri.parse('${BackendConfig.baseUrl}/api/stop_test'),
        headers: {'Content-Type': 'application/json'},
      );

      _logger.info(
        '🔴 Backend response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        setState(() {
          _isTestRunning = false;
        });

        // Send stop command via WebSocket
        _wsService.sendCommand('stop');

        // Clear WebSocket data to stop streaming
        _wsService.clearSession();

        // Get final session data
        final sessionResponse = await http.get(
          Uri.parse('${BackendConfig.baseUrl}/api/session_data'),
        );

        _logger.info('🔴 Session data response: ${sessionResponse.statusCode}');

        if (sessionResponse.statusCode == 200) {
          final sessionData = jsonDecode(sessionResponse.body);
          _logger.info(
            '🔴 Session data: ${sessionData.toString().substring(0, 200)}...',
          );
          if (sessionData['data'] != null) {
            setState(() {
              _testData.addAll(
                List<Map<String, dynamic>>.from(sessionData['data']),
              );
            });
            _logger.info(
              '🔴 Added ${sessionData['data'].length} samples to test data',
            );
          }
        }

        _logger.info('🔴 Test stopped successfully!');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test stopped successfully!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        throw Exception('Failed to stop test: ${response.statusCode}');
      }
    } catch (e) {
      _logger.severe('🔴 Error stopping test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping test: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDataRow(Map<String, dynamic> data, int index) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.grey[900] : Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          // Index
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Data values
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSensorValue(
                        'L',
                        data['left'] ?? 0,
                        Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSensorValue(
                        'R',
                        data['right'] ?? 0,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Time: ${timestamp.toString().substring(11, 19)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorValue(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSensorValue(String label, dynamic value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.toString(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveStreamTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Stream Header
          Row(
            children: [
              const Icon(Icons.sensors, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Real-Time Sensor Stream',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withAlpha(128)),
                ),
                child: Text(
                  '${_wsService.recentReadings.length} samples',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Current Live Reading Display
          if (_wsService.recentReadings.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withAlpha(128)),
              ),
              child: Column(
                children: [
                  Text(
                    'Latest Reading',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildCurrentReadingCard(
                          'L',
                          _wsService.recentReadings.last['left'] ?? 0,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCurrentReadingCard(
                          'R',
                          _wsService.recentReadings.last['right'] ?? 0,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Last Update: ${_formatTimestamp(_wsService.recentReadings.last['timestamp'])}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Real-Time Sensor History
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Real-Time Sensor History',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(51),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withAlpha(128)),
                ),
                child: Text(
                  'Live',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Real-time sensor history list
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: _buildRealTimeHistoryList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestDataTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Test Data Header
          Row(
            children: [
              const Icon(Icons.history, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Test Session Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withAlpha(128)),
                ),
                child: Text(
                  '${_testData.length} samples',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test Data List
          Expanded(
            child:
                _testData.isEmpty
                    ? const Center(
                      child: Text(
                        'No test data yet. Complete a test to see results.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      itemCount: _testData.length,
                      itemBuilder: (context, index) {
                        return _buildDataRow(_testData[index], index);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Header
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.purple, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Data Statistics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistics Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Samples',
                          '${_testData.length + _wsService.recentReadings.length}',
                          Icons.data_usage,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Test Data',
                          '${_testData.length}',
                          Icons.history,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Live Data',
                          '${_wsService.recentReadings.length}',
                          Icons.timeline,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Status',
                          _isTestRunning ? 'RUNNING' : 'IDLE',
                          Icons.play_circle,
                          _isTestRunning ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Data Range Info
                  if (_testData.isNotEmpty ||
                      _wsService.recentReadings.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Range',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildRangeInfo('L', _getSensorRange('left')),
                          const SizedBox(height: 8),
                          _buildRangeInfo('R', _getSensorRange('right')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRangeInfo(String sensorName, Map<String, dynamic> range) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            sensorName,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'Min: ${range['min']}, Max: ${range['max']}, Avg: ${range['avg'].toStringAsFixed(1)}',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getSensorRange(String sensorKey) {
    final allData = [..._testData, ..._wsService.recentReadings];
    if (allData.isEmpty) {
      return {'min': 0, 'max': 0, 'avg': 0.0};
    }

    final values =
        allData
            .map((data) => (data[sensorKey] ?? 0).toDouble())
            .where((value) => value != 0)
            .toList();

    if (values.isEmpty) {
      return {'min': 0, 'max': 0, 'avg': 0.0};
    }

    return {
      'min': values.reduce((a, b) => a < b ? a : b).toInt(),
      'max': values.reduce((a, b) => a > b ? a : b).toInt(),
      'avg': values.reduce((a, b) => a + b) / values.length,
    };
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return date.toString().substring(11, 19); // HH:mm:ss
  }

  Widget _buildCurrentReadingCard(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeHistoryList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _wsService.recentReadings.length,
      itemBuilder: (context, index) {
        final reading = _wsService.recentReadings[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Row(
            children: [
              Text(
                '#${index + 1}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    _buildCompactSensorValue(
                      'L',
                      reading['left'] ?? 0,
                      Colors.red,
                    ),
                    const SizedBox(width: 16),
                    _buildCompactSensorValue(
                      'R',
                      reading['right'] ?? 0,
                      Colors.green,
                    ),
                  ],
                ),
              ),
              Text(
                _formatTimestamp(reading['timestamp']),
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Real-time Loadcell Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Connection status
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  _wsService.isConnected
                      ? Colors.green.withAlpha(51)
                      : Colors.red.withAlpha(51),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _wsService.isConnected ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _wsService.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: _wsService.isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _wsService.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _wsService.isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Real-time Data Flow Display
          if (_wsService.recentReadings.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!, width: 1),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Real-time Data Flow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(51),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.green.withAlpha(128),
                          ),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Show last 10 readings in a scrollable row
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount:
                          _wsService.recentReadings.length > 10
                              ? 10
                              : _wsService.recentReadings.length,
                      itemBuilder: (context, index) {
                        final reversedIndex =
                            _wsService.recentReadings.length - 1 - index;
                        if (reversedIndex < 0) return Container();

                        final reading =
                            _wsService.recentReadings[reversedIndex];
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[600]!),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _buildCompactSensorValue(
                                'L',
                                reading['left'] ?? 0,
                                Colors.red,
                              ),
                              const SizedBox(height: 4),
                              _buildCompactSensorValue(
                                'R',
                                reading['right'] ?? 0,
                                Colors.green,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Control Panel
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[700]!, width: 1),
            ),
            child: Column(
              children: [
                // Connection Status
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        _wsService.isConnected
                            ? Colors.blue.withAlpha(51)
                            : Colors.red.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _wsService.isConnected ? Colors.blue : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _wsService.isConnected ? Icons.wifi : Icons.wifi_off,
                        color:
                            _wsService.isConnected ? Colors.blue : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _wsService.isConnected
                            ? 'WebSocket Connected'
                            : 'WebSocket Disconnected',
                        style: TextStyle(
                          color:
                              _wsService.isConnected ? Colors.blue : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isTestRunning
                            ? Colors.green.withAlpha(51)
                            : Colors.grey.withAlpha(51),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isTestRunning ? Colors.green : Colors.grey,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _isTestRunning ? 'TEST RUNNING' : 'TEST IDLE',
                    style: TextStyle(
                      color: _isTestRunning ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Start Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isTestRunning ? null : _startTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[600],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'START TEST',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Stop Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isTestRunning ? _stopTest : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey[600],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stop, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'STOP TEST',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Clear data button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _testData.clear();
                        });
                        _wsService.clearSession();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data cleared'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('CLEAR DATA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Live data indicator
                if (_isTestRunning) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Live data streaming...',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Data Display with Tabs
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[700]!, width: 1),
              ),
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    // Tab Header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Debug info row
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withAlpha(51),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.withAlpha(128),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'Test: ${_testData.length}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Live: ${_wsService.recentReadings.length}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Status: ${_isTestRunning ? "RUNNING" : "IDLE"}',
                                  style: TextStyle(
                                    color:
                                        _isTestRunning
                                            ? Colors.green
                                            : Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Tab Bar
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const TabBar(
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.blue,
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: [
                                Tab(
                                  icon: Icon(Icons.timeline),
                                  text: 'Live Stream',
                                ),
                                Tab(
                                  icon: Icon(Icons.history),
                                  text: 'Test Data',
                                ),
                                Tab(
                                  icon: Icon(Icons.analytics),
                                  text: 'Statistics',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab Content
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Tab 1: Live Stream
                          _buildLiveStreamTab(),

                          // Tab 2: Test Data
                          _buildTestDataTab(),

                          // Tab 3: Statistics
                          _buildStatisticsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
