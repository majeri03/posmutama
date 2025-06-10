import 'dart:typed_data';

import 'package:flutter/services.dart'; // Diperlukan untuk memuat font ikon
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

  // Memuat font Material Icons bawaan Flutter untuk digunakan di PDF
  final fontData = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  final ttf = pw.Font.ttf(fontData);
  final constructionIcon = pw.IconData(0xe189); // Kode untuk ikon 'construction'

  // Helper untuk format angka dan tanggal
  final numberFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final quantityFormat =
      NumberFormat.decimalPattern('id_ID'); // Untuk format kuantitas
  final dateFormat = DateFormat('dd-MM-yyyy');
  final timeFormat = DateFormat('HH:mm:ss');

  // Helper untuk garis pemisah
  final divider = pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Text('--------------------------------',
        style: const pw.TextStyle(fontSize: 8)),
  );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.all(12),
      build: (pw.Context context) {
        // --- Mulai membangun konten PDF ---
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ================== HEADER ==================
            pw.Row(
              children: [
                pw.Icon(constructionIcon, font: ttf, size: 32),
                pw.SizedBox(width: 8),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(storeName,
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text(storeAddress,
                        style: const pw.TextStyle(fontSize: 8)),
                    if (storePhone != null && storePhone.isNotEmpty)
                      pw.Text('Telp: $storePhone',
                          style: const pw.TextStyle(fontSize: 8)),
                  ],
                )
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Text('ID: ${transaction.id.substring(0, 13)}',
                style: const pw.TextStyle(fontSize: 8)),
            divider,

            // ================== INFO TRANSAKSI & PELANGGAN ==================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(dateFormat.format(transaction.date),
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(timeFormat.format(transaction.date),
                        style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(transaction.customer?.name ?? 'Umum',
                        style: const pw.TextStyle(fontSize: 8)),
                    if (transaction.customer?.address != null &&
                        transaction.customer!.address!.isNotEmpty)
                      pw.Text(transaction.customer!.address!,
                          style: const pw.TextStyle(fontSize: 8)),
                  ],
                )
              ],
            ),
            divider,

            // ================== DAFTAR ITEM ==================
            // Menggunakan for loop untuk menampilkan setiap item
            for (int i = 0; i < transaction.items.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${i + 1}. ${transaction.items[i].name}',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '   ${quantityFormat.format(transaction.items[i].quantity)} x ${quantityFormat.format(transaction.items[i].price)}',
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                        pw.Text(
                          numberFormat
                              .format(transaction.items[i].price *
                                  transaction.items[i].quantity)
                              .replaceAll('Rp', ''), // Hapus 'Rp' agar rata kanan
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            divider,

            // ================== RINGKASAN TOTAL ==================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total QTY:', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                    quantityFormat.format(transaction.items
                        .fold(0, (sum, item) => sum + item.quantity)),
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sub Total', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(
                    numberFormat
                        .format(transaction.totalAmount)
                        .replaceAll('Rp', ''),
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(numberFormat.format(transaction.totalAmount),
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 4),

            if (transaction.status == 'Lunas') ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar (${transaction.paymentMethod})',
                      style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(
                      numberFormat
                          .format(transaction.paidAmount)
                          .replaceAll('Rp', ''),
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembali', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(
                      numberFormat
                          .format(transaction.changeAmount)
                          .replaceAll('Rp', ''),
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ] else ...[
              // Menampilkan status jika belum lunas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Status',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(transaction.status,
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
            divider,

            // ================== FOOTER ==================
            pw.Center(
              child: pw.Text('Terima Kasih Telah Berbelanja',
                  style: pw.TextStyle(
                      fontSize: 8, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}