import 'package:hive/hive.dart';

part 'store_info.g.dart';

@HiveType(typeId: 4)
class StoreInfo extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String address;

  StoreInfo({
    required this.name,
    required this.address,
  });
}
