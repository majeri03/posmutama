import 'package:hive/hive.dart';
import 'package:pos_mutama/models/item_unit.dart';

part 'item.g.dart';

@HiveType(typeId: 1) // typeId tetap
class Item extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  // FIELD DIHAPUS: price, purchasePrice

  @HiveField(2) // Menggantikan price
  int stockInBaseUnit; // Stok akan selalu dicatat dalam satuan terkecil

  @HiveField(3) // Menggantikan stock
  String? barcode;

  @HiveField(4) // Menggantikan barcode
  List<ItemUnit> units; // Daftar satuan untuk item ini

  Item({
    required this.id,
    required this.name,
    required this.stockInBaseUnit,
    this.barcode,
    required this.units,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stockInBaseUnit': stockInBaseUnit,
        'barcode': barcode,
        'units': units.map((unit) => unit.toJson()).toList(),
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'],
        name: json['name'],
        stockInBaseUnit: json['stockInBaseUnit'],
        barcode: json['barcode'],
        units: List<ItemUnit>.from(
            json['units']?.map((x) => ItemUnit.fromJson(x))),
      );
}