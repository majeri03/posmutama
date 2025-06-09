import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/reports_filter_provider.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(reportMetricsProvider);
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const FilterChips(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: MetricCard(title: 'Pendapatan', value: numberFormat.format(metrics['revenue']), icon: Icons.attach_money, color: Colors.green)),
            const SizedBox(width: 16),
            Expanded(child: MetricCard(title: 'Keuntungan', value: numberFormat.format(metrics['profit']), icon: Icons.trending_up, color: Colors.blue)),
          ],
        ),
        const SizedBox(height: 16),
         Row(
          children: [
            Expanded(child: MetricCard(title: 'Jml Transaksi', value: metrics['transactionCount'].toString(), icon: Icons.receipt_long, color: Colors.orange)),
            const SizedBox(width: 16),
            Expanded(child: MetricCard(title: 'Transaksi Lunas', value: metrics['paidTransactionCount'].toString(), icon: Icons.check_circle, color: Colors.purple)),
          ],
        ),
        const SizedBox(height: 24),
        Text("Grafik Penjualan (Lunas)", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const SalesChart(),
      ],
    );
  }
}

class FilterChips extends ConsumerWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = ref.watch(dateFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: DateFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(_filterToString(filter)),
              selected: selectedFilter == filter,
              onSelected: (isSelected) {
                if (isSelected) {
                  ref.read(dateFilterProvider.notifier).state = filter;
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterToString(DateFilter filter) {
    switch (filter) {
      case DateFilter.all:
        return 'Semua';
      case DateFilter.today:
        return 'Hari Ini';
      case DateFilter.thisWeek:
        return 'Minggu Ini';
      case DateFilter.thisMonth:
        return 'Bulan Ini';
      case DateFilter.thisYear:
        return 'Tahun Ini';
    }
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class SalesChart extends ConsumerWidget {
  const SalesChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(filteredTransactionsProvider).where((t) => t.status == 'Lunas').toList();
    final filter = ref.watch(dateFilterProvider);

    if (transactions.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Tidak ada data penjualan untuk ditampilkan.")),
      );
    }
    
    final spots = _getChartData(transactions, filter);

    return SizedBox(
      height: 250,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) => _bottomTitleWidgets(value, meta, filter, transactions),
              ),
            ),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.indigo,
              barWidth: 5,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.indigo.withAlpha(77),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<FlSpot> _getChartData(List<Transaction> transactions, DateFilter filter) {
    Map<int, double> salesData = {};

    for (var tx in transactions) {
      int key;
      switch (filter) {
        case DateFilter.today:
          key = tx.date.hour; // Group by hour
          break;
        case DateFilter.thisWeek:
          key = tx.date.weekday; // Group by day of week (1=Mon, 7=Sun)
          break;
        case DateFilter.thisMonth:
          key = tx.date.day; // Group by day of month
          break;
        case DateFilter.thisYear:
          key = tx.date.month; // Group by month
          break;
        case DateFilter.all:
          key = tx.date.month; // Default to grouping by month for 'all'
          break;
      }
      salesData.update(key, (value) => value + tx.totalAmount, ifAbsent: () => tx.totalAmount.toDouble());
    }

    if (salesData.isEmpty) return [const FlSpot(0,0)];

    List<int> sortedKeys = salesData.keys.toList()..sort();
    return sortedKeys.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), salesData[entry.value]!);
    }).toList();
  }

  Widget _bottomTitleWidgets(double value, TitleMeta meta, DateFilter filter, List<Transaction> transactions) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    String text;
    final int index = value.toInt();

     Map<int, double> salesData = {};
     for (var tx in transactions) {
      int key;
      switch (filter) {
        case DateFilter.today: key = tx.date.hour; break;
        case DateFilter.thisWeek: key = tx.date.weekday; break;
        case DateFilter.thisMonth: key = tx.date.day; break;
        case DateFilter.thisYear: key = tx.date.month; break;
        case DateFilter.all: key = tx.date.month; break;
      }
      salesData.update(key, (val) => val + tx.totalAmount, ifAbsent: () => tx.totalAmount.toDouble());
    }
    List<int> sortedKeys = salesData.keys.toList()..sort();

    if(index >= sortedKeys.length) return const SizedBox.shrink();
    
    final key = sortedKeys[index];

    switch (filter) {
      case DateFilter.today:
        text = '$key:00';
        break;
      case DateFilter.thisWeek:
        text = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][key - 1];
        break;
      case DateFilter.thisMonth:
        text = key.toString();
        break;
      case DateFilter.thisYear:
      case DateFilter.all:
        text = DateFormat('MMM').format(DateTime(0, key));
        break;
    }
    return SideTitleWidget(axisSide: meta.axisSide, child: Text(text, style: style));
  }
}
