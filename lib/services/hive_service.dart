import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/store_info.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/models/transaction_item.dart';

class HiveService {
  static const String customersBoxName = 'customers';
  static const String itemsBoxName = 'items';
  static const String transactionsBoxName = 'transactions';
  static const String storeInfoBoxName = 'storeInfo';

  Future<void> init() async {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    registerAdapters();
    await openBoxes();
  }

  void registerAdapters() {
    if (!Hive.isAdapterRegistered(CustomerAdapter().typeId)) {
      Hive.registerAdapter(CustomerAdapter());
    }
    if (!Hive.isAdapterRegistered(ItemAdapter().typeId)) {
      Hive.registerAdapter(ItemAdapter());
    }
    if (!Hive.isAdapterRegistered(TransactionAdapter().typeId)) {
      Hive.registerAdapter(TransactionAdapter());
    }
    if (!Hive.isAdapterRegistered(TransactionItemAdapter().typeId)) {
      Hive.registerAdapter(TransactionItemAdapter());
    }
    if (!Hive.isAdapterRegistered(StoreInfoAdapter().typeId)) {
      Hive.registerAdapter(StoreInfoAdapter());
    }
  }

  Future<void> openBoxes() async {
    await Hive.openBox<Customer>(customersBoxName);
    await Hive.openBox<Item>(itemsBoxName);
    await Hive.openBox<Transaction>(transactionsBoxName);
    await Hive.openBox<StoreInfo>(storeInfoBoxName);
  }
}

