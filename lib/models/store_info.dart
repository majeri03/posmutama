import 'package:hive/hive.dart';

part 'store_info.g.dart';

@HiveType(typeId: 4)
class StoreInfo extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String address;

  @HiveField(2)
  String? phone;

  StoreInfo({
    required this.name,
    required this.address,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'phone': phone,
      };

  factory StoreInfo.fromJson(Map<String, dynamic> json) => StoreInfo(
        name: json['name'],
        address: json['address'],
        phone: json['phone'],
      );
}
