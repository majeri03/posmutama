import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // NEW: Controller untuk mengelola kamera scanner
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal, // Kecepatan deteksi
    facing: CameraFacing.back, // Gunakan kamera belakang
  );

  // NEW: Flag untuk memastikan kita hanya memproses satu hasil scan
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Dapatkan ukuran area scan window
    final scanWindow = Rect.fromCenter(
      center: MediaQuery.of(context).size.center(Offset.zero),
      width: 250,
      height: 150,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Barcode'),
        actions: [
          // NEW: Tombol untuk menyalakan senter
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
          ),
        ],
      ),
      // NEW: Gunakan Stack untuk menumpuk overlay di atas kamera
      body: Stack(
        children: [
          // Layer 1: Tampilan kamera dari scanner
          MobileScanner(
            controller: _controller,
            scanWindow: scanWindow, // Fokuskan area scan ke window yang ditentukan
            onDetect: (capture) {
              // Jika sedang memproses, abaikan hasil baru
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  setState(() {
                    _isProcessing = true; // Tandai sedang memproses
                  });
                  // Kirim hasil kembali ke halaman sebelumnya
                  Navigator.of(context).pop(code);
                }
              }
            },
          ),
          // Layer 2: Overlay untuk panduan visual
          CustomPaint(
            painter: ScannerOverlay(scanWindow: scanWindow),
          ),
          // Layer 3: Teks instruksi untuk pengguna
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.only(bottom: 80),
              color: Colors.transparent,
              child: const Text(
                'Posisikan barcode di dalam area kotak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  backgroundColor: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// NEW: Widget CustomPaint untuk membuat overlay dengan "lubang" di tengah
class ScannerOverlay extends CustomPainter {
  final Rect scanWindow;

  ScannerOverlay({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.largest);
    final cutoutPath = Path()..addRect(scanWindow);

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.6);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Gabungkan path untuk membuat "lubang"
    final overlayPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // Gambar overlay gelap
    canvas.drawPath(overlayPath, backgroundPaint);

    // Gambar border putih di sekitar scan window
    canvas.drawRect(scanWindow, borderPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlay oldDelegate) {
    return oldDelegate.scanWindow != scanWindow;
  }
}