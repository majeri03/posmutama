import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:pos_mutama/screens/reports/dashboard_view.dart';
import 'package:pos_mutama/screens/reports/transaction_detail_screen.dart';
import 'package:pos_mutama/utils/csv_helper.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionProvider);

    final searchedTransactions = allTransactions.where((t) {
      if (_searchQuery.isEmpty) return true;
      return t.id.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan ID transaksi...',
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Ekspor Transaksi Terfilter',
              onPressed: () async {
                await exportTransactionsToCsv(searchedTransactions);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Laporan berhasil diekspor')),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Dasbor'),
              Tab(icon: Icon(Icons.summarize), text: 'Ringkasan'),
              Tab(icon: Icon(Icons.check_circle), text: 'Lunas'),
              Tab(icon: Icon(Icons.credit_score), text: 'Utang/DP'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const DashboardView(),
            const SummaryView(),
            TransactionListView(transactions: searchedTransactions.where((t) => t.status == 'Lunas').toList()),
            TransactionListView(transactions: searchedTransactions.where((t) => t.status == 'Belum Lunas' || t.status == 'DP').toList()),
          ],
        ),
      ),
    );
  }
}

class SummaryView extends ConsumerWidget {
  const SummaryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalRevenue = ref.watch(transactionProvider.notifier).totalRevenue;
    final totalProfit = ref.watch(transactionProvider.notifier).totalProfit;
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.green, size: 40),
              title: const Text('Total Pendapatan (Lunas)'),
              subtitle: const Text('Dari semua transaksi lunas'),
              trailing: Text(numberFormat.format(totalRevenue), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.blue, size: 40),
              title: const Text('Total Keuntungan (Lunas)'),
              subtitle: const Text('Dari semua transaksi lunas'),
              trailing: Text(numberFormat.format(totalProfit), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class TransactionListView extends StatelessWidget {
  final List<Transaction> transactions;

  const TransactionListView({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('Tidak ada transaksi untuk ditampilkan.'));
    }

    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text('ID: ${transaction.id.substring(0, 8)}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pelanggan: ${transaction.customer?.name ?? 'Umum'}'),
                Text(DateFormat('dd MMM yy, HH:mm').format(transaction.date)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(numberFormat.format(transaction.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (transaction.status != 'Lunas')
                  Text(
                    transaction.status,
                    style: TextStyle(
                      color: transaction.status == 'DP' ? Colors.blue : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TransactionDetailScreen(transaction: transaction),
                ),
              );
            },
          ),
        );
      },
    );
  }
}