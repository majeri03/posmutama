import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:share_plus/share_plus.dart';

class CsvHelper {
  // Fungsi untuk mengekspor data barang ke file CSV
  static Future<void> exportItemsToCsv(BuildContext context, List<Item> items) async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diekspor.')),
      );
      return;
    }

    List<List<dynamic>> rows = [];
    // Header
    rows.add([
      'id', 'namaBarang', 'barcode', 'hargaBeli', 'hargaJual', 'stok', 'unit', 'tanggalDitambahkan'
    ]);

    // Data
    for (var item in items) {
      rows.add([
        item.id,
        item.namaBarang,
        item.barcode ?? '',
        item.hargaBeli,
        item.hargaJual,
        item.stok,
        item.unit,
        item.tanggalDitambahkan.toIso8601String(),
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);

    // Menyimpan file dan membagikannya
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = "${directory.path}/export_barang_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csv);
      
      await Share.shareXFiles([XFile(path)], text: 'Berikut adalah data barang.');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor file: $e')),
      );
    }
  }

  // Fungsi untuk mengimpor data barang dari file CSV
  static Future<void> importItemsFromCsv(BuildContext context, WidgetRef ref) async {
    try {
      // Minta izin penyimpanan jika belum diberikan
      if (Platform.isAndroid || Platform.isIOS) {
          var status = await Permission.storage.status;
          if (!status.isGranted) {
              await Permission.storage.request();
          }
      }
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final path = result.files.single.path!;
        final input = File(path).openRead();
        final fields = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter(shouldParseNumbers: false)) // Baca semua sebagai string dulu
            .toList();

        // Lewati header (baris pertama)
        final itemsToImport = fields.sublist(1);
        final itemNotifier = ref.read(itemProvider.notifier);

        for (var row in itemsToImport) {
          // Validasi sederhana jumlah kolom
          if (row.length < 7) continue; 
          
          itemNotifier.addItem(
            namaBarang: row[1],
            barcode: row[2].toString().isNotEmpty ? row[2] : null,
            hargaBeli: int.tryParse(row[3].toString()) ?? 0,
            hargaJual: int.tryParse(row[4].toString()) ?? 0,
            stok: int.tryParse(row[5].toString()) ?? 0,
            unit: row[6].toString(),
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${itemsToImport.length} barang berhasil diimpor.')),
        );
      } else {
        // User membatalkan picker
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saat impor: $e')),
      );
    }
  }
}
