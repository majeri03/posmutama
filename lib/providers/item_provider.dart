import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/services/hive_service.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_mutama/models/item_unit.dart';

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

  Future<void> addItem(String name, int stockInBaseUnit, String? barcode, List<ItemUnit> units) async {
    final newItem = Item(
      id: _uuid.v4(),
      name: name,
      stockInBaseUnit: stockInBaseUnit,
      barcode: barcode,
      units: units,
    );
    await _box.put(newItem.id, newItem);
    state = _box.values.toList();
  }

  Future<void> addImportedItem(Item item) async {
    await _box.put(item.id, item);
  }

  bool itemExists(String id) {
    return _box.containsKey(id);
  }

  Future<void> editItem(String id, String name, int stockInBaseUnit, String? barcode, List<ItemUnit> units) async {
    final item = _box.get(id);
    if (item != null) {
      item.name = name;
      item.stockInBaseUnit = stockInBaseUnit;
      item.barcode = barcode;
      item.units = units;
      await item.save();
      state = _box.values.toList();
    }
  }

  Future<void> deleteItem(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }

  void adjustStock(String itemId, int quantityChangeInBaseUnit) {
    final item = _box.get(itemId);
    if (item != null) {
      // quantityChange bisa positif (mengembalikan stok) atau negatif (menjual)
      item.stockInBaseUnit += quantityChangeInBaseUnit;
      item.save();
      // Perbarui state agar UI yang bergantung pada itemProvider ikut refresh
      state = _box.values.toList();
    }
  }
 
  void updateStock(String id, int quantitySold) {
    adjustStock(id, -quantitySold); // Arahkan ke method baru
  }

  List<Item> searchItems(String query) {
    if (query.isEmpty) {
      return state;
    }
    return state.where((item) {
      return item.name.toLowerCase().contains(query.toLowerCase()) || (item.barcode?.contains(query) ?? false);
    }).toList();
  }

  Item? findItemByBarcode(String barcode) {
    try {
      // Mencari item pertama yang cocok dengan barcode.
      return state.firstWhere((item) => item.barcode == barcode);
    } catch (e) {
      // Jika firstWhere tidak menemukan elemen, ia akan melempar error.
      // Kita tangkap error tersebut dan mengembalikan null.
      return null;
    }
  }
}
