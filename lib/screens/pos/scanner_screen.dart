import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Barcode')),
      body: MobileScanner(
        // Izinkan semua jenis barcode dan QR code
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              // Kirim hasil scan kembali ke halaman sebelumnya
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}
