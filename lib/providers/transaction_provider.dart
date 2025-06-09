import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/models/transaction_item.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/services/hive_service.dart';

// Provider untuk state notifier transaksi
final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier(ref);
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final Ref _ref;

  TransactionNotifier(this._ref) : super([]) {
    loadTransactions();
  }

  // Mengambil service dan notifier lain dari Ref
  HiveService get _hiveService => _ref.read(hiveServiceProvider);
  ItemNotifier get _itemNotifier => _ref.read(itemProvider.notifier);
  CustomerNotifier get _customerNotifier => _ref.read(customerProvider.notifier);
  
  // Memuat semua transaksi dari database
  void loadTransactions() {
    state = _hiveService.getAllTransactions();
  }

  // Fungsi inti untuk memproses dan menambah transaksi baru
  Future<Transaction?> addTransaction({
    required List<TransactionItem> items,
    required int totalBelanja,
    required int totalBayar,
    required String metodePembayaran,
    required String statusPembayaran,
    Customer? pelanggan,
  }) async {
    // Validasi dasar
    if (items.isEmpty) return null;

    // 1. Kurangi stok setiap barang yang terjual
    for (var item in items) {
      _itemNotifier.decreaseStock(item.idBarang, item.jumlahBeli);
    }

    // 2. Hitung kembalian dan utang
    int kembalian = 0;
    int utang = 0;

    if (statusPembayaran == 'Lunas') {
      kembalian = totalBayar - totalBelanja;
    } else { // Status 'Belum Lunas' atau 'DP'
      utang = totalBelanja - totalBayar;
      // Perbarui total utang pelanggan jika ada
      if (pelanggan != null) {
        _customerNotifier.updateCustomerDebt(pelanggan.id, utang);
      }
    }
    
    // 3. Buat objek transaksi baru
    final newTransaction = Transaction(
      id: 'TRX-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}',
      tanggalTransaksi: DateTime.now(),
      items: items,
      totalBelanja: totalBelanja,
      totalBayar: totalBayar,
      kembalian: kembalian,
      metodePembayaran: metodePembayaran,
      statusPembayaran: statusPembayaran,
      idPelanggan: pelanggan?.id,
      namaKasir: 'Kasir Utama', // Bisa dikembangkan dengan sistem login
    );

    // 4. Simpan transaksi ke database
    await _hiveService.saveTransaction(newTransaction);

    // 5. Muat ulang daftar transaksi
    loadTransactions();
    
    // Kembalikan transaksi yang baru dibuat agar bisa digunakan untuk cetak struk
    return newTransaction;
  }
}
