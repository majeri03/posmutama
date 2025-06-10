import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/models/transaction_item.dart';
import 'package:pos_mutama/services/hive_service.dart';
import 'package:uuid/uuid.dart';
import 'package:pos_mutama/providers/item_provider.dart'; // Tambahkan import ini

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  // Berikan 'ref' ke Notifier
  return TransactionNotifier(ref);
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final Box<Transaction> _box;
  final _uuid = const Uuid();

  final Ref _ref; 

  TransactionNotifier(this._ref) // Ubah constructor
      : _box = Hive.box<Transaction>(HiveService.transactionsBoxName),
        super([]) {
    state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<Transaction> addTransaction({
    required List<TransactionItem> items,
    required int totalAmount,
    Customer? customer,
    required int paidAmount,
    required int changeAmount,
    required String paymentMethod,
  }) async {
    String status;
    if (paidAmount >= totalAmount) {
      status = 'Lunas';
    } else if (paidAmount > 0) {
      status = 'DP';
    } else {
      status = 'Belum Lunas';
    }

    final newTransaction = Transaction(
      id: _uuid.v4(),
      date: DateTime.now(),
      items: items,
      totalAmount: totalAmount,
      customer: customer,
      status: status,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      paymentMethod: paymentMethod,
    );
    await _box.put(newTransaction.id, newTransaction);
    state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    return newTransaction;
  }

  Future<void> recordDebtPayment(String transactionId, int amountToPay) async {
    final transaction = _box.get(transactionId);
    if (transaction != null && transaction.status != 'Lunas') {
      transaction.paidAmount += amountToPay;

      if (transaction.paidAmount >= transaction.totalAmount) {
        transaction.status = 'Lunas';
        transaction.changeAmount = transaction.paidAmount - transaction.totalAmount;
      } else {
        transaction.status = 'DP';
      }
      
      await transaction.save();
      state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  // --- TAMBAHKAN METHOD BARU UNTUK HAPUS TRANSAKSI ---
  Future<void> deleteTransaction(String transactionId) async {
    final transaction = _box.get(transactionId);
    if (transaction != null) {
      // 1. Kembalikan stok semua item dalam transaksi ini
      for (final item in transaction.items) {
        _ref.read(itemProvider.notifier).adjustStock(item.id, item.quantity); // quantity positif = menambah stok
      }

      // 2. Hapus transaksi dari database
      await _box.delete(transactionId);

      // 3. Perbarui state untuk refresh UI
      state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    }
  }
  
  // --- TAMBAHKAN METHOD BARU UNTUK EDIT TRANSAKSI ---
  Future<void> updateTransaction(Transaction oldTransaction, Transaction newTransaction) async {
    // 1. Hitung perbedaan stok untuk setiap item
    final allItemIds = {...oldTransaction.items.map((e) => e.id), ...newTransaction.items.map((e) => e.id)};

    for (final itemId in allItemIds) {
      final oldItem = oldTransaction.items.where((e) => e.id == itemId);
      final newItem = newTransaction.items.where((e) => e.id == itemId);

      final oldQty = oldItem.isEmpty ? 0 : oldItem.first.quantity;
      final newQty = newItem.isEmpty ? 0 : newItem.first.quantity;
      
      final stockChange = oldQty - newQty; 

      if (stockChange != 0) {
        _ref.read(itemProvider.notifier).adjustStock(itemId, stockChange);
      }
    }

    // 2. Simpan objek transaksi yang sudah diperbarui
    await _box.put(oldTransaction.id, newTransaction);
    
    // 3. Perbarui state
    state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double get totalRevenue {
    return state.where((t) => t.status == 'Lunas').fold(0.0, (sum, t) => sum + t.totalAmount);
  }

  double get totalProfit {
    return state.where((t) => t.status == 'Lunas').fold(0.0, (sum, transaction) {
      final transactionProfit = transaction.items.fold(0.0, (itemSum, item) {
        final profitPerItem = (item.price - item.purchasePrice) * item.quantity;
        return itemSum + profitPerItem;
      });
      return sum + transactionProfit;
    });
  }
}