import 'package:hive/hive.dart';
import 'package:pos_mutama/models/transaction_item.dart';

part 'transaction.g.dart';

@HiveType(typeId: 2)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime tanggalTransaksi;

  @HiveField(2)
  List<TransactionItem> items;

  @HiveField(3)
  int totalBelanja;

  @HiveField(4)
  int totalBayar;

  @HiveField(5)
  int kembalian;

  @HiveField(6)
  String metodePembayaran; // 'Cash', 'Transfer'

  @HiveField(7)
  String statusPembayaran; // 'Lunas', 'Belum Lunas', 'DP'

  @HiveField(8)
  String? idPelanggan;

  @HiveField(9)
  String namaKasir;

  Transaction({
    required this.id,
    required this.tanggalTransaksi,
    required this.items,
    required this.totalBelanja,
    required this.totalBayar,
    required this.kembalian,
    required this.metodePembayaran,
    required this.statusPembayaran,
    this.idPelanggan,
    required this.namaKasir,
  });
  
  // Getter untuk menghitung total keuntungan dari transaksi ini
  int get totalKeuntungan {
    return items.fold(0, (previousValue, element) {
      final keuntunganPerItem = (element.hargaJualSaatTransaksi - element.hargaBeliSaatTransaksi) * element.jumlahBeli;
      return previousValue + keuntunganPerItem;
    });
  }
}