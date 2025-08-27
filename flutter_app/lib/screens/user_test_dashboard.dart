import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/loadcell_api_service.dart';

class UserTestDashboard extends StatefulWidget {
  final User user;
  final String testType;

  const UserTestDashboard({
    super.key,
    required this.user,
    this.testType = 'Standard Test',
  });

  @override
  State<UserTestDashboard> createState() => _UserTestDashboardState();
}

class _UserTestDashboardState extends State<UserTestDashboard> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final loadcellApiService = Provider.of<LoadcellApiService>(
        context,
        listen: false,
      );

      // Only check connection and start updates if user actually wants to use loadcell features
      // This prevents unnecessary backend connection attempts
      if (widget.testType.toLowerCase().contains('loadcell') ||
          widget.testType.toLowerCase().contains('imtp')) {
        loadcellApiService.checkConnection();
        loadcellApiService.startPeriodicUpdates();
      }
    });
  }

  Future<void> _startTest() async {
    final loadcellApiService = Provider.of<LoadcellApiService>(
      context,
      listen: false,
    );
    final result = await loadcellApiService.startTest();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['success'] ? result['message'] : result['error'],
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _stopTest() async {
    final loadcellApiService = Provider.of<LoadcellApiService>(
      context,
      listen: false,
    );
    final result = await loadcellApiService.stopTest();

    if (mounted) {
      String message =
          result['success']
              ? '${result['message']}\nSamples collected: ${result['sample_count']}'
              : result['error'];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

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
                  // Status indicator
                  Consumer<LoadcellApiService>(
                    builder: (context, loadcellApiService, child) {
                      final isLoadcellConnected =
                          loadcellApiService.isConnected;
                      final isTesting = loadcellApiService.isTesting;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Loadcell connection status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isLoadcellConnected
                                      ? Colors.green.withAlpha(51)
                                      : Colors.red.withAlpha(51),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isLoadcellConnected
                                      ? "Loadcell Connected"
                                      : "Loadcell Offline",
                                  style: TextStyle(
                                    color:
                                        isLoadcellConnected
                                            ? Colors.green
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  isLoadcellConnected
                                      ? Icons.sensors
                                      : Icons.sensors_off,
                                  color:
                                      isLoadcellConnected
                                          ? Colors.green
                                          : Colors.red,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Test status
                          if (isLoadcellConnected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isTesting
                                        ? Colors.orange.withAlpha(51)
                                        : Colors.blue.withAlpha(51),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isTesting ? "Testing..." : "Ready",
                                    style: TextStyle(
                                      color:
                                          isTesting
                                              ? Colors.orange
                                              : Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isTesting
                                        ? Icons.play_circle_filled
                                        : Icons.pause_circle_filled,
                                    color:
                                        isTesting ? Colors.orange : Colors.blue,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main Content Container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  children: [
                    // User name header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1919),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF007340),
                            radius: 20,
                            child: Text(
                              (widget.user.username.isNotEmpty
                                      ? widget.user.username[0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${widget.testType} Session',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            DateTime.now().toString().substring(0, 16),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Test Control Buttons
                    Consumer<LoadcellApiService>(
                      builder: (context, loadcellApiService, child) {
                        final isConnected = loadcellApiService.isConnected;
                        final isTesting = loadcellApiService.isTesting;

                        return Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    isConnected && !isTesting
                                        ? _startTest
                                        : null,
                                icon: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'START TEST',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isConnected && !isTesting
                                          ? const Color(0xFF75F94C)
                                          : Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    isConnected && isTesting ? _stopTest : null,
                                icon: const Icon(
                                  Icons.stop,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'STOP TEST',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isConnected && isTesting
                                          ? const Color(0xFF75F94C)
                                          : Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Loadcell Readings Section
                    const Text(
                      'Real-Time Sensor History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Consumer<LoadcellApiService>(
                      builder: (context, loadcellApiService, child) {
                        final latestReading = loadcellApiService.latestReading;
                        final isConnected = loadcellApiService.isConnected;

                        if (!isConnected || latestReading.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1919),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.scale,
                                    color: Colors.grey,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No sensor data available',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1919),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.sensors, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Live Data Stream',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  // Live indicator
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'LIVE',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Current live data display
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCurrentDataDisplay(
                                      'L',
                                      '${latestReading['left'] ?? 0}',
                                      Colors.red,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildCurrentDataDisplay(
                                      'R',
                                      '${latestReading['right'] ?? 0}',
                                      Colors.green,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Sensor History List
                              Row(
                                children: [
                                  Icon(
                                    Icons.history,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sensor History (Real-Time)',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${loadcellApiService.sessionData.length} readings',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Real-time sensor history list
                              Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[700]!),
                                ),
                                child: _buildSensorHistoryList(
                                  loadcellApiService,
                                ),
                              ),

                              const SizedBox(height: 8),
                              Text(
                                'Last Update: ${_formatTimestamp(latestReading['timestamp'])}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 15.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.home, color: Colors.yellow, size: 30),
                  Icon(Icons.fitness_center, color: Colors.yellow, size: 30),
                  Icon(
                    Icons.insert_chart_outlined_rounded,
                    color: Colors.yellow,
                    size: 30,
                  ),
                  Icon(Icons.person, color: Colors.yellow, size: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDataDisplay(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorHistoryList(LoadcellApiService loadcellApiService) {
    if (loadcellApiService.sessionData.isEmpty) {
      return const Center(
        child: Text(
          'No sensor history yet. Start a test to see real-time data.',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: loadcellApiService.sessionData.length,
      reverse: true, // Show newest first
      itemBuilder: (context, index) {
        final reversedIndex = loadcellApiService.sessionData.length - 1 - index;
        final reading = loadcellApiService.sessionData[reversedIndex];

        return Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: index % 2 == 0 ? Colors.grey[900] : Colors.grey[800],
            border: Border(
              bottom: BorderSide(color: Colors.grey[700]!, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              // Timestamp
              Container(
                width: 80,
                child: Text(
                  _formatTimestamp(reading['timestamp']),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Sensor values
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      child: Text(
                        'L: ${reading['left'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      width: 60,
                      child: Text(
                        'R: ${reading['right'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sample number
              Text(
                '#${reversedIndex + 1}',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      return 'N/A';
    }

    try {
      int timestampInt;
      if (timestamp is String) {
        timestampInt = int.parse(timestamp);
      } else if (timestamp is int) {
        timestampInt = timestamp;
      } else {
        return 'Invalid timestamp';
      }

      final date = DateTime.fromMillisecondsSinceEpoch(timestampInt);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid timestamp';
    }
  }
}
