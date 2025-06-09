import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> exportItemsToCsv(List<Item> items) async {
  List<List<dynamic>> rows = [];
  rows.add(['ID', 'Nama', 'Harga Beli', 'Harga Jual', 'Stok', 'Barcode']);
  for (var item in items) {
    rows.add([item.id, item.name, item.purchasePrice, item.price, item.stock, item.barcode ?? '']);
  }

  String csv = const ListToCsvConverter().convert(rows);
  await _saveAndShareFile(csv, 'items_export.csv');
}

Future<void> exportTransactionsToCsv(List<Transaction> transactions) async {
   List<List<dynamic>> rows = [];
  rows.add(['ID', 'Tanggal', 'Pelanggan', 'Total', 'Status', 'Metode Bayar', 'Item']);
   for (var tx in transactions) {
     final itemsString = tx.items.map((e) => '${e.name} (x${e.quantity})').join(', ');
    rows.add([tx.id, tx.date.toIso8601String(), tx.customer?.name ?? 'Umum', tx.totalAmount, tx.status, tx.paymentMethod, itemsString]);
  }

  String csv = const ListToCsvConverter().convert(rows);
  await _saveAndShareFile(csv, 'transactions_export.csv');
}

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
      
      // Skip header row
      for (var i = 1; i < fields.length; i++) {
        var row = fields[i];
        if(row.length >= 5) {
            final name = row[1].toString();
            final purchasePrice = double.tryParse(row[2].toString()) ?? 0.0;
            final price = int.tryParse(row[3].toString()) ?? 0;
            final stock = int.tryParse(row[4].toString()) ?? 0;
            final barcode = row.length > 5 && row[5].toString().isNotEmpty ? row[5].toString() : null;

            await ref.read(itemProvider.notifier).addItem(name, price, stock, barcode, purchasePrice);
        }
      }
      return 'Import berhasil!';
    } catch (e) {
      return 'Error saat memproses file: $e';
    }
  } else {
    return 'Tidak ada file yang dipilih.';
  }
}

Future<void> _saveAndShareFile(String data, String fileName) async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    status = await Permission.storage.request();
  }

  if (status.isGranted) {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    await file.writeAsString(data);
    
    final xfile = XFile(path);
    await Share.shareXFiles([xfile]);
  } else {
    // Handle kasus di mana izin tidak diberikan.
    // Tidak melakukan apa-apa agar tidak ada 'print' di production.
  }
}
