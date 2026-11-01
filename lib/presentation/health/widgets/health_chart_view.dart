import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../data/models/health_models.dart';

enum SugarChartMode {
  preMeal,
  postMeal,
  random,
  allCombined,
}

class HealthChartView extends StatefulWidget {
  final List<HealthEvent> events;
  final void Function(HealthEventType type)? onOpenFastFill;

  const HealthChartView({
    super.key,
    required this.events,
    this.onOpenFastFill,
  });

  @override
  State<HealthChartView> createState() => _HealthChartViewState();
}

class _HealthChartViewState extends State<HealthChartView> {
  SugarChartMode _selectedSugarMode = SugarChartMode.preMeal;

  @override
  Widget build(BuildContext context) {
    final sugarEvents = widget.events
        .where((e) => e.eventType == HealthEventType.sugar && e.sugarData != null)
        .toList()
      ..sort((a, b) {
        final dateCmp = a.eventDate.compareTo(b.eventDate);
        if (dateCmp != 0) return dateCmp;
        return a.eventTime.compareTo(b.eventTime);
      });

    final bpEvents = widget.events
        .where((e) => e.eventType == HealthEventType.bloodPressure && e.bpData != null)
        .toList()
      ..sort((a, b) {
        final dateCmp = a.eventDate.compareTo(b.eventDate);
        if (dateCmp != 0) return dateCmp;
        return a.eventTime.compareTo(b.eventTime);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. BLOOD SUGAR DEDICATED SEPARATE CHARTS
        _buildSugarAnalysisSection(sugarEvents),
        const SizedBox(height: 24),

        // 2. BLOOD PRESSURE ANALYSIS SECTION
        _buildBpAnalysisSection(bpEvents),
        const SizedBox(height: 40),
      ],
    );
  }

  // ==========================================
  // SUGAR ANALYSIS SECTION (SEPARATE CHARTS)
  // ==========================================

  Widget _buildSugarAnalysisSection(List<HealthEvent> allSugarEvents) {
    // Filter dataset based on selected chart mode
    final List<HealthEvent> currentDataset;
    final String modeTitle;
    final String referenceTargetText;
    final double? normalTargetLine;
    final double? highTargetLine;

    switch (_selectedSugarMode) {
      case SugarChartMode.preMeal:
        currentDataset = allSugarEvents.where((e) {
          final ctx = e.sugarData?.context;
          return ctx == SugarContext.fasting || ctx == SugarContext.beforeMeal;
        }).toList();
        modeTitle = 'Pre-Meal / Fasting Sugar (उपवासाची साखर)';
        referenceTargetText = 'Guideline Target: < 100 mg/dL (Normal Reference Range)';
        normalTargetLine = 100.0;
        highTargetLine = 126.0;
        break;

      case SugarChartMode.postMeal:
        currentDataset = allSugarEvents.where((e) {
          return e.sugarData?.context == SugarContext.afterMeal;
        }).toList();
        modeTitle = 'Post-Meal Sugar (जेवणानंतरची साखर)';
        referenceTargetText = 'Guideline Target: < 140 mg/dL (Normal Reference Range)';
        normalTargetLine = 140.0;
        highTargetLine = 200.0;
        break;

      case SugarChartMode.random:
        currentDataset = allSugarEvents.where((e) {
          return e.sugarData?.context == SugarContext.random;
        }).toList();
        modeTitle = 'Random Sugar (कधीही तपासलेली साखर)';
        referenceTargetText = 'Guideline Target: < 140 mg/dL (Normal Reference Range)';
        normalTargetLine = 140.0;
        highTargetLine = 200.0;
        break;

      case SugarChartMode.allCombined:
        currentDataset = allSugarEvents;
        modeTitle = 'All Sugar Readings (सर्व एकत्रित आलेख)';
        referenceTargetText = 'Comprehensive trend across all meal contexts';
        normalTargetLine = 100.0;
        highTargetLine = 140.0;
        break;
    }

    // Statistics computation for the selected dataset
    double avgSugar = 0;
    double? minSugar;
    String? minDateStr;
    double? maxSugar;
    String? maxDateStr;
    int withinTargetCount = 0;

    if (currentDataset.isNotEmpty) {
      final sum = currentDataset.fold<double>(0, (prev, e) => prev + (e.sugarData?.value ?? 0));
      avgSugar = sum / currentDataset.length;

      for (final e in currentDataset) {
        final val = e.sugarData?.value ?? 0;
        if (minSugar == null || val < minSugar) {
          minSugar = val;
          minDateStr = '${DateFormat('dd MMM').format(e.eventDate)} ${e.eventTime}';
        }
        if (maxSugar == null || val > maxSugar) {
          maxSugar = val;
          maxDateStr = '${DateFormat('dd MMM').format(e.eventDate)} ${e.eventTime}';
        }

        if (normalTargetLine != null && val <= normalTargetLine) {
          withinTargetCount++;
        }
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Section Title & Direct Fast Fill Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('🩸', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'Blood Sugar Analysis',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (widget.onOpenFastFill != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.amber.shade50,
                      foregroundColor: Colors.amber.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.amber.shade300),
                      ),
                    ),
                    icon: const Text('⚡', style: TextStyle(fontSize: 12)),
                    label: const Text(
                      'Fast Fill Paper Log',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => widget.onOpenFastFill!(HealthEventType.sugar),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // SEPARATE CHART SELECTOR TABS
            // [ 🌅 Pre-Meal / Fasting ] [ 🍽️ Post-Meal ] [ 🎲 Random ] [ 📊 All Combined ]
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSugarModeChip(
                    mode: SugarChartMode.preMeal,
                    label: '🌅 Pre-Meal / Fasting',
                    badgeCount: allSugarEvents.where((e) {
                      final c = e.sugarData?.context;
                      return c == SugarContext.fasting || c == SugarContext.beforeMeal;
                    }).length,
                  ),
                  const SizedBox(width: 6),
                  _buildSugarModeChip(
                    mode: SugarChartMode.postMeal,
                    label: '🍽️ Post-Meal',
                    badgeCount: allSugarEvents.where((e) => e.sugarData?.context == SugarContext.afterMeal).length,
                  ),
                  const SizedBox(width: 6),
                  _buildSugarModeChip(
                    mode: SugarChartMode.random,
                    label: '🎲 Random',
                    badgeCount: allSugarEvents.where((e) => e.sugarData?.context == SugarContext.random).length,
                  ),
                  const SizedBox(width: 6),
                  _buildSugarModeChip(
                    mode: SugarChartMode.allCombined,
                    label: '📊 All Combined',
                    badgeCount: allSugarEvents.length,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Subtitle & Guideline Target
            Text(
              modeTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 2),
            Text(
              referenceTargetText,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),

            // SUMMARY METRICS CARDS (Genuinely independent for this chart)
            if (currentDataset.isNotEmpty)
              _buildSugarMetricsRow(
                count: currentDataset.length,
                avg: avgSugar,
                min: minSugar,
                minDate: minDateStr,
                max: maxSugar,
                maxDate: maxDateStr,
                withinTargetCount: withinTargetCount,
                normalThreshold: normalTargetLine,
              ),

            const SizedBox(height: 16),

            // THE CHART CANVAS
            SizedBox(
              height: 210,
              child: currentDataset.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.query_builder, size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 6),
                          Text(
                            'No readings for this chart yet.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                          if (widget.onOpenFastFill != null) ...[
                            const SizedBox(height: 6),
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Add paper diary readings', style: TextStyle(fontSize: 12)),
                              onPressed: () => widget.onOpenFastFill!(HealthEventType.sugar),
                            ),
                          ],
                        ],
                      ),
                    )
                  : _renderSugarChart(
                      currentDataset,
                      normalTargetLine: normalTargetLine,
                      highTargetLine: highTargetLine,
                    ),
            ),
            const SizedBox(height: 10),

            // CHART LEGEND
            _buildSugarLegend(),
            const SizedBox(height: 14),

            // READINGS TABLE / FEED (Detailed log for this specific view)
            if (currentDataset.isNotEmpty) ...[
              const Divider(height: 1),
              const SizedBox(height: 8),
              _buildSugarHistoryList(currentDataset),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSugarModeChip({
    required SugarChartMode mode,
    required String label,
    required int badgeCount,
  }) {
    final isSelected = _selectedSugarMode == mode;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          if (badgeCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.teal.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      selectedColor: Colors.teal.shade100,
      visualDensity: VisualDensity.compact,
      onSelected: (selected) {
        if (selected) setState(() => _selectedSugarMode = mode);
      },
    );
  }

  Widget _buildSugarMetricsRow({
    required int count,
    required double avg,
    required double? min,
    required String? minDate,
    required double? max,
    required String? maxDate,
    required int withinTargetCount,
    required double? normalThreshold,
  }) {
    final pctInTarget = count > 0 ? (withinTargetCount * 100 ~/ count) : 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricStat('Readings', '$count', Colors.black87),
          _buildMetricStat('Average', '${avg.toStringAsFixed(0)} mg/dL', Colors.teal.shade900),
          if (min != null)
            _buildMetricStat('Lowest', '${min.toStringAsFixed(0)} mg/dL', Colors.green.shade800, subtext: minDate),
          if (max != null)
            _buildMetricStat('Highest', '${max.toStringAsFixed(0)} mg/dL', Colors.red.shade800, subtext: maxDate),
          if (normalThreshold != null)
            _buildMetricStat('In Target', '$pctInTarget%', Colors.indigo.shade800),
        ],
      ),
    );
  }

  Widget _buildMetricStat(String label, String value, Color color, {String? subtext}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
        if (subtext != null)
          Text(
            subtext,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _renderSugarChart(
    List<HealthEvent> sugars, {
    double? normalTargetLine,
    double? highTargetLine,
  }) {
    final spots = <FlSpot>[];
    for (int i = 0; i < sugars.length; i++) {
      final val = sugars[i].sugarData?.value ?? 0;
      spots.add(FlSpot(i.toDouble(), val));
    }

    double calculatedMinY = 60;
    double calculatedMaxY = 240;

    if (sugars.isNotEmpty) {
      final values = sugars.map((e) => e.sugarData?.value ?? 0);
      final minVal = values.reduce((a, b) => a < b ? a : b);
      final maxVal = values.reduce((a, b) => a > b ? a : b);
      calculatedMinY = (minVal - 20).clamp(40.0, 300.0);
      calculatedMaxY = (maxVal + 30).clamp(180.0, 500.0);
    }

    final extraLines = <HorizontalLine>[];
    if (normalTargetLine != null) {
      extraLines.add(
        HorizontalLine(
          y: normalTargetLine,
          color: Colors.green.withOpacity(0.6),
          strokeWidth: 1.5,
          dashArray: [5, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 6, bottom: 2),
            style: const TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold),
            labelResolver: (_) => '< ${normalTargetLine.toInt()}',
          ),
        ),
      );
    }
    if (highTargetLine != null) {
      extraLines.add(
        HorizontalLine(
          y: highTargetLine,
          color: Colors.red.withOpacity(0.5),
          strokeWidth: 1.5,
          dashArray: [4, 4],
          label: HorizontalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            padding: const EdgeInsets.only(right: 6, bottom: 2),
            style: const TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
            labelResolver: (_) => '≥ ${highTargetLine.toInt()}',
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 40,
          getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: extraLines),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 40,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (sugars.length / 4).ceilToDouble().clamp(1.0, 10.0),
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < sugars.length) {
                  final event = sugars[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${DateFormat('dd MMM').format(event.eventDate)}\n${event.eventTime}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx < 0 || idx >= sugars.length) return null;
                final event = sugars[idx];
                final reading = event.sugarData?.value ?? 0;
                final ctxLabel = event.sugarData?.context.label ?? '';
                final hasEvidence = event.hasEvidence;

                return LineTooltipItem(
                  '${DateFormat('dd MMM yyyy').format(event.eventDate)} • ${event.eventTime}\n'
                  '${reading.toStringAsFixed(0)} mg/dL ($ctxLabel)\n'
                  '${hasEvidence ? '🟢 Lab Report Attached' : '🟡 Manual Paper Diary'}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              }).toList();
            },
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: calculatedMinY,
        maxY: calculatedMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.teal.shade700,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final hasEvidence = index < sugars.length && sugars[index].hasEvidence;
                return FlDotCirclePainter(
                  radius: hasEvidence ? 5 : 3.5,
                  color: hasEvidence ? Colors.green.shade700 : Colors.teal,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.teal.withOpacity(0.10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugarLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildReferenceDot(Colors.teal, 'Manual Reading'),
          const SizedBox(width: 12),
          _buildReferenceDot(Colors.green.shade700, 'Lab Report Attached'),
          const SizedBox(width: 12),
          _buildReferenceLine(Colors.green, 'Target Threshold'),
          const SizedBox(width: 12),
          _buildReferenceLine(Colors.red, 'Elevated Threshold'),
        ],
      ),
    );
  }

  Widget _buildSugarHistoryList(List<HealthEvent> sugars) {
    // Show last 6 readings in reverse chronological order
    final recent = sugars.reversed.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT READINGS (${sugars.length} TOTAL)',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Colors.grey,
              ),
            ),
            Text(
              'Date • Time • Value • Provenance',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, idx) {
            final e = recent[idx];
            final val = e.sugarData?.value ?? 0;
            final ctxLabel = e.sugarData?.context.label ?? '';
            final hasDoc = e.hasEvidence;

            Color badgeColor = Colors.teal;
            if (val >= 180) {
              badgeColor = Colors.red.shade700;
            } else if (val >= 140) {
              badgeColor = Colors.orange.shade800;
            } else {
              badgeColor = Colors.green.shade700;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: badgeColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '${val.toStringAsFixed(0)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$ctxLabel',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          '${DateFormat('dd MMM yyyy').format(e.eventDate)} • ${e.eventTime}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasDoc ? Colors.green.shade50 : Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: hasDoc ? Colors.green.shade200 : Colors.amber.shade200),
                    ),
                    child: Text(
                      hasDoc ? '🟢 Lab Report' : '🟡 Paper Log',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: hasDoc ? Colors.green.shade900 : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // BLOOD PRESSURE ANALYSIS SECTION
  // ==========================================

  Widget _buildBpAnalysisSection(List<HealthEvent> bpEvents) {
    int avgSys = 0;
    int avgDia = 0;
    int? minSys;
    int? maxSys;

    if (bpEvents.isNotEmpty) {
      final totalSys = bpEvents.fold<int>(0, (prev, e) => prev + (e.bpData?.systolic ?? 0));
      final totalDia = bpEvents.fold<int>(0, (prev, e) => prev + (e.bpData?.diastolic ?? 0));
      avgSys = totalSys ~/ bpEvents.length;
      avgDia = totalDia ~/ bpEvents.length;

      for (final e in bpEvents) {
        final s = e.bpData?.systolic ?? 0;
        if (minSys == null || s < minSys) minSys = s;
        if (maxSys == null || s > maxSys) maxSys = s;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text('❤️', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text('Blood Pressure Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                if (widget.onOpenFastFill != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.indigo.shade50,
                      foregroundColor: Colors.indigo.shade900,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.indigo.shade200),
                      ),
                    ),
                    icon: const Text('⚡', style: TextStyle(fontSize: 12)),
                    label: const Text(
                      'Fast Fill BP',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () => widget.onOpenFastFill!(HealthEventType.bloodPressure),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Systolic & Diastolic readings over time • Target: < 120/80 mmHg (Reference Range)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),

            if (bpEvents.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricStat('Readings', '${bpEvents.length}', Colors.black87),
                    _buildMetricStat('Average BP', '$avgSys / $avgDia', Colors.indigo.shade900),
                    if (minSys != null) _buildMetricStat('Lowest Sys', '$minSys mmHg', Colors.green.shade800),
                    if (maxSys != null) _buildMetricStat('Highest Sys', '$maxSys mmHg', Colors.red.shade800),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              height: 200,
              child: bpEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.monitor_heart, size: 36, color: Colors.grey.shade300),
                          const SizedBox(height: 6),
                          Text('No BP readings recorded yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          if (widget.onOpenFastFill != null) ...[
                            const SizedBox(height: 6),
                            TextButton.icon(
                              icon: const Icon(Icons.add, size: 14),
                              label: const Text('Add paper BP records', style: TextStyle(fontSize: 12)),
                              onPressed: () => widget.onOpenFastFill!(HealthEventType.bloodPressure),
                            ),
                          ],
                        ],
                      ),
                    )
                  : _renderBpChart(bpEvents),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildReferenceDot(Colors.indigo, 'Systolic'),
                const SizedBox(width: 16),
                _buildReferenceDot(Colors.teal, 'Diastolic'),
                const SizedBox(width: 16),
                _buildReferenceLine(Colors.red.shade300, 'Normal 120/80 Target'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderBpChart(List<HealthEvent> bpEvents) {
    final sysSpots = <FlSpot>[];
    final diaSpots = <FlSpot>[];

    for (int i = 0; i < bpEvents.length; i++) {
      final bp = bpEvents[i].bpData!;
      sysSpots.add(FlSpot(i.toDouble(), bp.systolic.toDouble()));
      diaSpots.add(FlSpot(i.toDouble(), bp.diastolic.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 120,
              color: Colors.red.withOpacity(0.35),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
            HorizontalLine(
              y: 80,
              color: Colors.teal.withOpacity(0.35),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              interval: 20,
              getTitlesWidget: (val, meta) => Text(
                '${val.toInt()}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (bpEvents.length / 4).ceilToDouble().clamp(1.0, 10.0),
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < bpEvents.length) {
                  final event = bpEvents[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${DateFormat('dd MMM').format(event.eventDate)}\n${event.eventTime}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 8.5, color: Colors.grey),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.toInt();
                if (idx < 0 || idx >= bpEvents.length) return null;
                final event = bpEvents[idx];
                final bp = event.bpData!;
                final isSys = spot.barIndex == 0;

                return LineTooltipItem(
                  '${DateFormat('dd MMM yyyy').format(event.eventDate)} • ${event.eventTime}\n'
                  '${isSys ? "Systolic: ${bp.systolic}" : "Diastolic: ${bp.diastolic}"} mmHg'
                  '${bp.pulse != null ? " • Pulse: ${bp.pulse}" : ""}\n'
                  '${event.hasEvidence ? "🟢 Document Attached" : "🟡 Manual Entry"}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                );
              }).toList();
            },
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 50,
        maxY: 180,
        lineBarsData: [
          LineChartBarData(
            spots: sysSpots,
            isCurved: true,
            color: Colors.indigo,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
          LineChartBarData(
            spots: diaSpots,
            isCurved: true,
            color: Colors.teal,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReferenceLine(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 2,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
