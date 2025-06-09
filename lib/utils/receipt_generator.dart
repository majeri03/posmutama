import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_mutama/models/transaction.dart';

Future<Uint8List> generateReceipt(
  Transaction transaction,
  String storeName,
  String storeAddress,
) async {
  final pdf = pw.Document();
  final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Text(storeName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Center(
              child: pw.Text(storeAddress, style: const pw.TextStyle(fontSize: 8)),
            ),
            pw.SizedBox(height: 10),
            pw.Text('ID: ${transaction.id}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Tgl: ${DateFormat('dd/MM/yy HH:mm').format(transaction.date)}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Plgn: ${transaction.customer?.name ?? 'Umum'}', style: const pw.TextStyle(fontSize: 8)),
            pw.Divider(height: 10),
            for (final item in transaction.items)
              pw.Column(children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(item.name, style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(numberFormat.format(item.price * item.quantity), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.start,
                  children: [
                    pw.Text('${item.quantity} x @${numberFormat.format(item.price)}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ]),
            pw.Divider(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.Text(numberFormat.format(transaction.totalAmount), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            if (transaction.status == 'Lunas') ...[
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
            ] else ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Status', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(transaction.status, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
            pw.Divider(height: 10),
            pw.Center(
              child: pw.Text('Terima kasih!', style: const pw.TextStyle(fontSize: 8)),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}
