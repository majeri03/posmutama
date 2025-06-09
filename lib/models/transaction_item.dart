import 'package:hive/hive.dart';

part 'transaction_item.g.dart';

// Model ini tidak menjadi HiveObject karena akan disimpan sebagai bagian dari list di dalam Transaction
@HiveType(typeId: 3)
class TransactionItem {
  @HiveField(0)
  String idBarang;

  @HiveField(1)
  String namaBarang;

  @HiveField(2)
  int hargaJualSaatTransaksi;

  @HiveField(3)
  int jumlahBeli;

  @HiveField(4)
  int subtotal;
  
  @HiveField(5)
  int hargaBeliSaatTransaksi; // Diperlukan untuk menghitung keuntungan

  TransactionItem({
    required this.idBarang,
    required this.namaBarang,
    required this.hargaJualSaatTransaksi,
    required this.jumlahBeli,
    required this.subtotal,
    required this.hargaBeliSaatTransaksi,
  });
}