import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/models/transaction_item.dart';
import 'package:pos_mutama/services/hive_service.dart';
import 'package:uuid/uuid.dart';

final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier();
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  final Box<Transaction> _box;
  final _uuid = const Uuid();

  TransactionNotifier()
      : _box = Hive.box<Transaction>(HiveService.transactionsBoxName),
        super([]) {
    state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addTransaction({
    required List<TransactionItem> items,
    required int totalAmount,
    Customer? customer,
    required String status,
    required int paidAmount,
    required int changeAmount,
    required String paymentMethod,
  }) async {
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
  }

  Future<void> payDebt(String transactionId) async {
    final transaction = _box.get(transactionId);
    if (transaction != null && transaction.status == 'Belum Lunas') {
      transaction.status = 'Lunas';
      transaction.paidAmount = transaction.totalAmount;
      transaction.changeAmount = 0;
      await transaction.save();
      state = _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    }
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

