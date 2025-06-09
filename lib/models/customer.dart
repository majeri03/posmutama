import 'package:hive/hive.dart';

part 'customer.g.dart';

@HiveType(typeId: 1)
class Customer extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String namaPelanggan;

  @HiveField(2)
  String? noHp;

  @HiveField(3)
  String? alamat;

  @HiveField(4)
  int totalUtang;

  Customer({
    required this.id,
    required this.namaPelanggan,
    this.noHp,
    this.alamat,
    required this.totalUtang,
  });
}