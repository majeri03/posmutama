import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';

// Enum untuk tipe filter laporan
enum ReportFilter { daily, weekly, monthly, allTime }

// Provider untuk menyimpan state filter yang sedang aktif
final reportFilterProvider = StateProvider<ReportFilter>((ref) => ReportFilter.daily);

// Provider turunan untuk memfilter transaksi berdasarkan state filter
final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final filter = ref.watch(reportFilterProvider);
  final transactions = ref.watch(transactionProvider);
  final now = DateTime.now();

  return transactions.where((tx) {
    switch (filter) {
      case ReportFilter.daily:
        return tx.tanggalTransaksi.year == now.year &&
               tx.tanggalTransaksi.month == now.month &&
               tx.tanggalTransaksi.day == now.day;
      case ReportFilter.weekly:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return tx.tanggalTransaksi.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
               tx.tanggalTransaksi.isBefore(endOfWeek.add(const Duration(days: 1)));
      case ReportFilter.monthly:
        return tx.tanggalTransaksi.year == now.year &&
               tx.tanggalTransaksi.month == now.month;
      case ReportFilter.allTime:
        return true;
    }
  }).toList();
});

// Provider untuk data statistik (Omzet dan Keuntungan)
final salesStatsProvider = Provider<Map<String, int>>((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  int totalOmzet = 0;
  int totalKeuntungan = 0;

  for (var tx in transactions) {
    totalOmzet += tx.totalBelanja;
    totalKeuntungan += tx.totalKeuntungan;
  }

  return {
    'omzet': totalOmzet,
    'profit': totalKeuntungan,
  };
});

// Provider untuk daftar pelanggan yang memiliki utang
final customersInDebtProvider = Provider<List<Customer>>((ref) {
  final customers = ref.watch(customerProvider);
  return customers.where((c) => c.totalUtang > 0).toList();
});


class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.assessment), text: 'Penjualan'),
              Tab(icon: Icon(Icons.person_pin), text: 'Utang Pelanggan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SalesReportsTab(),
            DebtReportsTab(),
          ],
        ),
      ),
    );
  }
}

class SalesReportsTab extends ConsumerWidget {
  const SalesReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(salesStatsProvider);
    final transactions = ref.watch(filteredTransactionsProvider);
    final activeFilter = ref.watch(reportFilterProvider);
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final dateFormat = DateFormat('dd MMM, HH:mm');

    return Column(
      children: [
        // Tombol Filter
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<ReportFilter>(
            segments: const <ButtonSegment<ReportFilter>>[
              ButtonSegment(value: ReportFilter.daily, label: Text('Harian')),
              ButtonSegment(value: ReportFilter.weekly, label: Text('Mingguan')),
              ButtonSegment(value: ReportFilter.monthly, label: Text('Bulanan')),
              ButtonSegment(value: ReportFilter.allTime, label: Text('Semua')),
            ],
            selected: {activeFilter},
            onSelectionChanged: (Set<ReportFilter> newSelection) {
              ref.read(reportFilterProvider.notifier).state = newSelection.first;
            },
          ),
        ),
        // Kartu Statistik
        Row(
          children: [
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Total Omzet', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(numberFormat.format(stats['omzet']), style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('Total Keuntungan', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(numberFormat.format(stats['profit']), style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
        const Divider(),
        // Daftar Transaksi
        Expanded(
          child: transactions.isEmpty
              ? const Center(child: Text('Tidak ada transaksi pada periode ini.'))
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return ListTile(
                      title: Text(tx.id),
                      subtitle: Text(dateFormat.format(tx.tanggalTransaksi)),
                      trailing: Text(numberFormat.format(tx.totalBelanja)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class DebtReportsTab extends ConsumerWidget {
  const DebtReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersInDebt = ref.watch(customersInDebtProvider);
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return customersInDebt.isEmpty
        ? const Center(child: Text('Tidak ada pelanggan yang memiliki utang.'))
        : ListView.builder(
            itemCount: customersInDebt.length,
            itemBuilder: (context, index) {
              final customer = customersInDebt[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(customer.namaPelanggan),
                  subtitle: Text('No. HP: ${customer.noHp ?? '-'}'),
                  trailing: Text(
                    numberFormat.format(customer.totalUtang),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
  }
}
