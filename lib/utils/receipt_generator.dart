import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_mutama/models/transaction.dart';

Future<Uint8List> generateReceipt(
  Transaction transaction,
  String storeName,
  String storeAddress,
  String? storePhone,
) async {
  final pdf = pw.Document();

  // --- PERUBAHAN: Memuat gambar logo Anda dari assets ---
  final ByteData logoData = await rootBundle.load('assets/images/icon.png');
  final Uint8List logoBytes = logoData.buffer.asUint8List();
  final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

  // Memuat font kustom dari assets
  final fontData = await rootBundle.load("assets/fonts/RobotoMono-Regular.ttf");
  final ttf = pw.Font.ttf(fontData);
  final receiptTheme = pw.ThemeData.withFont(
    base: ttf,
    bold: ttf, // Anda bisa menggunakan varian Bold jika ada
  );

  // Helper untuk format angka dan tanggal
  final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final quantityFormat = NumberFormat.decimalPattern('id_ID');
  final dateFormat = DateFormat('dd/MM/yyyy', 'id_ID');
  final timeFormat = DateFormat('HH:mm:ss', 'id_ID');

  // --- PERUBAHAN: Garis pemisah yang lebih rapi ---
  final divider = pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Divider(
      height: 1,
      borderStyle: pw.BorderStyle.dotted,
    ),
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80, // Ukuran kertas struk thermal 80mm
      margin: const pw.EdgeInsets.all(12),
      theme: receiptTheme,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ================== HEADER ==================
            // --- PERUBAHAN: Layout header baru dengan logo gambar ---
            pw.Row(
              children: [
                pw.SizedBox(
                  height: 40,
                  width: 40,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(width: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(storeName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 8)),
                    if (storePhone != null && storePhone.isNotEmpty)
                      pw.Text('Telp: $storePhone', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            
            // ================== INFO TRANSAKSI ==================
            // --- PERUBAHAN: Layout info transaksi lebih rapi ---
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                  '${dateFormat.format(transaction.date)} ${timeFormat.format(transaction.date)}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('No. Struk:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(transaction.id.substring(0, 13), style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Kasir:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Admin', style: const pw.TextStyle(fontSize: 8)), // Ganti dengan nama kasir jika ada
              ],
            ),
             pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Pelanggan:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(transaction.customer?.name ?? 'Umum', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            divider,

            // ================== DAFTAR ITEM ==================
            // --- PERUBAHAN: Menampilkan detail item dengan satuan dan subtotal ---
            for (final item in transaction.items)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(item.name, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        // Menampilkan: 2 Sak x Rp 55.000
                        pw.Text(
                          '  ${quantityFormat.format(item.quantity)} ${item.unitName} x ${numberFormat.format(item.price)}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        // Menampilkan subtotal per item
                        pw.Text(
                          numberFormat.format(item.price * item.quantity),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            divider,

            // ================== RINGKASAN TOTAL ==================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Item:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                  quantityFormat.format(transaction.items.fold(0, (sum, item) => sum + item.quantity)),
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Belanja', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                  numberFormat.format(transaction.totalAmount),
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            if (transaction.paymentHistory.length > 1) ...[
              pw.SizedBox(height: 8),
              pw.Text('RIWAYAT PEMBAYARAN:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              for (final record in transaction.paymentHistory)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(DateFormat('dd/MM/yy').format(record.date), style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(numberFormat.format(record.amount), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              divider,
            ],

            // Menampilkan detail pembayaran hanya jika sudah ada pembayaran
            if (transaction.status == 'Lunas' || transaction.status == 'DP') ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar (${transaction.paymentMethod})', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(numberFormat.format(transaction.paidAmount), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembali', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(numberFormat.format(transaction.changeAmount), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ],

            // Menampilkan status jika belum lunas
            if (transaction.status != 'Lunas') ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Status', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(transaction.status, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.red)),
                ],
              ),
            ],
            
            pw.SizedBox(height: 12),
            divider,
            
            // ================== FOOTER ==================
            pw.Center(
              child: pw.Text('Terima Kasih Telah Berbelanja!', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
            pw.Center(
              child: pw.Text('Barang yang sudah dibeli tidak dapat dikembalikan.', style: const pw.TextStyle(fontSize: 7)),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}