import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 1)
class Item extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int price;

  @HiveField(3)
  int stock;

  @HiveField(4)
  String? barcode;

  @HiveField(5)
  double purchasePrice;

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.barcode,
    required this.purchasePrice,
  });
  
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'stock': stock,
        'barcode': barcode,
        'purchasePrice': purchasePrice,
      };

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        stock: json['stock'],
        barcode: json['barcode'],
        purchasePrice: json['purchasePrice'],
      );
}
