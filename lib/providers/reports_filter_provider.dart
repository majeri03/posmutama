import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';

enum DateFilter { all, today, thisWeek, thisMonth, thisYear }

final dateFilterProvider = StateProvider<DateFilter>((ref) => DateFilter.all);

final filteredTransactionsProvider = Provider<List<Transaction>>((ref) {
  final filter = ref.watch(dateFilterProvider);
  final allTransactions = ref.watch(transactionProvider);
  final now = DateTime.now();

  switch (filter) {
    case DateFilter.today:
      return allTransactions
          .where((t) =>
              t.date.year == now.year &&
              t.date.month == now.month &&
              t.date.day == now.day)
          .toList();
    case DateFilter.thisWeek:
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return allTransactions
          .where((t) =>
              t.date.isAfter(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)) &&
              t.date.isBefore(DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day).add(const Duration(days: 1))))
          .toList();
    case DateFilter.thisMonth:
       return allTransactions
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList();
    case DateFilter.thisYear:
       return allTransactions.where((t) => t.date.year == now.year).toList();
    case DateFilter.all:
      return allTransactions;
  }
});

final reportMetricsProvider = Provider((ref) {
  final transactions = ref.watch(filteredTransactionsProvider);
  
  final lunasTransactions = transactions.where((t) => t.status == 'Lunas').toList();

  final double totalRevenue = lunasTransactions.fold(0.0, (sum, t) => sum + t.totalAmount);
  
  final double totalProfit = lunasTransactions.fold(0.0, (sum, transaction) {
      final transactionProfit = transaction.items.fold(0.0, (itemSum, item) {
        final profitPerItem = (item.price - item.purchasePrice) * item.quantity;
        return itemSum + profitPerItem;
      });
      return sum + transactionProfit;
    });

  return {
    'revenue': totalRevenue,
    'profit': totalProfit,
    'transactionCount': transactions.length,
    'paidTransactionCount': lunasTransactions.length,
  };
});
