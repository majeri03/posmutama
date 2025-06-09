import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/services/hive_service.dart';
import 'package:uuid/uuid.dart';

final itemProvider = StateNotifierProvider<ItemNotifier, List<Item>>((ref) {
  return ItemNotifier();
});

class ItemNotifier extends StateNotifier<List<Item>> {
  final Box<Item> _box;
  final _uuid = const Uuid();

  ItemNotifier()
      : _box = Hive.box<Item>(HiveService.itemsBoxName),
        super([]) {
    state = _box.values.toList();
  }

  Future<void> addItem(String name, int price, int stock, String? barcode, double purchasePrice) async {
    final newItem = Item(
      id: _uuid.v4(),
      name: name,
      price: price,
      stock: stock,
      barcode: barcode,
      purchasePrice: purchasePrice,
    );
    await _box.put(newItem.id, newItem);
    state = _box.values.toList();
  }

  Future<void> editItem(String id, String name, int price, int stock, String? barcode, double purchasePrice) async {
    final item = _box.get(id);
    if (item != null) {
      item.name = name;
      item.price = price;
      item.stock = stock;
      item.barcode = barcode;
      item.purchasePrice = purchasePrice;
      await item.save();
      state = _box.values.toList();
    }
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }

  void updateStock(String id, int quantitySold) {
    final item = _box.get(id);
    if (item != null) {
      item.stock -= quantitySold;
      item.save();
      state = _box.values.toList();
    }
  }

  List<Item> searchItems(String query) {
    if (query.isEmpty) {
      return state;
    }
    return state.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase()) || (item.barcode?.contains(query) ?? false);
    }).toList();
  }
}
