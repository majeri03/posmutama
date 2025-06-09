import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/store_info_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:pos_mutama/utils/receipt_generator.dart';
import 'package:printing/printing.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final Transaction transaction;

  const TransactionDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeInfo = ref.watch(storeInfoProvider);
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    void showPayDebtConfirmation() {
      showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: const Text('Konfirmasi Pembayaran'),
            content: Text('Apakah Anda yakin ingin melunasi utang untuk transaksi #${transaction.id.substring(0, 8)}?'),
            actions: <Widget>[
              TextButton(
                child: const Text('Batal'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
              ElevatedButton(
                child: const Text('Ya, LUNASI'),
                onPressed: () {
                  ref.read(transactionProvider.notifier).payDebt(transaction.id);
                  Navigator.of(ctx).pop(); 
                  Navigator.of(context).pop(); 
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Ulang Struk',
            onPressed: () async {
              if (storeInfo != null) {
                final pdfData = await generateReceipt(
                  transaction,
                  storeInfo.name,
                  storeInfo.address,
                );
                await Printing.layoutPdf(
                  onLayout: (format) async => pdfData,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Informasi toko belum diatur.')),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDetailRow('ID Transaksi:', transaction.id.substring(0, 8)),
                  _buildDetailRow('Tanggal:', DateFormat('dd MMM yyyy, HH:mm').format(transaction.date.toLocal())),
                  _buildDetailRow( 'Status:', transaction.status,
                    valueColor: transaction.status == 'Lunas' ? Colors.green : Colors.orange,
                  ),
                  _buildDetailRow('Pelanggan:', transaction.customer?.name ?? 'Umum'),
                  const Divider(height: 20),
                  _buildDetailRow('Total Belanja:', numberFormat.format(transaction.totalAmount)),
                  _buildDetailRow('Jumlah Bayar:', numberFormat.format(transaction.paidAmount)),
                  _buildDetailRow('Kembalian:', numberFormat.format(transaction.changeAmount)),
                  _buildDetailRow('Metode Bayar:', transaction.paymentMethod),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Item yang Dibeli:', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          ...transaction.items.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.name),
              subtitle: Text('${item.quantity} x ${numberFormat.format(item.price)}'),
              trailing: Text(numberFormat.format(item.quantity * item.price)),
            ),
          )),
        ],
      ),
      bottomNavigationBar: transaction.status == 'Belum Lunas'
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('LUNASI UTANG'),
                onPressed: showPayDebtConfirmation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
