import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/backend_config.dart';
import '../components/standard_page_layout.dart';

class NetworkDebugScreen extends StatefulWidget {
  const NetworkDebugScreen({super.key});

  @override
  State<NetworkDebugScreen> createState() => _NetworkDebugScreenState();
}

class _NetworkDebugScreenState extends State<NetworkDebugScreen> {
  Map<String, dynamic>? _connectionInfo;
  bool _isLoading = true;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _loadConnectionInfo();
  }

  Future<void> _loadConnectionInfo() async {
    setState(() => _isLoading = true);

    try {
      final info = await BackendConfig.getConnectionInfo();
      setState(() {
        _connectionInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error loading connection info: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() => _testResult = 'Testing connection...');

    try {
      final success = await BackendConfig.autoDetectBackend();
      setState(() {
        _testResult =
            success
                ? 'Connection successful! Backend found at: ${BackendConfig.baseUrl}'
                : 'Connection failed. No backend found.';
      });

      // Reload connection info after test
      await _loadConnectionInfo();
    } catch (e) {
      setState(() {
        _testResult = 'Connection test failed: $e';
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'NETWORK DEBUG',
      currentRoute: '/network-debug',
      child:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF75F94C)),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Test Connection Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _testConnection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF75F94C),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'TEST CONNECTION',
                          style: GoogleFonts.montserrat(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Test Result
                    if (_testResult.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color:
                              _testResult.contains('successful')
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                          border: Border.all(
                            color:
                                _testResult.contains('successful')
                                    ? Colors.green
                                    : Colors.red,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _testResult,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 30),

                    // Connection Information
                    _buildInfoSection('Platform Information', [
                      _buildInfoRow(
                        'Platform',
                        _connectionInfo?['platform'] ?? 'Unknown',
                      ),
                      if (Platform.isIOS)
                        _buildInfoRow(
                          'iOS Simulator',
                          _connectionInfo?['isSimulator'].toString() ??
                              'Unknown',
                        ),
                      if (Platform.isAndroid)
                        _buildInfoRow(
                          'Android Emulator',
                          _connectionInfo?['isAndroidEmulator'].toString() ??
                              'Unknown',
                        ),
                    ]),

                    const SizedBox(height: 20),

                    _buildInfoSection('Current Configuration', [
                      _buildInfoRow(
                        'Detected Backend URL',
                        _connectionInfo?['detectedBaseUrl'] ?? 'Not detected',
                      ),
                      _buildInfoRow(
                        'Fallback Backend URL',
                        _connectionInfo?['fallbackBaseUrl'] ?? 'Unknown',
                      ),
                      _buildInfoRow(
                        'Config Backend URL',
                        _connectionInfo?['configBackendUrl']?.isEmpty == false
                            ? _connectionInfo!['configBackendUrl']
                            : 'Not set',
                      ),
                      _buildInfoRow(
                        'Config Backend Host',
                        _connectionInfo?['configBackendHost']?.isEmpty == false
                            ? _connectionInfo!['configBackendHost']
                            : 'Not set',
                      ),
                      _buildInfoRow(
                        'Auto-Detect Enabled',
                        _connectionInfo?['autoDetectEnabled'].toString() ??
                            'Unknown',
                      ),
                    ]),

                    const SizedBox(height: 20),

                    _buildInfoSection('Network Information', [
                      _buildListSection(
                        'Local IP Addresses',
                        _connectionInfo?['localIPs']?.cast<String>() ?? [],
                      ),
                      _buildListSection(
                        'Candidate Hosts (Testing Order)',
                        _connectionInfo?['candidateHosts']?.cast<String>() ??
                            [],
                      ),
                    ]),

                    const SizedBox(height: 30),

                    // Configuration Help
                    _buildConfigurationHelp(),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            color: const Color(0xFF75F94C),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items
            .take(10)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 10, bottom: 4),
                child: GestureDetector(
                  onTap: () => _copyToClipboard(item),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 4,
                        color: Color(0xFF75F94C),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        if (items.length > 10)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              '... and ${items.length - 10} more',
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfigurationHelp() {
    final platform =
        Platform.isIOS
            ? 'iOS'
            : Platform.isAndroid
            ? 'Android'
            : 'Unknown';
    final isEmulator =
        Platform.isIOS
            ? (_connectionInfo?['isSimulator'] ?? false)
            : Platform.isAndroid
            ? (_connectionInfo?['isAndroidEmulator'] ?? false)
            : false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuration Help',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF75F94C),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For your $platform ${isEmulator ? 'Emulator' : 'Device'}:',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (Platform.isIOS && isEmulator)
                Text(
                  '• Use: http://127.0.0.1:5000 or http://localhost:5000\n'
                  '• Edit lib/config.dart and set:\n'
                  '  backendUrl = "http://127.0.0.1:5000"',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                )
              else if (Platform.isAndroid && isEmulator)
                Text(
                  '• Use: http://10.0.2.2:5000\n'
                  '• Edit lib/config.dart and set:\n'
                  '  backendUrl = "http://10.0.2.2:5000"',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                )
              else
                Text(
                  '• For physical devices, use your computer\'s local IP\n'
                  '• Find your IP: ${Platform.isWindows ? 'ipconfig' : 'ifconfig'}\n'
                  '• Edit lib/config.dart and set:\n'
                  '  backendUrl = "http://YOUR_IP:5000"\n'
                  '• Example: backendUrl = "http://192.168.1.100:5000"',
                  style: GoogleFonts.montserrat(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'Tap any value above to copy it to clipboard.',
                style: GoogleFonts.montserrat(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
