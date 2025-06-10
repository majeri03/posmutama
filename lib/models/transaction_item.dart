import 'package:hive/hive.dart';

part 'transaction_item.g.dart';

@HiveType(typeId: 3)
class TransactionItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int price;

  @HiveField(3)
  int quantity;
  
  @HiveField(4)
  double purchasePrice;

  TransactionItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.purchasePrice,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'purchasePrice': purchasePrice,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem(
        id: json['id'],
        name: json['name'],
        price: json['price'],
        quantity: json['quantity'],
        purchasePrice: json['purchasePrice'],
      );
}
