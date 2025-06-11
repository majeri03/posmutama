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
import 'package:path/path.dart' as p;

Future<String> exportItemsToCsv(List<Item> items) async {
  List<List<dynamic>> rows = [];

  // Tambahkan header baru
  rows.add([
    'item_id',
    'item_name',
    'item_barcode',
    'stock_in_base_unit',
    'unit_name',
    'unit_purchase_price',
    'unit_sell_price',
    'unit_conversion_rate'
  ]);

  // Loop untuk setiap item
  for (var item in items) {
    // Loop lagi untuk setiap satuan di dalam item
    for (var unit in item.units) {
      rows.add([
        item.id,
        item.name,
        item.barcode ?? '',
        item.stockInBaseUnit,
        unit.name,
        unit.purchasePrice,
        unit.price, // Ini adalah harga jual satuan
        unit.conversionRate,
      ]);
    }
  }

  String csv = const ListToCsvConverter().convert(rows);
  return await _saveFileToCustomLocation(
    data: utf8.encode(csv), // Kirim data dalam format Uint8List
    fileName: 'items_export_mutama.csv',
  );
}

Future<String> exportTransactionsToCsv(List<Transaction> transactions) async {
  List<List<dynamic>> rows = [];
  rows.add(['ID', 'Tanggal', 'Pelanggan', 'Total', 'Status', 'Metode Bayar', 'Item']);
  for (var tx in transactions) {
    final itemsString = tx.items.map((e) => '${e.name} (${e.unitName} x${e.quantity})').join(', ');
    rows.add([
      tx.id, tx.date.toIso8601String(), tx.customer?.name ?? 'Umum',
      tx.totalAmount, tx.status, tx.paymentMethod, itemsString
    ]);
  }

  String csv = const ListToCsvConverter().convert(rows);
  return await _saveFileToCustomLocation(
    data: utf8.encode(csv),
    fileName: 'transactions_export_mutama.csv',
  );
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
      final List<List<dynamic>> fields =
          const CsvToListConverter().convert(stringContent);

      if (fields.length <= 1) {
        return 'File CSV kosong atau hanya berisi header.';
      }

      final itemNotifier = ref.read(itemProvider.notifier);
      int itemsAdded = 0;
      int itemsSkipped = 0;

      // Tahap 1: Kelompokkan semua baris berdasarkan item_id
      final Map<String, List<List<dynamic>>> groupedByItemId = {};
      for (int i = 1; i < fields.length; i++) { // Mulai dari 1 untuk lewati header
        var row = fields[i];
        if (row.isNotEmpty && row[0] != null) {
          final itemId = row[0].toString();
          if (!groupedByItemId.containsKey(itemId)) {
            groupedByItemId[itemId] = [];
          }
          groupedByItemId[itemId]!.add(row);
        }
      }

      // Tahap 2: Proses setiap grup menjadi satu Item object
      for (var entry in groupedByItemId.entries) {
        final itemId = entry.key;
        final itemRows = entry.value;

        // Cek apakah item sudah ada di database, jika ya, lewati
        if (itemNotifier.itemExists(itemId)) {
          itemsSkipped++;
          continue;
        }

        // Ambil data item dari baris pertama grup
        final firstRow = itemRows.first;
        final itemName = firstRow[1].toString();
        final barcode = firstRow[2].toString().isNotEmpty ? firstRow[2].toString() : null;
        final stockInBaseUnit = int.tryParse(firstRow[3].toString()) ?? 0;

        // Buat daftar satuan dari semua baris di grup ini
        final List<ItemUnit> units = [];
        for (var row in itemRows) {
          units.add(ItemUnit(
            name: row[4].toString(),
            purchasePrice: double.tryParse(row[5].toString()) ?? 0.0,
            price: int.tryParse(row[6].toString()) ?? 0,
            conversionRate: int.tryParse(row[7].toString()) ?? 1,
          ));
        }

        // Buat item baru dengan daftar satuannya
        final newItem = Item(
          id: itemId,
          name: itemName,
          barcode: barcode,
          stockInBaseUnit: stockInBaseUnit,
          units: units,
        );

        // Tambahkan ke database (gunakan method addImportedItem jika ada, atau add item biasa)
        await itemNotifier.addImportedItem(newItem);
        itemsAdded++;
      }

      // Perbarui state setelah semua item ditambahkan
      itemNotifier.state = ref.read(itemProvider.notifier).state.toList();

      return 'Import selesai: $itemsAdded item baru ditambahkan, $itemsSkipped item dilewati karena ID sudah ada.';
    } catch (e) {
      return 'Error saat memproses file: $e. Pastikan format file CSV sudah benar.';
    }
  } else {
    return 'Tidak ada file yang dipilih.';
  }
}

Future<String> _saveFileToCustomLocation({
  required Uint8List data,
  required String fileName,
}) async {
  try {
    // 1. Minta pengguna memilih direktori/folder
    String? directoryPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Pilih Folder untuk Menyimpan File',
    );

    // 2. Cek jika pengguna membatalkan pemilihan folder
    if (directoryPath == null) {
      return 'Penyimpanan dibatalkan oleh pengguna.';
    }

    // 3. Gabungkan path direktori dengan nama file
    final String filePath = p.join(directoryPath, fileName);

    // 4. Tulis file ke lokasi yang sudah dipilih
    final file = File(filePath);
    await file.writeAsBytes(data);

    return 'File berhasil disimpan di: $filePath';
  } catch (e) {
    return 'Error saat menyimpan file: $e';
  }
}