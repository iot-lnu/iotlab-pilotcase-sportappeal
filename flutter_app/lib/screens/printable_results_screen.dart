import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/user.dart';
import '../services/backend_config.dart';

class PrintableResultsScreen extends StatefulWidget {
  final User user;
  final String? testDate;

  const PrintableResultsScreen({super.key, required this.user, this.testDate});

  @override
  State<PrintableResultsScreen> createState() => _PrintableResultsScreenState();
}

class _PrintableResultsScreenState extends State<PrintableResultsScreen> {
  final List<Map<String, dynamic>> _testData = [];
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _analysis = {};

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  Future<void> _loadTestData() async {
    try {
      // Get latest CSV file from backend
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}/api/csv_files'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final files = data['files'] as List;

        if (files.isNotEmpty) {
          // Get the most recent CSV file
          final latestFile = files.first;
          await _loadCsvData(latestFile['filename']);
        } else {
          setState(() {
            _error = 'No test data available';
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to get CSV files');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading test data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCsvData(String filename) async {
    try {
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}/api/download/$filename'),
      );

      if (response.statusCode == 200) {
        final csvData = response.body;
        _parseCsvData(csvData);
        _calculateAnalysis();

        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to download CSV file');
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading CSV data: $e';
        _isLoading = false;
      });
    }
  }

  void _parseCsvData(String csvData) {
    final lines = csvData.split('\n');
    _testData.clear();

    // Skip header row and parse data
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        final values = line.split(',');
        if (values.length >= 4) {
          try {
            _testData.add({
              'timestamp': values[0],
              'left': double.parse(values[1]),
              'right': double.parse(values[2]),
              'esp32_time': int.parse(values[3]),
            });
          } catch (e) {
            // Skip invalid rows
          }
        }
      }
    }
  }

  void _calculateAnalysis() {
    if (_testData.isEmpty) return;

    final leftValues = _testData.map((d) => d['left'] as double).toList();
    final rightValues = _testData.map((d) => d['right'] as double).toList();

    // Calculate peak forces
    final leftPeak = leftValues.reduce((a, b) => a > b ? a : b);
    final rightPeak = rightValues.reduce((a, b) => a > b ? a : b);
    final totalPeak = leftPeak + rightPeak;

    // Calculate force at specific time intervals
    final force50ms = _getForceAtTime(50);
    final force100ms = _getForceAtTime(100);
    final force150ms = _getForceAtTime(150);
    final force200ms = _getForceAtTime(200);
    final force250ms = _getForceAtTime(250);

    // Calculate RFD (Rate of Force Development)
    final rfd50 = _calculateRFD(50);
    final rfd100 = _calculateRFD(100);
    final rfd150 = _calculateRFD(150);
    final rfd200 = _calculateRFD(200);
    final rfd250 = _calculateRFD(250);

    // Calculate impulse
    final impulse50 = _calculateImpulse(50);
    final impulse100 = _calculateImpulse(100);
    final impulse150 = _calculateImpulse(150);
    final impulse200 = _calculateImpulse(200);
    final impulse250 = _calculateImpulse(250);

    // Calculate test duration and time to peak
    final testDuration = _testData.length * 0.01;
    final timeToPeak = _getTimeToPeak();

    // Calculate asymmetry
    final asymmetry = ((leftPeak - rightPeak) / totalPeak * 100);

    _analysis = {
      'peakForce': totalPeak.round(),
      'leftPeakForce': leftPeak.round(),
      'rightPeakForce': rightPeak.round(),
      'force50ms': force50ms.round(),
      'force100ms': force100ms.round(),
      'force150ms': force150ms.round(),
      'force200ms': force200ms.round(),
      'force250ms': force250ms.round(),
      'force50msPercent': ((force50ms / totalPeak) * 100).round(),
      'force100msPercent': ((force100ms / totalPeak) * 100).round(),
      'force150msPercent': ((force150ms / totalPeak) * 100).round(),
      'force200msPercent': ((force200ms / totalPeak) * 100).round(),
      'force250msPercent': ((force250ms / totalPeak) * 100).round(),
      'rfd50': rfd50.round(),
      'rfd100': rfd100.round(),
      'rfd150': rfd150.round(),
      'rfd200': rfd200.round(),
      'rfd250': rfd250.round(),
      'impulse50': impulse50.round(),
      'impulse100': impulse100.round(),
      'impulse150': impulse150.round(),
      'impulse200': impulse200.round(),
      'impulse250': impulse250.round(),
      'testDuration': testDuration,
      'timeToPeak': timeToPeak,
      'asymmetry': asymmetry,
    };
  }

  double _getForceAtTime(int milliseconds) {
    final index = (milliseconds / 10).round();
    if (index < _testData.length) {
      final data = _testData[index];
      return (data['left'] as double) + (data['right'] as double);
    }
    return 0.0;
  }

  double _calculateRFD(int milliseconds) {
    final force = _getForceAtTime(milliseconds);
    return force / (milliseconds / 1000.0);
  }

  double _calculateImpulse(int milliseconds) {
    final endIndex = (milliseconds / 10).round();
    double impulse = 0.0;

    for (int i = 0; i < endIndex && i < _testData.length; i++) {
      final data = _testData[i];
      impulse += (data['left'] as double) + (data['right'] as double);
    }

    return impulse * 0.01;
  }

  double _getTimeToPeak() {
    double maxForce = 0;
    int peakIndex = 0;

    for (int i = 0; i < _testData.length; i++) {
      final data = _testData[i];
      final totalForce = (data['left'] as double) + (data['right'] as double);
      if (totalForce > maxForce) {
        maxForce = totalForce;
        peakIndex = i;
      }
    }

    return peakIndex * 0.01;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Test Results Report',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printResults,
            tooltip: 'Print Results',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : _buildPrintableContent(),
    );
  }

  Widget _buildPrintableContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.05,
      ), // Responsive padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          _buildHeader(),

          const SizedBox(height: 30),

          // Chart section
          _buildChartSection(),

          const SizedBox(height: 30),

          // Analysis tables
          _buildAnalysisTables(),

          const SizedBox(height: 30),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.05,
      ), // Responsive padding
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive layout that works on all screen sizes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IMTP TEST RESULTS',
                style: GoogleFonts.montserrat(
                  fontSize:
                      MediaQuery.of(context).size.width *
                      0.06, // Responsive font size
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'Participant: ${widget.user.username}',
                style: GoogleFonts.montserrat(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Email: ${widget.user.email}',
                style: GoogleFonts.montserrat(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),
              // Date and duration info below main title to avoid overflow
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Test Date: ${widget.testDate ?? DateTime.now().toString().split('.').first}',
                    style: GoogleFonts.montserrat(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Duration: ${_analysis['testDuration']?.toStringAsFixed(1) ?? 'N/A'}s',
                    style: GoogleFonts.montserrat(
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                'Data Points: ${_testData.length}',
                style: GoogleFonts.montserrat(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width * 0.05,
      ), // Responsive padding
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Force-Time Curve',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height:
                MediaQuery.of(context).size.height * 0.35, // Responsive height
            child: LineChart(_createPrintChart()),
          ),
          const SizedBox(height: 10),
          // Responsive legend that wraps on smaller screens
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem('Total Force', Colors.green),
              _buildLegendItem('Left Foot', Colors.blue),
              _buildLegendItem('Right Foot', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.04, // Responsive width
          height: 3,
          color: color,
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.02,
        ), // Responsive spacing
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize:
                MediaQuery.of(context).size.width *
                0.03, // Responsive font size
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  LineChartData _createPrintChart() {
    if (_testData.isEmpty) {
      return LineChartData();
    }

    final leftSpots = <FlSpot>[];
    final rightSpots = <FlSpot>[];
    final totalSpots = <FlSpot>[];

    for (int i = 0; i < _testData.length; i++) {
      final time = i * 0.01;
      final data = _testData[i];
      leftSpots.add(FlSpot(time, data['left']));
      rightSpots.add(FlSpot(time, data['right']));
      totalSpots.add(FlSpot(time, data['left'] + data['right']));
    }

    return LineChartData(
      backgroundColor: Colors.white,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 500, // Increased for cleaner grid
        verticalInterval: 1.0, // Increased for cleaner grid
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
        },
        getDrawingVerticalLine: (value) {
          return FlLine(color: Colors.grey.shade300, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 35, // Increased space for labels
            interval: 1.0, // Increased interval for cleaner labels
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  '${value.toStringAsFixed(1)}s',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize:
                        MediaQuery.of(context).size.width *
                        0.025, // Responsive font size
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 500, // Increased interval for cleaner labels
            reservedSize: 60, // Increased space for labels
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  '${value.toInt()}N',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize:
                        MediaQuery.of(context).size.width *
                        0.025, // Responsive font size
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.black),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: totalSpots,
          isCurved: false,
          color: Colors.green,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
        ),
        LineChartBarData(
          spots: leftSpots,
          isCurved: false,
          color: Colors.blue,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
        ),
        LineChartBarData(
          spots: rightSpots,
          isCurved: false,
          color: Colors.orange,
          barWidth: 1.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
        ),
      ],
    );
  }

  Widget _buildAnalysisTables() {
    if (_analysis.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildForceTable()),
            const SizedBox(width: 20),
            Expanded(child: _buildRFDTable()),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildImpulseTable()),
            const SizedBox(width: 20),
            Expanded(child: _buildTimingTable()),
          ],
        ),
      ],
    );
  }

  Widget _buildForceTable() {
    return _buildAnalysisTable('Force Analysis', [
      ['Peak Force (N)', _analysis['peakForce'].toString()],
      ['Force at 50ms (N)', _analysis['force50ms'].toString()],
      ['Force at 100ms (N)', _analysis['force100ms'].toString()],
      ['Force at 150ms (N)', _analysis['force150ms'].toString()],
      ['Force at 200ms (N)', _analysis['force200ms'].toString()],
      ['Force at 250ms (N)', _analysis['force250ms'].toString()],
      ['Force at 50ms (%)', '${_analysis['force50msPercent']}%'],
      ['Force at 100ms (%)', '${_analysis['force100msPercent']}%'],
      ['Force at 150ms (%)', '${_analysis['force150msPercent']}%'],
      ['Force at 200ms (%)', '${_analysis['force200msPercent']}%'],
      ['Force at 250ms (%)', '${_analysis['force250msPercent']}%'],
    ]);
  }

  Widget _buildRFDTable() {
    return _buildAnalysisTable('Rate of Force Development', [
      ['RFD 0-50ms (N/s)', _analysis['rfd50'].toString()],
      ['RFD 0-100ms (N/s)', _analysis['rfd100'].toString()],
      ['RFD 0-150ms (N/s)', _analysis['rfd150'].toString()],
      ['RFD 0-200ms (N/s)', _analysis['rfd200'].toString()],
      ['RFD 0-250ms (N/s)', _analysis['rfd250'].toString()],
    ]);
  }

  Widget _buildImpulseTable() {
    return _buildAnalysisTable('Impulse Analysis', [
      ['Impulse 0-50ms (N·s)', _analysis['impulse50'].toString()],
      ['Impulse 0-100ms (N·s)', _analysis['impulse100'].toString()],
      ['Impulse 0-150ms (N·s)', _analysis['impulse150'].toString()],
      ['Impulse 0-200ms (N·s)', _analysis['impulse200'].toString()],
      ['Impulse 0-250ms (N·s)', _analysis['impulse250'].toString()],
    ]);
  }

  Widget _buildTimingTable() {
    return _buildAnalysisTable('Timing & Asymmetry', [
      ['Test Duration (s)', _analysis['testDuration'].toStringAsFixed(1)],
      ['Time to Peak (s)', _analysis['timeToPeak'].toStringAsFixed(2)],
      ['Left Peak Force (N)', _analysis['leftPeakForce'].toString()],
      ['Right Peak Force (N)', _analysis['rightPeakForce'].toString()],
      ['L/R Asymmetry (%)', _analysis['asymmetry'].toStringAsFixed(1)],
    ]);
  }

  Widget _buildAnalysisTable(String title, List<List<String>> data) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Text(
              title,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          ...data.map(
            (row) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      row[0],
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    row[1],
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Notes:',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• IMTP (Isometric Mid-Thigh Pull) test performed using dual force plates',
            style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black87),
          ),
          Text(
            '• Sampling rate: 100 Hz (10ms intervals)',
            style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black87),
          ),
          Text(
            '• RFD calculated as force/time at specified intervals',
            style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black87),
          ),
          Text(
            '• Impulse represents area under the force-time curve',
            style: GoogleFonts.montserrat(fontSize: 11, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            'Generated: ${DateTime.now().toString().split('.').first}',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              color: Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _printResults() {
    // TODO: Implement actual printing functionality
    // For now, show a dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Print Results'),
            content: const Text(
              'Print functionality will be implemented here.\n\n'
              'This would generate a PDF or send to printer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
