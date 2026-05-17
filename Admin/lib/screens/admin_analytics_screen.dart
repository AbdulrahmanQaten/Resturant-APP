import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:remixicon/remixicon.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

enum DateRange { today, week, month, year }

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  String? _errorMessage;
  DateRange _selectedRange = DateRange.month;

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateStatistics();
  }

  Future<void> _fetchAndCalculateStatistics() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DateTime now = DateTime.now();
      DateTime startDate;
      switch (_selectedRange) {
        case DateRange.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case DateRange.week:
          startDate = now.subtract(const Duration(days: 7));
          break;
        case DateRange.month:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case DateRange.year:
          startDate = DateTime(now.year, 1, 1);
          break;
      }

      final ordersSnapshot = await FirebaseFirestore.instance
          .collectionGroup('orders')
          .where('orderDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      final favoritesSnapshot = await FirebaseFirestore.instance
          .collectionGroup('favorites')
          .where('addedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      final allMealsSnapshot =
          await FirebaseFirestore.instance.collection('meals').get();

      final allOrders = ordersSnapshot.docs;
      final completedOrders = allOrders
          .where((doc) => doc.data()['status'] == 'تم التوصيل')
          .toList();
      final cancelledOrders =
          allOrders.where((doc) => doc.data()['status'] == 'ملغي').toList();
      final favorites = favoritesSnapshot.docs;
      final allMealsMap = {
        for (var doc in allMealsSnapshot.docs) doc.id: doc.data()
      };

      double totalRevenue = 0;
      Map<String, int> mealSales = {};
      Map<int, double> salesByHour =
          Map.fromIterables(List.generate(24, (i) => i), List.filled(24, 0.0));
      Map<String, int> zoneFrequency = {};

      for (var doc in completedOrders) {
        final data = doc.data();
        totalRevenue += (data['totalPrice'] as num?)?.toDouble() ?? 0.0;

        final date = (data['orderDate'] as Timestamp?)?.toDate();
        if (date != null) {
          salesByHour[date.hour] = (salesByHour[date.hour] ?? 0) +
              ((data['totalPrice'] as num?)?.toDouble() ?? 0.0);
        }

        final zoneName = data['deliveryZone'] as String?;
        if (zoneName != null) {
          zoneFrequency[zoneName] = (zoneFrequency[zoneName] ?? 0) + 1;
        }

        final items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          final mealName = item['name'] as String?;
          if (mealName != null) {
            mealSales[mealName] =
                (mealSales[mealName] ?? 0) + (item['quantity'] as int? ?? 1);
          }
        }
      }

      Map<String, int> mealFavorites = {};
      for (var doc in favorites) {
        final mealId = doc.id;
        if (allMealsMap.containsKey(mealId)) {
          final mealName = allMealsMap[mealId]!['name'] as String?;
          if (mealName != null) {
            mealFavorites[mealName] = (mealFavorites[mealName] ?? 0) + 1;
          }
        }
      }

      var sortedSales = mealSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      var sortedFavorites = mealFavorites.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      var sortedZones = zoneFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (mounted) {
        setState(() {
          _stats = {
            'totalRevenue': totalRevenue,
            'totalOrders': allOrders.length,
            'completedOrders': completedOrders.length,
            'cancelledOrders': cancelledOrders.length,
            'top5Meals': Map.fromEntries(sortedSales.take(5)),
            'top5Favorites': Map.fromEntries(sortedFavorites.take(5)),
            'top5Zones': Map.fromEntries(sortedZones.take(5)),
            'salesByHour': salesByHour,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error calculating statistics: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'فشل تحميل الإحصائيات. يرجى التأكد من جهوزية الفهارس في قاعدة البيانات.';
        });
      }
    }
  }

  Future<void> _exportToExcel() async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['الإحصائيات'];

    sheetObject.appendRow([
      TextCellValue('المؤشر'),
      TextCellValue('القيمة'),
    ]);

    sheetObject.appendRow([
      TextCellValue('إجمالي الدخل'),
      TextCellValue('${_stats['totalRevenue'] ?? 0} ريال')
    ]);
    sheetObject.appendRow([
      TextCellValue('إجمالي الطلبات'),
      TextCellValue((_stats['totalOrders'] ?? 0).toString())
    ]);
    sheetObject.appendRow([
      TextCellValue('الطلبات المكتملة'),
      TextCellValue((_stats['completedOrders'] ?? 0).toString())
    ]);
    sheetObject.appendRow([
      TextCellValue('الطلبات الملغية'),
      TextCellValue((_stats['cancelledOrders'] ?? 0).toString())
    ]);

    sheetObject.appendRow([TextCellValue('')]);
    sheetObject.appendRow([TextCellValue('الوجبات الأكثر مبيعاً')]);
    (_stats['top5Meals'] as Map<String, int>).forEach((key, value) {
      sheetObject
          .appendRow([TextCellValue(key), TextCellValue(value.toString())]);
    });

    sheetObject.appendRow([TextCellValue('')]);
    sheetObject.appendRow([TextCellValue('الوجبات الأكثر تفضيلاً')]);
    (_stats['top5Favorites'] as Map<String, int>).forEach((key, value) {
      sheetObject
          .appendRow([TextCellValue(key), TextCellValue(value.toString())]);
    });

    sheetObject.appendRow([TextCellValue('')]);
    sheetObject.appendRow([TextCellValue('المناطق الأكثر طلباً')]);
    (_stats['top5Zones'] as Map<String, int>).forEach((key, value) {
      sheetObject
          .appendRow([TextCellValue(key), TextCellValue(value.toString())]);
    });

    final bytes = excel.save();
    if (bytes == null) return;

    final fileName =
        "statistics_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.xlsx";

    if (kIsWeb) {
      // --- طريقة الويب (لـ FlutLab) ---
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('بدء تنزيل الملف... يرجى تفقد تنزيلات المتصفح.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // --- طريقة الهاتف (Android/iOS) ---
      if (await Permission.storage.request().isGranted) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final path = '${directory.path}/$fileName';
          final file = File(path);
          await file.writeAsBytes(bytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حفظ الملف في: $path'),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: 'فتح',
                  onPressed: () {
                    OpenFile.open(path);
                  },
                ),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('تم رفض إذن الوصول إلى التخزين.'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات والتقارير'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Remix.file_excel_2_line),
            tooltip: 'تصدير إلى Excel',
            onPressed: _isLoading ? null : _exportToExcel,
          ),
          IconButton(
            icon: const Icon(Remix.refresh_line),
            onPressed: _isLoading ? null : _fetchAndCalculateStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _errorMessage != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_errorMessage!, textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _fetchAndCalculateStatistics,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDateFilter(),
                        const SizedBox(height: 24),
                        _buildKPIs(),
                        const SizedBox(height: 24),
                        Text('أوقات الذروة (حسب الدخل)',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        _buildSalesByHourChart(),
                        const SizedBox(height: 24),
                        _buildTopLists(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildDateFilter() {
    return SegmentedButton<DateRange>(
      segments: const <ButtonSegment<DateRange>>[
        ButtonSegment<DateRange>(value: DateRange.today, label: Text('اليوم')),
        ButtonSegment<DateRange>(value: DateRange.week, label: Text('أسبوع')),
        ButtonSegment<DateRange>(value: DateRange.month, label: Text('شهر')),
        ButtonSegment<DateRange>(value: DateRange.year, label: Text('سنة')),
      ],
      selected: {_selectedRange},
      onSelectionChanged: (Set<DateRange> newSelection) {
        setState(() {
          _selectedRange = newSelection.first;
          _fetchAndCalculateStatistics();
        });
      },
    );
  }

  Widget _buildKPIs() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(context,
            icon: Remix.money_dollar_circle_line,
            label: 'إجمالي الدخل',
            value:
                '${NumberFormat.compact(locale: 'ar').format(_stats['totalRevenue'] ?? 0)} ريال',
            color: Colors.green),
        _buildStatCard(context,
            icon: Remix.shopping_bag_3_line,
            label: 'إجمالي الطلبات',
            value: (_stats['totalOrders'] ?? 0).toString(),
            color: Colors.blue),
        _buildStatCard(context,
            icon: Remix.checkbox_circle_line,
            label: 'الطلبات المكتملة',
            value: (_stats['completedOrders'] ?? 0).toString(),
            color: Colors.teal),
        _buildStatCard(context,
            icon: Remix.close_circle_line,
            label: 'الطلبات الملغية',
            value: (_stats['cancelledOrders'] ?? 0).toString(),
            color: Colors.red),
      ],
    );
  }

  Widget _buildSalesByHourChart() {
    Map<int, double> salesData = _stats['salesByHour'] ?? {};
    if (salesData.values.every((v) => v == 0))
      return const SizedBox(
          height: 200,
          child:
              Center(child: Text('لا توجد بيانات كافية لعرض الرسم البياني.')));

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: salesData.entries.map((entry) {
            return BarChartGroupData(x: entry.key, barRods: [
              BarChartRodData(
                  toY: entry.value,
                  color: Theme.of(context).colorScheme.primary,
                  width: 10,
                  borderRadius: BorderRadius.circular(4))
            ]);
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Text('${value.toInt()}',
                          style: const TextStyle(fontSize: 10));
                    },
                    interval: 3)),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Widget _buildTopLists() {
    return Column(
      children: [
        _buildListCard('الأكثر مبيعاً', _stats['top5Meals'] ?? {}),
        const SizedBox(height: 16),
        _buildListCard('الأكثر تفضيلاً', _stats['top5Favorites'] ?? {}),
        const SizedBox(height: 16),
        _buildListCard('المناطق الأكثر طلباً', _stats['top5Zones'] ?? {}),
      ],
    );
  }

  Widget _buildListCard(String title, Map<String, int> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            if (data.isEmpty) const Text('لا توجد بيانات.'),
            ...data.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(entry.key,
                                  overflow: TextOverflow.ellipsis)),
                          Text(entry.value.toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(label, style: TextStyle(color: Colors.grey[600])),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  // ---===  الإصلاح هنا: تعديل الواجهة الهيكلية  ===---
  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
                4,
                (_) => Expanded(
                    child: Container(
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8))))),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: List.generate(
                4,
                (index) => Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    shape: BoxShape.circle)),
                            Container(
                                width: 100,
                                height: 14,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8))),
                            Container(
                                width: 120,
                                height: 24,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8))),
                          ],
                        ),
                      ),
                    )),
          ),
          const SizedBox(height: 24),
          Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15))),
          const SizedBox(height: 24),
          Column(
            children: List.generate(
                3,
                (_) => Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: 150,
                                height: 20,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8))),
                            const Divider(),
                            ...List.generate(
                                3,
                                (_) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                              child: Container(
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)))),
                                          const SizedBox(width: 16),
                                          Container(
                                              width: 30,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8))),
                                        ],
                                      ),
                                    )),
                          ],
                        ),
                      ),
                    )),
          )
        ],
      ),
    );
  }
}
