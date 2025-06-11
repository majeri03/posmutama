import 'package:hive/hive.dart';

part 'item_unit.g.dart';

@HiveType(typeId: 5) // Pastikan typeId ini unik (belum digunakan)
class ItemUnit extends HiveObject {
  @HiveField(0)
  String name; // Contoh: "Pcs", "Lusin", "Dus"

  @HiveField(1)
  double purchasePrice; // Harga Beli (Modal) untuk satuan ini

  @HiveField(2)
  int price; // Harga Jual untuk satuan ini

  @HiveField(3)
  int conversionRate; // Berapa banyak "Satuan Dasar" dalam satuan ini. Contoh: 1 Lusin = 12 Pcs, maka conversionRate = 12

  ItemUnit({
    required this.name,
    required this.purchasePrice,
    required this.price,
    required this.conversionRate,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'purchasePrice': purchasePrice,
    'price': price,
    'conversionRate': conversionRate,
  };

  factory ItemUnit.fromJson(Map<String, dynamic> json) => ItemUnit(
    name: json['name'],
    purchasePrice: (json['purchasePrice'] as num).toDouble(),
    price: json['price'],
    conversionRate: json['conversionRate'],
  );
}