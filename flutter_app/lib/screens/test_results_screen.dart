import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../components/standard_page_layout.dart';

class TestResultsScreen extends StatefulWidget {
  final User user;

  const TestResultsScreen({super.key, required this.user});

  @override
  State<TestResultsScreen> createState() => _TestResultsScreenState();
}

class _TestResultsScreenState extends State<TestResultsScreen> {
  final List<Map<String, dynamic>> _testData = [];
  bool _isLoading = true;
  String? _error;

  // Analysis results
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
        Uri.parse('http://localhost:5000/api/csv_files'),
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
        Uri.parse('http://localhost:5000/api/download/$filename'),
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

    // Calculate averages (for future use if needed)
    // final leftAvg = leftValues.reduce((a, b) => a + b) / leftValues.length;
    // final rightAvg = rightValues.reduce((a, b) => a + b) / rightValues.length;

    // Calculate force at specific time intervals (simplified)
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

    // Calculate impulse (simplified as area under curve)
    final impulse50 = _calculateImpulse(50);
    final impulse100 = _calculateImpulse(100);
    final impulse150 = _calculateImpulse(150);
    final impulse200 = _calculateImpulse(200);
    final impulse250 = _calculateImpulse(250);

    // Calculate test duration and time to peak
    final testDuration = _testData.length * 0.01; // Assuming 10ms intervals
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
    return force / (milliseconds / 1000.0); // N/s
  }

  double _calculateImpulse(int milliseconds) {
    final endIndex = (milliseconds / 10).round();
    double impulse = 0.0;

    for (int i = 0; i < endIndex && i < _testData.length; i++) {
      final data = _testData[i];
      impulse += (data['left'] as double) + (data['right'] as double);
    }

    return impulse * 0.01; // Convert to N·s
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

    return peakIndex * 0.01; // Convert to seconds
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'TEST RESULTS',
      currentRoute: '/test-results',
      customAppBarContent: Row(
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
          // Print button
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/printable-results',
                    arguments: widget.user,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF75F94C),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.print,
                        color: Color(0xFF75F94C),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'PRINT',
                        style: GoogleFonts.montserrat(
                          color: const Color(0xFF75F94C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.more_vert, color: Color(0xFF75F94C), size: 24),
            ],
          ),
        ],
      ),
      child:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF75F94C)),
              )
              : _error != null
              ? Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    Text(
                      widget.user.username,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'IMTP Session',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFF75F94C),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      DateTime.now().toString().split('.').first,
                      style: GoogleFonts.montserrat(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Chart
                    SizedBox(height: 250, child: LineChart(_createChart())),

                    const SizedBox(height: 30),

                    // Analysis data
                    _buildAnalysisSection(),
                  ],
                ),
              ),
    );
  }

  LineChartData _createChart() {
    if (_testData.isEmpty) {
      return LineChartData();
    }

    final leftSpots = <FlSpot>[];
    final rightSpots = <FlSpot>[];
    final totalSpots = <FlSpot>[];

    for (int i = 0; i < _testData.length; i++) {
      final time = i * 0.01; // 10ms intervals
      final data = _testData[i];
      leftSpots.add(FlSpot(time, data['left']));
      rightSpots.add(FlSpot(time, data['right']));
      totalSpots.add(FlSpot(time, data['left'] + data['right']));
    }

    return LineChartData(
      backgroundColor: Colors.transparent,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 200,
        verticalInterval: 0.5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Colors.white.withValues(alpha: 0.1),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  '${value.toStringAsFixed(1)}s',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 200,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  '${value.toInt()}N',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: totalSpots,
          isCurved: false,
          color: const Color(0xFF75F94C),
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(0xFF75F94C).withValues(alpha: 0.1),
          ),
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

  Widget _buildAnalysisSection() {
    if (_analysis.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Force section
        _buildSectionHeader('Force', Colors.green),
        _buildAnalysisGrid([
          _buildAnalysisItem(
            'Peak force, N',
            _analysis['peakForce'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 50 ms, N',
            _analysis['force50ms'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 100 ms, N',
            _analysis['force100ms'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 150 ms, N',
            _analysis['force150ms'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 200 ms, N',
            _analysis['force200ms'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 250 ms, N',
            _analysis['force250ms'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 50 ms, %',
            _analysis['force50msPercent'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 100 ms, %',
            _analysis['force100msPercent'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 150 ms, %',
            _analysis['force150msPercent'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 200 ms, %',
            _analysis['force200msPercent'].toString(),
          ),
          _buildAnalysisItem(
            'Force at 200 ms, %',
            _analysis['force250msPercent'].toString(),
          ),
        ]),

        const SizedBox(height: 20),

        // Rate of Force Development section
        _buildSectionHeader('Rate of Force Development', Colors.purple),
        _buildAnalysisGrid([
          _buildAnalysisItem('RFD 0-50 ms, N/s', _analysis['rfd50'].toString()),
          _buildAnalysisItem(
            'RFD 0-100 ms, N/s',
            _analysis['rfd100'].toString(),
          ),
          _buildAnalysisItem(
            'RFD at 0-150 ms, N/s',
            _analysis['rfd150'].toString(),
          ),
          _buildAnalysisItem(
            'RFD at 0-200 ms, N/s',
            _analysis['rfd200'].toString(),
          ),
          _buildAnalysisItem(
            'RFD at 0-250 ms, N/s',
            _analysis['rfd250'].toString(),
          ),
        ]),

        const SizedBox(height: 20),

        // Impulse section
        _buildSectionHeader('Impulse (integral*)', Colors.blue),
        _buildAnalysisGrid([
          _buildAnalysisItem(
            'Impulse 0-50 ms, N',
            _analysis['impulse50'].toString(),
          ),
          _buildAnalysisItem(
            'Impulse 0-100 ms, N',
            _analysis['impulse100'].toString(),
          ),
          _buildAnalysisItem(
            'Impulse 0-150 ms, N',
            _analysis['impulse150'].toString(),
          ),
          _buildAnalysisItem(
            'Impulse 0-200 ms, N',
            _analysis['impulse200'].toString(),
          ),
          _buildAnalysisItem(
            'Impulse 0-250 ms, N',
            _analysis['impulse250'].toString(),
          ),
        ]),

        const SizedBox(height: 20),

        // Timing section
        _buildSectionHeader('Timing', Colors.cyan),
        _buildAnalysisGrid([
          _buildAnalysisItem(
            'Length of Pull, s',
            _analysis['testDuration'].toStringAsFixed(1),
          ),
          _buildAnalysisItem(
            'Time to Peak Force, s',
            _analysis['timeToPeak'].toStringAsFixed(2),
          ),
        ]),

        const SizedBox(height: 20),

        // Asymmetry section
        _buildSectionHeader('Asymmetry', Colors.orange),
        _buildAnalysisGrid([
          _buildAnalysisItem(
            'L/R Peak Force, %',
            _analysis['asymmetry'].toStringAsFixed(1),
          ),
          _buildAnalysisItem(
            'Left Peak Force',
            _analysis['leftPeakForce'].toString(),
          ),
          _buildAnalysisItem(
            'Right Peak Force',
            _analysis['rightPeakForce'].toString(),
          ),
        ]),

        const SizedBox(height: 20),

        // Note
        Text(
          '*Area Under the Curve',
          style: GoogleFonts.montserrat(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: color,
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAnalysisGrid(List<Widget> items) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Row(
            children: [
              Expanded(child: items[i]),
              if (i + 1 < items.length) Expanded(child: items[i + 1]),
            ],
          ),
      ],
    );
  }

  Widget _buildAnalysisItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
