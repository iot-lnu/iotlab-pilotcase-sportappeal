import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/loadcell_api_service.dart';
import '../services/websocket_service.dart';

/// Demonstration screen showing both REST API and WebSocket data side-by-side
/// This helps you choose between the two real-time options
class RealtimeComparisonScreen extends StatefulWidget {
  const RealtimeComparisonScreen({super.key});

  @override
  State<RealtimeComparisonScreen> createState() =>
      _RealtimeComparisonScreenState();
}

class _RealtimeComparisonScreenState extends State<RealtimeComparisonScreen> {
  late WebSocketService _wsService;

  @override
  void initState() {
    super.initState();
    _wsService = WebSocketService();

    // Initialize services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final apiService = Provider.of<LoadcellApiService>(
        context,
        listen: false,
      );
      apiService.checkConnection();
      apiService.startPeriodicUpdates();

      // Start WebSocket connection
      _wsService.connect();
    });
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Real-time Data Comparison',
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF75F94C)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Real-time Experience',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compare REST API polling (2s updates) vs WebSocket streaming (millisecond updates)',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Data comparison
            Expanded(
              child: Row(
                children: [
                  // REST API Column
                  Expanded(
                    child: Column(
                      children: [
                        _buildMethodHeader(
                          'REST API Polling',
                          'Current Method (2s intervals)',
                          Colors.blue,
                          Icons.refresh,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Consumer<LoadcellApiService>(
                            builder: (context, apiService, child) {
                              return _buildDataDisplay(
                                apiService.latestReading,
                                apiService.isConnected,
                                'Polling every 2 seconds',
                                Colors.blue,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // WebSocket Column
                  Expanded(
                    child: Column(
                      children: [
                        _buildMethodHeader(
                          'WebSocket Streaming',
                          'Real-time (milliseconds)',
                          Colors.green,
                          Icons.bolt,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ChangeNotifierProvider.value(
                            value: _wsService,
                            child: Consumer<WebSocketService>(
                              builder: (context, wsService, child) {
                                return _buildDataDisplay(
                                  wsService.latestReading,
                                  wsService.isConnected,
                                  'Streaming live data',
                                  Colors.green,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Control buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final apiService = Provider.of<LoadcellApiService>(
                        context,
                        listen: false,
                      );
                      apiService.startTest();
                      _wsService.startTest();
                    },
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      'START TEST',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final apiService = Provider.of<LoadcellApiService>(
                        context,
                        listen: false,
                      );
                      apiService.stopTest();
                      _wsService.stopTest();
                    },
                    icon: const Icon(Icons.stop, color: Colors.white),
                    label: const Text(
                      'STOP TEST',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodHeader(
    String title,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: color.withAlpha(200), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataDisplay(
    Map<String, dynamic> reading,
    bool isConnected,
    String method,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? color.withAlpha(102) : Colors.red.withAlpha(102),
        ),
      ),
      child: Column(
        children: [
          // Connection status
          Row(
            children: [
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? color : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: TextStyle(
                  color: isConnected ? color : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sensor readings
          if (isConnected && reading.isNotEmpty) ...[
            _buildSensorValue('L', '${reading['left'] ?? 0}', color),
            const SizedBox(height: 12),
            _buildSensorValue('R', '${reading['right'] ?? 0}', color),
            const SizedBox(height: 12),
            _buildSensorValue(
              'Live Update',
              _formatTimestamp(reading['timestamp']),
              color,
            ),
          ] else ...[
            const Expanded(
              child: Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],

          const Spacer(),

          // Method description
          Text(
            method,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorValue(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid';
    }
  }
}
