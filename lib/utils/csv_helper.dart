import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/item_provider.dart';

Future<String> exportItemsToCsv(List<Item> items) async {
  List<List<dynamic>> rows = [];
  rows.add(['ID', 'Nama', 'Harga Beli', 'Harga Jual', 'Stok', 'Barcode']);
  for (var item in items) {
    rows.add([item.id, item.name, item.purchasePrice, item.price, item.stock, item.barcode ?? '']);
  }

  String csv = const ListToCsvConverter().convert(rows);
  return await _saveFileToDownloads(csv, 'items_export.csv');
}

Future<String> exportTransactionsToCsv(List<Transaction> transactions) async {
   List<List<dynamic>> rows = [];
  rows.add(['ID', 'Tanggal', 'Pelanggan', 'Total', 'Status', 'Metode Bayar', 'Item']);
   for (var tx in transactions) {
     final itemsString = tx.items.map((e) => '${e.name} (x${e.quantity})').join(', ');
    rows.add([tx.id, tx.date.toIso8601String(), tx.customer?.name ?? 'Umum', tx.totalAmount, tx.status, tx.paymentMethod, itemsString]);
  }

  String csv = const ListToCsvConverter().convert(rows);
  return await _saveFileToDownloads(csv, 'transactions_export.csv');
}

// --- GANTI FUNGSI DI BAWAH INI ---
Future<String> importItemsFromCsv(WidgetRef ref) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );

  if (result != null) {
    try {
      final file = File(result.files.single.path!);
      final stringContent = await file.readAsString();
      final List<List<dynamic>> fields = const CsvToListConverter().convert(stringContent);
      
      final itemNotifier = ref.read(itemProvider.notifier);
      int itemsAdded = 0;
      int itemsSkipped = 0;

      // Lewati baris header, mulai dari indeks 1
      for (var i = 1; i < fields.length; i++) {
        var row = fields[i];
        // Pastikan baris memiliki kolom yang cukup dan ID tidak kosong
        if (row.isNotEmpty && row[0] != null && row[0].toString().isNotEmpty) {
          final id = row[0].toString();
          
          // Cek apakah item dengan ID ini sudah ada
          if (!itemNotifier.itemExists(id)) {
            // Jika tidak ada, tambahkan item baru
            final newItem = Item(
              id: id,
              name: row[1].toString(),
              purchasePrice: double.tryParse(row[2].toString()) ?? 0.0,
              price: int.tryParse(row[3].toString()) ?? 0,
              stock: int.tryParse(row[4].toString()) ?? 0,
              barcode: row.length > 5 && row[5].toString().isNotEmpty ? row[5].toString() : null,
            );
            await itemNotifier.addImportedItem(newItem);
            itemsAdded++;
          } else {
            // Jika sudah ada, lewati
            itemsSkipped++;
          }
        }
      }
      
      // Perbarui state setelah semua item ditambahkan
      ref.read(itemProvider.notifier).state = ref.read(itemProvider.notifier).state.toList();

      return 'Import selesai: $itemsAdded item ditambahkan, $itemsSkipped item dilewati karena ID sudah ada.';
    } catch (e) {
      return 'Error saat memproses file: $e';
    }
  } else {
    return 'Tidak ada file yang dipilih.';
  }
}

Future<String> _saveFileToDownloads(String data, String fileName) async {
  try {
    // Ubah String menjadi Uint8List (format data biner)
    Uint8List bytes = utf8.encode(data);

    // Dapatkan nama file tanpa ekstensi dan ekstensinya secara terpisah
    String name = fileName.split('.').first;
    String ext = fileName.split('.').last;

    // Simpan file menggunakan file_saver
    String? path = await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: ext,
      mimeType: ext == 'csv' ? MimeType.csv : MimeType.text,
    );

    if (path != null) {
      return 'File berhasil disimpan di folder Downloads.';
    } else {
      return 'Gagal menyimpan file.';
    }
  } catch (e) {
    return 'Error saat menyimpan file: $e';
  }
}