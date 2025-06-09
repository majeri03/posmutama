import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/utils/receipt_generator.dart';
import 'package:printing/printing.dart';

class ReceiptScreen extends ConsumerWidget {
  final Transaction transaction;

  const ReceiptScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cari data pelanggan jika ada, untuk ditampilkan di struk
    final Customer? customer = transaction.idPelanggan != null
        ? ref.watch(customerProvider).firstWhere((c) => c.id == transaction.idPelanggan)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Struk Transaksi'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          // Kembali ke halaman awal (kasir) saat ditutup
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: PdfPreview(
        build: (format) => ReceiptGenerator.generateReceiptPdf(transaction, customer),
        // Opsi tambahan untuk kustomisasi
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
