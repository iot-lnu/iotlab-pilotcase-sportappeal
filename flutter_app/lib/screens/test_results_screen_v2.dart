import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../components/standard_page_layout.dart';
import '../services/backend_config.dart';

class TestResultsScreenV2 extends StatefulWidget {
  final User user;

  const TestResultsScreenV2({super.key, required this.user});

  @override
  State<TestResultsScreenV2> createState() => _TestResultsScreenV2State();
}

class _TestResultsScreenV2State extends State<TestResultsScreenV2> {
  List<LoadCellData> _chartData = [];
  final List<LoadCellData> _rawChartData =
      []; // Store original data with negative values
  bool _isLoading = true;
  String? _error;
  bool _showOnlyPositive = true; // Default to showing only positive values

  // Time interval settings for RFD analysis
  double _t1 = 0.0; // First time marker
  double _t2 = 0.1; // Second time marker (100ms default)

  // Pre-set time intervals
  static const List<Map<String, dynamic>> _presetIntervals = [
    {'start': 0.0, 'end': 0.05, 'label': '0-50ms'},
    {'start': 0.0, 'end': 0.1, 'label': '0-100ms'},
    {'start': 0.0, 'end': 0.15, 'label': '0-150ms'},
    {'start': 0.0, 'end': 0.2, 'label': '0-200ms'},
    {'start': 0.0, 'end': 0.25, 'label': '0-250ms'},
  ];

  // Analysis results
  Map<String, dynamic> _analysis = {};

  // Chart controller for interactions
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePinching: true,
      enableDoubleTapZooming: true,
      enablePanning: true,
      enableSelectionZooming: true,
    );
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
    _rawChartData.clear();

    // Skip header row and parse data
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        final values = line.split(',');
        if (values.length >= 4) {
          try {
            final timeSeconds = i * 0.01; // 10ms intervals
            final left = double.parse(values[1]);
            final right = double.parse(values[2]);

            // Store raw data (including negative values)
            _rawChartData.add(
              LoadCellData(
                timeSeconds: timeSeconds,
                leftForce: left,
                rightForce: right,
                totalForce: left + right,
              ),
            );
          } catch (e) {
            // Skip invalid rows
          }
        }
      }
    }

    // Apply filtering based on current setting
    _applyDataFiltering();

    // Limit data points for performance if needed
    if (_chartData.length > 5000) {
      final step = (_chartData.length / 5000).ceil();
      _chartData =
          _chartData
              .where((element) => _chartData.indexOf(element) % step == 0)
              .toList();
    }
  }

  void _calculateAnalysis() {
    if (_chartData.isEmpty) return;

    final leftValues = _chartData.map((d) => d.leftForce).toList();
    final rightValues = _chartData.map((d) => d.rightForce).toList();
    final totalValues = _chartData.map((d) => d.totalForce).toList();

    // Calculate peak forces
    final leftPeak = leftValues.reduce((a, b) => a > b ? a : b);
    final rightPeak = rightValues.reduce((a, b) => a > b ? a : b);
    final totalPeak = totalValues.reduce((a, b) => a > b ? a : b);

    // Calculate force at specific time intervals
    final force50ms = _getForceAtTime(0.05);
    final force100ms = _getForceAtTime(0.1);
    final force150ms = _getForceAtTime(0.15);
    final force200ms = _getForceAtTime(0.2);
    final force250ms = _getForceAtTime(0.25);

    // Calculate RFD (Rate of Force Development)
    final rfd50 = force50ms / 0.05;
    final rfd100 = force100ms / 0.1;
    final rfd150 = force150ms / 0.15;
    final rfd200 = force200ms / 0.2;
    final rfd250 = force250ms / 0.25;

    // Calculate impulse (area under curve)
    final impulse50 = _calculateImpulse(0.05);
    final impulse100 = _calculateImpulse(0.1);
    final impulse150 = _calculateImpulse(0.15);
    final impulse200 = _calculateImpulse(0.2);
    final impulse250 = _calculateImpulse(0.25);

    // Calculate test duration and time to peak
    final testDuration = _chartData.last.timeSeconds;
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

  double _getForceAtTime(double timeSeconds) {
    final targetData = _chartData.firstWhere(
      (d) => d.timeSeconds >= timeSeconds,
      orElse: () => _chartData.last,
    );
    return targetData.totalForce;
  }

  double _calculateImpulse(double timeSeconds) {
    double impulse = 0.0;
    double previousTime = 0.0;

    for (final data in _chartData) {
      if (data.timeSeconds > timeSeconds) break;

      final deltaTime = data.timeSeconds - previousTime;
      impulse += data.totalForce * deltaTime;
      previousTime = data.timeSeconds;
    }

    return impulse;
  }

  double _getTimeToPeak() {
    double maxForce = 0;
    double peakTime = 0;

    for (final data in _chartData) {
      if (data.totalForce > maxForce) {
        maxForce = data.totalForce;
        peakTime = data.timeSeconds;
      }
    }

    return peakTime;
  }

  /// Returns positive value or 0 if negative (filters out noise/calibration issues)
  double _getPositiveValue(double value) {
    return value > 0 ? value : 0;
  }

  /// Apply data filtering based on current settings
  void _applyDataFiltering() {
    if (_showOnlyPositive) {
      // Filter to only show positive values
      _chartData =
          _rawChartData
              .map(
                (data) => LoadCellData(
                  timeSeconds: data.timeSeconds,
                  leftForce: _getPositiveValue(data.leftForce),
                  rightForce: _getPositiveValue(data.rightForce),
                  totalForce:
                      _getPositiveValue(data.leftForce) +
                      _getPositiveValue(data.rightForce),
                ),
              )
              .toList();
    } else {
      // Show all values (including negative)
      _chartData = List.from(_rawChartData);
    }
  }

  /// Toggle between showing all values vs only positive values
  void _togglePositiveValues() {
    setState(() {
      _showOnlyPositive = !_showOnlyPositive;
      _applyDataFiltering();
      _calculateAnalysis(); // Recalculate analysis with new data
    });
  }

  /// Find first positive value and set T1 to that point
  void _findFirstPositiveValue() {
    for (final data in _chartData) {
      if (data.totalForce > 0) {
        setState(() {
          _t1 = data.timeSeconds;
          _calculateAnalysis(); // Recalculate with new T1
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'T1 set to first positive value: ${_t1.toStringAsFixed(3)}s',
            ),
            backgroundColor: const Color(0xFF75F94C),
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      }
    }
  }

  /// Set preset time interval
  void _setPresetInterval(Map<String, dynamic> interval) {
    setState(() {
      _t1 = interval['start'] as double;
      _t2 = interval['end'] as double;
      _calculateAnalysis(); // Recalculate with new interval
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Interval set: ${interval['label']} (T1:${_t1}s, T2:${_t2}s)',
        ),
        backgroundColor: const Color(0xFF007340),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Calculate RFD (Rate of Force Development) for current T1-T2 interval
  double _calculateRFDForInterval() {
    final forceAtT1 = _getForceAtTime(_t1);
    final forceAtT2 = _getForceAtTime(_t2);
    final timeDiff = _t2 - _t1;

    if (timeDiff <= 0) return 0.0;

    return (forceAtT2 - forceAtT1) / timeDiff; // N/s
  }

  /// Calculate slope (similar to RFD but can be used for any interval)
  double _calculateSlopeForInterval(double startTime, double endTime) {
    final forceAtStart = _getForceAtTime(startTime);
    final forceAtEnd = _getForceAtTime(endTime);
    final timeDiff = endTime - startTime;

    if (timeDiff <= 0) return 0.0;

    return (forceAtEnd - forceAtStart) / timeDiff;
  }

  @override
  Widget build(BuildContext context) {
    return StandardPageLayout(
      title: 'TEST RESULTS',
      currentRoute: '/test-results',
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

                    const SizedBox(height: 10),

                    // Chart controls
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _exportChart,
                          icon: const Icon(Icons.download),
                          label: const Text('Export'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007340),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _resetZoom,
                          icon: const Icon(Icons.zoom_out_map),
                          label: const Text('Reset Zoom'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007340),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _togglePositiveValues,
                          icon: Icon(
                            _showOnlyPositive
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          label: Text(
                            _showOnlyPositive ? 'Show All' : 'Positive Only',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _showOnlyPositive
                                    ? const Color(0xFF75F94C)
                                    : const Color(0xFF007340),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Time interval controls (Feature 1: Find first positive)
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _findFirstPositiveValue,
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Find First Positive'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'T1: ${_t1.toStringAsFixed(3)}s  T2: ${_t2.toStringAsFixed(3)}s',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Preset interval buttons (Feature 2: Pre-set buttons)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          _presetIntervals.map((interval) {
                            final isSelected =
                                _t1 == interval['start'] &&
                                _t2 == interval['end'];
                            return ElevatedButton(
                              onPressed: () => _setPresetInterval(interval),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isSelected
                                        ? const Color(0xFF75F94C)
                                        : const Color(0xFF455A64),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              child: Text(
                                interval['label'] as String,
                                style: const TextStyle(fontSize: 11),
                              ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: 15),

                    // Chart
                    SizedBox(height: 300, child: _buildSyncfusionChart()),

                    const SizedBox(height: 20),

                    // Data info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Points: ${_chartData.length} (Raw: ${_rawChartData.length})',
                          style: GoogleFonts.montserrat(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Filter: ${_showOnlyPositive ? 'Positive values only' : 'All values (including negative)'}',
                          style: GoogleFonts.montserrat(
                            color:
                                _showOnlyPositive
                                    ? const Color(0xFF75F94C)
                                    : Colors.orange.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // RFD Table (Feature 3: Create RFD table with slopes)
                    _buildRFDTable(),

                    const SizedBox(height: 20),

                    // Analysis data
                    _buildAnalysisSection(),
                  ],
                ),
              ),
    );
  }

  Widget _buildSyncfusionChart() {
    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBackgroundColor: Colors.transparent,
      zoomPanBehavior: _zoomPanBehavior,
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: const TextStyle(color: Colors.white),
      ),
      primaryXAxis: NumericAxis(
        title: AxisTitle(
          text: 'Time (seconds)',
          textStyle: const TextStyle(color: Colors.white),
        ),
        labelStyle: const TextStyle(color: Colors.white),
        majorGridLines: const MajorGridLines(color: Colors.white24),
        axisLine: const AxisLine(color: Colors.white),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(
          text: 'Force (N)',
          textStyle: const TextStyle(color: Colors.white),
        ),
        labelStyle: const TextStyle(color: Colors.white),
        majorGridLines: const MajorGridLines(color: Colors.white24),
        axisLine: const AxisLine(color: Colors.white),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: const Color(0xFF1A1919),
        textStyle: const TextStyle(color: Colors.white),
      ),
      trackballBehavior: TrackballBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineColor: const Color(0xFF75F94C),
        tooltipSettings: const InteractiveTooltip(
          enable: true,
          color: Color(0xFF1A1919),
          textStyle: TextStyle(color: Colors.white),
        ),
      ),
      series: <CartesianSeries>[
        // Total Force (Area Chart)
        AreaSeries<LoadCellData, double>(
          dataSource: _chartData,
          xValueMapper: (LoadCellData data, _) => data.timeSeconds,
          yValueMapper: (LoadCellData data, _) => data.totalForce,
          name: 'Total Force',
          color: const Color(0xFF75F94C).withValues(alpha: 0.3),
          borderColor: const Color(0xFF75F94C),
          borderWidth: 2,
        ),
        // Left Force
        LineSeries<LoadCellData, double>(
          dataSource: _chartData,
          xValueMapper: (LoadCellData data, _) => data.timeSeconds,
          yValueMapper: (LoadCellData data, _) => data.leftForce,
          name: 'Left Force',
          color: Colors.blue,
          width: 2,
        ),
        // Right Force
        LineSeries<LoadCellData, double>(
          dataSource: _chartData,
          xValueMapper: (LoadCellData data, _) => data.timeSeconds,
          yValueMapper: (LoadCellData data, _) => data.rightForce,
          name: 'Right Force',
          color: Colors.orange,
          width: 2,
        ),
      ],
    );
  }

  void _exportChart() {
    // This would implement chart export to PDF/image
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality would be implemented here'),
        backgroundColor: Color(0xFF007340),
      ),
    );
  }

  void _resetZoom() {
    _zoomPanBehavior.reset();
  }

  Widget _buildRFDTable() {
    // Calculate RFD for different intervals
    final rfdData = [
      {
        'interval': 'Current (T1-T2)',
        'start': _t1,
        'end': _t2,
        'push': 1,
        'rfd': _calculateRFDForInterval(),
      },
      ..._presetIntervals.map(
        (interval) => {
          'interval': interval['label'],
          'start': interval['start'],
          'end': interval['end'],
          'push': 1,
          'rfd': _calculateSlopeForInterval(
            interval['start'] as double,
            interval['end'] as double,
          ),
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF2196F3),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Text(
              'RFD (Rate of Force Development) Table',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Table headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Interval (ms)',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Push',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'RFD (N/s)',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table rows
          ...rfdData.map((data) {
            final isCurrent = data['interval'] == 'Current (T1-T2)';
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color:
                    isCurrent
                        ? const Color(0xFF75F94C).withValues(alpha: 0.2)
                        : Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      data['interval'] as String,
                      style: GoogleFonts.montserrat(
                        color:
                            isCurrent ? const Color(0xFF75F94C) : Colors.white,
                        fontSize: 11,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      data['push'].toString(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      (data['rfd'] as double).round().toString(),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.montserrat(
                        color:
                            isCurrent ? const Color(0xFF75F94C) : Colors.white,
                        fontSize: 11,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
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
            'Force at 250 ms, %',
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

// Data model for load cell readings
class LoadCellData {
  final double timeSeconds;
  final double leftForce;
  final double rightForce;
  final double totalForce;

  LoadCellData({
    required this.timeSeconds,
    required this.leftForce,
    required this.rightForce,
    required this.totalForce,
  });
}
