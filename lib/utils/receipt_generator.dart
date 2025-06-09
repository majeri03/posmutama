import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/transaction.dart';

class ReceiptGenerator {
  static Future<Uint8List> generateReceiptPdf(Transaction transaction, Customer? customer) async {
    final pdf = pw.Document();
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Ukuran kertas struk thermal umum
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text('Toko Bahan Bangunan mUtama', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ),
              pw.Center(
                child: pw.Text('Jl. Pembangunan No. 123', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              
              // Info Transaksi
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('ID Transaksi:', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(transaction.id, style: const pw.TextStyle(fontSize: 9)),
              ]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Tanggal:', style: const pw.TextStyle(fontSize: 9)),
                pw.Text(dateFormat.format(transaction.tanggalTransaksi), style: const pw.TextStyle(fontSize: 9)),
              ]),
              if (customer != null)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Text('Pelanggan:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(customer.namaPelanggan, style: const pw.TextStyle(fontSize: 9)),
                ]),
              pw.Divider(),

              // Tabel Item (FIXED: deprecated_member_use)
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['Barang', 'Qty', 'Harga', 'Subtotal'],
                data: transaction.items.map((item) => [
                  item.namaBarang,
                  item.jumlahBeli.toString(),
                  numberFormat.format(item.hargaJualSaatTransaksi),
                  numberFormat.format(item.subtotal),
                ]).toList(),
                columnWidths: {
                   0: const pw.FlexColumnWidth(3),
                   1: const pw.FlexColumnWidth(1),
                   2: const pw.FlexColumnWidth(2),
                   3: const pw.FlexColumnWidth(2.5),
                },
              ),
              pw.Divider(),
              
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Belanja: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.Text(numberFormat.format(transaction.totalBelanja), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ]
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total Bayar: ', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(numberFormat.format(transaction.totalBayar), style: const pw.TextStyle(fontSize:10)),
                ]
              ),
              if(transaction.kembalian > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Kembalian: ', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(numberFormat.format(transaction.kembalian), style: const pw.TextStyle(fontSize: 10)),
                  ]
                ),
              pw.Divider(),

              // Footer
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text('Terima Kasih!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
               pw.Center(
                 // FIXED: const_eval_type_bool_num_string
                child: pw.Text('Barang yang sudah dibeli tidak dapat dikembalikan.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic, fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}