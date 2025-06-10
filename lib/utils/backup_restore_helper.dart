import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/store_info.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/services/hive_service.dart';

class BackupRestoreHelper {
  Future<String> createBackup() async {
    try {
      final storeInfoBox = Hive.box<StoreInfo>(HiveService.storeInfoBoxName);
      final itemsBox = Hive.box<Item>(HiveService.itemsBoxName);
      final customersBox = Hive.box<Customer>(HiveService.customersBoxName);
      final transactionsBox = Hive.box<Transaction>(HiveService.transactionsBoxName);

      final backupData = {
        'storeInfo': storeInfoBox.values.map((e) => e.toJson()).toList(),
        'items': itemsBox.values.map((e) => e.toJson()).toList(),
        'customers': customersBox.values.map((e) => e.toJson()).toList(),
        'transactions': transactionsBox.values.map((e) => e.toJson()).toList(),
      };

      final jsonString = jsonEncode(backupData);
      final timestamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final fileName = 'posmutama_backup_$timestamp';
      
      // Ubah String menjadi Uint8List
      Uint8List bytes = utf8.encode(jsonString);

      // Simpan file JSON menggunakan file_saver
      String? path = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'json',
        mimeType: MimeType.json,
      );

      if (path != null) {
        return 'Backup berhasil disimpan di folder Downloads.';
      } else {
        return 'Gagal menyimpan backup.';
      }

    } catch (e) {
      return 'Gagal membuat backup: $e';
    }
  }

  Future<String> restoreFromBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null) return 'Pemulihan dibatalkan.';

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      await Hive.box<StoreInfo>(HiveService.storeInfoBoxName).clear();
      await Hive.box<Item>(HiveService.itemsBoxName).clear();
      await Hive.box<Customer>(HiveService.customersBoxName).clear();
      await Hive.box<Transaction>(HiveService.transactionsBoxName).clear();
      
      final storeInfoList = (backupData['storeInfo'] as List).map((e) => StoreInfo.fromJson(e)).toList();
      for (var data in storeInfoList) {
        await Hive.box<StoreInfo>(HiveService.storeInfoBoxName).add(data);
      }

      final itemsList = (backupData['items'] as List).map((e) => Item.fromJson(e)).toList();
      for (var data in itemsList) {
        await Hive.box<Item>(HiveService.itemsBoxName).put(data.id, data);
      }

      final customersList = (backupData['customers'] as List).map((e) => Customer.fromJson(e)).toList();
      for (var data in customersList) {
        await Hive.box<Customer>(HiveService.customersBoxName).put(data.id, data);
      }

      final transactionsList = (backupData['transactions'] as List).map((e) => Transaction.fromJson(e)).toList();
      for (var data in transactionsList) {
        await Hive.box<Transaction>(HiveService.transactionsBoxName).put(data.id, data);
      }

      return 'Data berhasil dipulihkan! Silakan mulai ulang aplikasi.';
    } catch (e) {
      return 'Gagal memulihkan data: $e';
    }
  }
}