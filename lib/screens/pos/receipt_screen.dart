import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/store_info_provider.dart';
import 'package:pos_mutama/screens/main_screen.dart';
import 'package:pos_mutama/utils/receipt_generator.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReceiptScreen extends ConsumerWidget {
  final Transaction transaction;

  const ReceiptScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeInfo = ref.watch(storeInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi Berhasil'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            const SizedBox(height: 16),
            Text(
              'Transaksi berhasil disimpan!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('Cetak Struk'),
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
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.share),
              label: const Text('Bagikan Struk'),
              onPressed: () async {
                if (storeInfo != null) {
                  final pdfData = await generateReceipt(
                    transaction,
                    storeInfo.name,
                    storeInfo.address,
                    storeInfo.phone,
                  );
                  final xfile = XFile.fromData(
                    pdfData,
                    name: 'struk-${transaction.id.substring(0, 8)}.pdf',
                    mimeType: 'application/pdf',
                  );
                  await Share.shareXFiles([xfile], text: 'Struk Pembelian');
                }
              },
               style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
