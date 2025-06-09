import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/transaction_item.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<TransactionItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<TransactionItem>> {
  CartNotifier() : super([]);

  void addItem(Item item) {
    final existingItemIndex = state.indexWhere((txItem) => txItem.id == item.id);

    if (existingItemIndex != -1) {
      final updatedItem = state[existingItemIndex];
      if (updatedItem.quantity < item.stock) {
        updatedItem.quantity++;
        state = List.from(state);
      }
    } else {
      if (item.stock > 0) {
        state = [
          ...state,
          TransactionItem(
            id: item.id,
            name: item.name,
            price: item.price,
            quantity: 1,
            purchasePrice: item.purchasePrice,
          ),
        ];
      }
    }
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList();
  }

  void increaseQuantity(String itemId) {
    state = [
      for (final item in state)
        if (item.id == itemId)
          TransactionItem(
              id: item.id,
              name: item.name,
              price: item.price,
              quantity: item.quantity + 1,
              purchasePrice: item.purchasePrice)
        else
          item,
    ];
  }

  void decreaseQuantity(String itemId) {
    final itemToDecrease = state.firstWhere((item) => item.id == itemId);
    if (itemToDecrease.quantity > 1) {
      state = [
        for (final item in state)
          if (item.id == itemId)
            TransactionItem(
                id: item.id,
                name: item.name,
                price: item.price,
                quantity: item.quantity - 1,
                purchasePrice: item.purchasePrice)
          else
            item,
      ];
    } else {
      removeItem(itemId);
    }
  }

  void clearCart() {
    state = [];
  }

  int get totalAmount {
    return state.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
}
