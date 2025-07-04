import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/providers/store_info_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:pos_mutama/utils/receipt_generator.dart';
import 'package:printing/printing.dart';
import 'package:pos_mutama/screens/reports/edit_transaction_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTransactions = ref.watch(transactionProvider);
    final transaction = allTransactions.firstWhere((t) => t.id == transactionId, orElse: () => allTransactions.first);
    final storeInfo = ref.watch(storeInfoProvider);
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final remainingAmount = transaction.totalAmount - transaction.paidAmount;

    void showPayDebtDialog() {
      showDialog(
        context: context,
        builder: (ctx) => PayDebtDialog(
          transactionId: transaction.id,
          remainingAmount: remainingAmount,
        ),
      ).then((_) {
        // Refresh a "copy" of the provider to force UI update on this screen
        ref.refresh(transactionProvider);
      });
    }

    Color getStatusColor(String status) {
      switch (status) {
        case 'Lunas':
          return Colors.green;
        case 'DP':
          return Colors.blue;
        case 'Belum Lunas':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Transaksi',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => EditTransactionScreen(originalTransaction: transaction)
              ));
            },
          ),
          // --- TAMBAHKAN TOMBOL HAPUS ---
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Hapus Transaksi',
            onPressed: () {
              // Tampilkan dialog konfirmasi yang aman
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hapus Transaksi Ini?'),
                  content: const Text(
                      'Aksi ini tidak dapat dibatalkan. Stok barang akan dikembalikan. Anda yakin?'),
                  actions: [
                    TextButton(
                      child: const Text('Batal'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await ref.read(transactionProvider.notifier).deleteTransaction(transaction.id);
                        if (context.mounted) {
                          Navigator.of(ctx).pop(); // Tutup dialog
                          Navigator.of(context).pop(); // Kembali dari detail screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaksi berhasil dihapus.')),
                          );
                        }
                      },
                      child: const Text('Ya, Hapus'),
                    )
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Cetak Ulang Struk',
            onPressed: () async {
              if (storeInfo != null) {
                final pdfData = await generateReceipt(
                  transaction,
                  storeInfo.name,
                  storeInfo.address,
                  storeInfo.phone,
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
                  _buildDetailRow(
                    'Status:',
                    transaction.status,
                    valueColor: getStatusColor(transaction.status),
                  ),
                  _buildDetailRow('Pelanggan:', transaction.customer?.name ?? 'Umum'),
                  const Divider(height: 20),
                  _buildDetailRow('Total Belanja:', numberFormat.format(transaction.totalAmount)),
                  _buildDetailRow('Sudah Dibayar:', numberFormat.format(transaction.paidAmount)),
                  if (transaction.status != 'Lunas')
                    _buildDetailRow(
                      'Sisa Utang:',
                      numberFormat.format(remainingAmount),
                      valueColor: Colors.red,
                    ),
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
          const SizedBox(height: 20),
          if (transaction.paymentHistory.isNotEmpty)
            Card(
              child: ExpansionTile(
                title: const Text('Riwayat Pembayaran'),
                leading: const Icon(Icons.history),
                initiallyExpanded: true,
                children: transaction.paymentHistory.map((record) {
                  return ListTile(
                    title: Text(numberFormat.format(record.amount)),
                    trailing: Text(DateFormat('dd/MM/yy HH:mm').format(record.date)),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: transaction.status != 'Lunas'
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('BAYAR UTANG'),
                onPressed: showPayDebtDialog,
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

class PayDebtDialog extends ConsumerStatefulWidget {
  final String transactionId;
  final int remainingAmount;

  const PayDebtDialog({
    super.key,
    required this.transactionId,
    required this.remainingAmount,
  });

  @override
  ConsumerState<PayDebtDialog> createState() => _PayDebtDialogState();
}

class _PayDebtDialogState extends ConsumerState<PayDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submitPayment() {
    if (_formKey.currentState!.validate()) {
      final amountToPay = int.parse(_amountController.text);
      ref.read(transactionProvider.notifier).recordDebtPayment(widget.transactionId, amountToPay);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil dicatat!'), backgroundColor: Colors.green)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return AlertDialog(
      title: const Text('Bayar Utang'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sisa utang saat ini: ${numberFormat.format(widget.remainingAmount)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah yang Dibayar',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                final amount = int.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Masukkan jumlah yang valid';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submitPayment,
          child: const Text('Proses Bayar'),
        ),
      ],
    );
  }
}