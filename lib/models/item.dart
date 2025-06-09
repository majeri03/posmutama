import 'package:hive/hive.dart';

part 'item.g.dart';

@HiveType(typeId: 0)
class Item extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String namaBarang;

  @HiveField(2)
  String? barcode;

  @HiveField(3)
  int hargaBeli;

  @HiveField(4)
  int hargaJual;

  @HiveField(5)
  int stok;

  @HiveField(6)
  String unit;

  @HiveField(7)
  DateTime tanggalDitambahkan;

  Item({
    required this.id,
    required this.namaBarang,
    this.barcode,
    required this.hargaBeli,
    required this.hargaJual,
    required this.stok,
    required this.unit,
    required this.tanggalDitambahkan,
  });
}