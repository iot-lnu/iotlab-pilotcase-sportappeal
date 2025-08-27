import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/backend_config.dart';
import '../services/loadcell_api_service.dart';

/// Settings screen showing backend connection details and allowing manual detection
class BackendSettingsScreen extends StatefulWidget {
  const BackendSettingsScreen({super.key});

  @override
  State<BackendSettingsScreen> createState() => _BackendSettingsScreenState();
}

class _BackendSettingsScreenState extends State<BackendSettingsScreen> {
  bool _isDetecting = false;
  Map<String, dynamic> _connectionInfo = {};

  @override
  void initState() {
    super.initState();
    _updateConnectionInfo();
  }

  void _updateConnectionInfo() {
    setState(() {
      _connectionInfo = BackendConfig.getConnectionInfo();
    });
  }

  Future<void> _retryDetection() async {
    setState(() {
      _isDetecting = true;
    });

    try {
      // Get the service before any async operations to avoid using BuildContext across async gaps
      final apiService = Provider.of<LoadcellApiService>(
        context,
        listen: false,
      );

      // Reset previous detection
      BackendConfig.resetDetection();

      // Try to detect backend
      final detected = await BackendConfig.autoDetectBackend();

      // Test connection
      final connected = await apiService.checkConnection();

      _updateConnectionInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              detected && connected
                  ? 'Backend detected and connected!'
                  : detected
                  ? 'Backend detected but not fully connected'
                  : 'No backend found',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor:
                detected && connected
                    ? Colors.green
                    : detected
                    ? Colors.orange
                    : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isDetecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          'Backend Settings',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: BackendConfig.isDetected ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        BackendConfig.isDetected
                            ? Icons.check_circle
                            : Icons.error,
                        color:
                            BackendConfig.isDetected
                                ? Colors.green
                                : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        BackendConfig.isDetected
                            ? 'Backend Detected'
                            : 'Backend Not Found',
                        style: TextStyle(
                          color:
                              BackendConfig.isDetected
                                  ? Colors.green
                                  : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  if (BackendConfig.isDetected) ...[
                    const SizedBox(height: 12),
                    Text(
                      'HTTP API: ${BackendConfig.baseUrl}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WebSocket: ${BackendConfig.wsUrl}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Retry Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDetecting ? null : _retryDetection,
                icon:
                    _isDetecting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  _isDetecting ? 'Detecting...' : 'Retry Detection',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Connection Details
            Text(
              'Connection Details',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        'Platform',
                        _connectionInfo['platform'] ?? 'Unknown',
                      ),
                      _buildInfoRow(
                        'Is Simulator',
                        (_connectionInfo['isSimulator'] ?? false).toString(),
                      ),
                      _buildInfoRow(
                        'Detected URL',
                        _connectionInfo['detectedBaseUrl'] ?? 'None',
                      ),
                      _buildInfoRow(
                        'Fallback URL',
                        _connectionInfo['fallbackBaseUrl'] ?? 'None',
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        'Candidate Hosts (in order of preference):',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_connectionInfo['candidateHosts'] != null)
                        ...((_connectionInfo['candidateHosts'] as List).map(
                          (host) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $host:5000',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tips
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tips',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Make sure the backend server is running\n'
                    '• iOS Simulator uses localhost (127.0.0.1)\n'
                    '• Android Emulator uses 10.0.2.2\n'
                    '• Physical devices need your Mac\'s LAN IP\n'
                    '• Check firewall settings if connection fails',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
