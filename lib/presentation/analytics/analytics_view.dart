import 'package:flutter/material.dart';
import '../../data/database/database.dart';
import '../../data/services/profile_service.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../main.dart'; // for global database instance
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:gal/gal.dart';
import '../../data/services/pdf_service.dart';
import '../../core/utils/date_utils.dart';

class AnalyticsView extends StatefulWidget {
  @override
  _AnalyticsViewState createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  int _timeFilterIndex = 2; // 0=Today, 1=Weekly, 2=Monthly, 3=6 Months, 4=Yearly
  final List<String> _filters = ['आज', 'आठवडा', 'महिना', '६ महिने', 'वर्ष'];
  int? _activeProfileId;
  int? _selectedProfileId; // null = All Profiles
  List<Profile> _profiles = [];
  final GlobalKey _globalKey = GlobalKey();
  List<Transaction> _currentTransactions = [];
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final activeId = await ProfileService.getActiveProfileId();
    final profiles = await ProfileService.getProfiles();
    setState(() {
      _activeProfileId = activeId;
      _selectedProfileId = activeId;
      _profiles = profiles;
    });
  }

  DateTime _getStartDate() {
    final now = DateTime.now();
    switch (_timeFilterIndex) {
      case 0: return DateTime(now.year, now.month, now.day);
      case 1: return shiftCalendarDay(now, -7);
      case 2: return shiftCalendarMonth(now, -1);
      case 3: return shiftCalendarMonth(now, -6);
      case 4: return shiftCalendarMonth(now, -12);
      default: return shiftCalendarMonth(now, -1);
    }
  }

  Future<File?> _captureImage() async {
    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/dashboard_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      return null;
    }
  }

  void _shareScreenshot() async {
    final file = await _captureImage();
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)], text: 'माझा डॅशबोर्ड रिपोर्ट');
    }
  }

  void _saveToGallery() async {
    final file = await _captureImage();
    if (file != null) {
      try {
        await Gal.putImage(file.path);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ गॅलरीमध्ये सेव्ह केले')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _shareTextReport() {
    if (_currentTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('माहिती उपलब्ध नाही')));
      return;
    }
    final startDate = _getStartDate();
    final today = DateTime.now();
    final filtered = _currentTransactions.where((t) => t.timestamp.isAfter(startDate)).toList();
    double inc = 0, exp = 0;
    Map<String, double> cats = {};
    for (var tx in filtered) {
       if (tx.type == 'Income') inc += tx.amount;
       if (tx.type == 'Expense') {
           exp += tx.amount;
           cats[tx.categoryName ?? 'अज्ञात'] = (cats[tx.categoryName ?? 'अज्ञात'] ?? 0) + tx.amount;
       }
    }
    var topCat = cats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (topCat.length > 5) topCat = topCat.sublist(0, 5);

    final startStr = "${startDate.day}/${startDate.month}/${startDate.year}";
    final endStr = "${today.day}/${today.month}/${today.year}";
    final genStr = "${today.day}/${today.month}/${today.year} ${today.hour}:${today.minute.toString().padLeft(2, '0')}";

    String text = "📊 डॅशबोर्ड रिपोर्ट ($startStr ते $endStr):\n\nअहवाल तयार केला: $genStr\n\n🟢 उत्पन्न: ₹${inc.toStringAsFixed(0)}\n🔴 खर्च: ₹${exp.toStringAsFixed(0)}\n💰 नफा: ₹${(inc - exp).toStringAsFixed(0)}\n\n📉 टॉप खर्च:\n";
    for (var c in topCat) {
      text += "• ${c.key} - ₹${c.value.toStringAsFixed(0)}\n";
    }
    Share.share(text);
  }

  void _sharePdfReport() async {
    if (_currentTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('माहिती उपलब्ध नाही')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF तयार होत आहे...')));
    
    final file = await _captureImage();
    final startDate = _getStartDate();
    final today = DateTime.now();
    final filtered = _currentTransactions.where((t) => t.timestamp.isAfter(startDate)).toList();
    double inc = 0, exp = 0;
    for (var tx in filtered) {
       if (tx.type == 'Income') inc += tx.amount;
       if (tx.type == 'Expense') exp += tx.amount;
    }
    
    await PdfService.generateDashboardReport(
      chartsImg: file != null ? file.readAsBytesSync() : null,
      startStr: "${startDate.day}/${startDate.month}/${startDate.year}",
      endStr: "${today.day}/${today.month}/${today.year}",
      totalIncome: inc,
      totalExpense: exp,
      profileName: _profiles.firstWhere((p) => p.id == _selectedProfileId, orElse: () => _profiles.first).name,
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: const Text('PDF रिपोर्ट (Branded PDF)'),
                onTap: () { Navigator.pop(context); _sharePdfReport(); },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble, color: Colors.green),
                title: const Text('WhatsApp मेसेज (Text)'),
                onTap: () { Navigator.pop(context); _shareTextReport(); },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: Colors.blue),
                title: const Text('इमेज शेअर करा (Share Image)'),
                onTap: () { Navigator.pop(context); _shareScreenshot(); },
              ),
              ListTile(
                leading: const Icon(Icons.save_alt, color: Colors.purple),
                title: const Text('गॅलरीत सेव्ह करा (Save to Gallery)'),
                onTap: () { Navigator.pop(context); _saveToGallery(); },
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activeProfileId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('डॅशबोर्ड'),
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: _showExportOptions),
        ]
      ),
      body: StreamBuilder<List<Transaction>>(
        stream: _selectedProfileId == null 
            ? database.watchAllTransactionsForAllProfiles()
            : database.watchAllTransactionsForAnalytics(_selectedProfileId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          _currentTransactions = snapshot.data ?? [];
          final allTxs = _currentTransactions;
          final startDate = _getStartDate();
          final filteredTxs = allTxs.where((t) => t.timestamp.isAfter(startDate)).toList();

          double totalIncome = 0;
          double totalExpense = 0;
          Map<String, double> categoryExp = {};
          Map<DateTime, double> dailyIncome = {};
          Map<DateTime, double> dailyExpense = {};

          for (var tx in filteredTxs) {
            if (tx.type == 'Income') {
              totalIncome += tx.amount;
              final d = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
              dailyIncome[d] = (dailyIncome[d] ?? 0) + tx.amount;
            } else if (tx.type == 'Expense') {
              totalExpense += tx.amount;
              final cat = tx.categoryName ?? 'अज्ञात';
              categoryExp[cat] = (categoryExp[cat] ?? 0) + tx.amount;
              final d = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
              dailyExpense[d] = (dailyExpense[d] ?? 0) + tx.amount;
            }
          }

          var sortedCat = categoryExp.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          if (sortedCat.length > 5) sortedCat = sortedCat.sublist(0, 5);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int?>(
                  value: _selectedProfileId,
                  decoration: const InputDecoration(labelText: 'प्रोफाइल निवडा (Profile)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("All Profiles (सर्व)")),
                    ..._profiles.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
                  ],
                  onChanged: (val) {
                    setState(() => _selectedProfileId = val);
                  },
                ),
                const SizedBox(height: 10),
                _buildTimeFilters(),
                const SizedBox(height: 20),
                RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor, // Ensure proper background in screenshot
                    child: Column(
                      children: [
                        _buildSummaryCards(totalIncome, totalExpense),
                        const SizedBox(height: 16),
                        _buildMoMComparison(allTxs),
                        const SizedBox(height: 30),
                        if (sortedCat.isNotEmpty) _buildPieChart(sortedCat),
                        if (dailyIncome.isNotEmpty || dailyExpense.isNotEmpty) ...[
                          const SizedBox(height: 30),
                           _buildTrendChart(dailyIncome, dailyExpense, startDate, DateTime.now()),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      )
    );
  }

  Widget _buildMoMComparison(List<Transaction> allTxs) {
    final now = DateTime.now();
    final firstDayThisMonth = DateTime(now.year, now.month, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayLastMonth = DateTime(now.year, now.month, 0);

    double thisMonthExp = 0;
    double lastMonthExp = 0;

    for (var tx in allTxs) {
      if (tx.type == 'Expense') {
        if (tx.timestamp.isAfter(firstDayThisMonth.subtract(const Duration(seconds: 1)))) {
          thisMonthExp += tx.amount;
        } else if (tx.timestamp.isAfter(firstDayLastMonth.subtract(const Duration(seconds: 1))) && 
                   tx.timestamp.isBefore(lastDayLastMonth.add(const Duration(days: 1)))) {
          lastMonthExp += tx.amount;
        }
      }
    }

    final diff = thisMonthExp - lastMonthExp;
    final percent = lastMonthExp > 0 ? (diff / lastMonthExp) * 100 : 0.0;
    final isIncrease = diff > 0;

    return Card(
      elevation: 0,
      color: Colors.indigo.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('मागील महिन्याशी तुलना', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${isIncrease ? '+' : ''}${percent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: isIncrease ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (lastMonthExp > 0 && thisMonthExp < lastMonthExp * 2) ? thisMonthExp / (lastMonthExp * 2) : 0.5,
              backgroundColor: Colors.white,
              color: isIncrease ? Colors.red : Colors.green,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              'या महिन्यात: ₹${thisMonthExp.toStringAsFixed(0)} | मागील महिन्यात: ₹${lastMonthExp.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_filters.length, (index) {
          final isSelected = _timeFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(_filters[index]),
              selected: isSelected,
              onSelected: (val) {
                if (val) setState(() => _timeFilterIndex = index);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCards(double inc, double exp) {
    return Row(
      children: [
        Expanded(child: Card(
          color: Colors.green.shade50,
          child: Padding(padding: const EdgeInsets.all(16), child: Column(
            children: [
              const Text('जमा', style: TextStyle(color: Colors.green)),
              Text('₹${inc.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ]
          ))
        )),
        const SizedBox(width: 16),
        Expanded(child: Card(
          color: Colors.red.shade50,
          child: Padding(padding: const EdgeInsets.all(16), child: Column(
            children: [
              const Text('खर्च', style: TextStyle(color: Colors.red)),
              Text('₹${exp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)),
            ]
          ))
        )),
      ]
    );
  }

  Widget _buildPieChart(List<MapEntry<String, double>> categories) {
    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.brown];
    double sum = categories.fold(0, (prev, e) => prev + e.value);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('कॅटेगरीनुसार खर्च', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categories.asMap().entries.map((e) {
                    final isTouched = false;
                    final rad = isTouched ? 60.0 : 50.0;
                    return PieChartSectionData(
                      color: colors[e.key % colors.length],
                      value: e.value.value,
                      title: '${((e.value.value / sum) * 100).toStringAsFixed(0)}%',
                      radius: rad,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                )
              )
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8, runSpacing: 4,
              children: categories.asMap().entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, color: colors[e.key % colors.length]),
                    const SizedBox(width: 4),
                    Text('${e.value.key} (₹${e.value.value.toInt()})', style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            )
          ],
        )
      )
    );
  }

  Widget _buildTrendChart(Map<DateTime, double> inc, Map<DateTime, double> exp, DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    final List<BarChartGroupData> barGroups = [];
    double maxY = 0;

    for (int i = 0; i < days; i++) {
        final d = start.add(Duration(days: i));
        final dateKey = DateTime(d.year, d.month, d.day);
        final iVal = inc[dateKey] ?? 0;
        final eVal = exp[dateKey] ?? 0;
        if (iVal > maxY) maxY = iVal;
        if (eVal > maxY) maxY = eVal;

        barGroups.add(BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: iVal, color: Colors.green, width: 8),
            BarChartRodData(toY: eVal, color: Colors.red, width: 8),
          ]
        ));
    }

    // Limit large charts logic (e.g. Yearly to months) can be added here, currently simply maps days to X
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('जमा आणि खर्च ट्रेंड', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.3,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: days <= 10, // Show individual days only if range is small
                        getTitlesWidget: (val, meta) {
                          final date = start.add(Duration(days: val.toInt()));
                          return Text('${date.day}', style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '₹${rod.toY.toInt()}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                )
              )
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend(Colors.green, 'जमा'),
                const SizedBox(width: 20),
                _buildLegend(Colors.red, 'खर्च'),
              ],
            )
          ]
        )
      )
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
