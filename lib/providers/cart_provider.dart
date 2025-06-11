import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/transaction_item.dart';
import 'package:pos_mutama/models/item_unit.dart';

final cartProvider = StateNotifierProvider<CartNotifier, List<TransactionItem>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<TransactionItem>> {
  CartNotifier() : super([]);

  void addItem(Item item, ItemUnit unit) {
    final existingItemIndex = state.indexWhere((txItem) => txItem.id == item.id && txItem.unitName == unit.name);

    // Dapatkan stok item asli dalam satuan dasar
    final stockInBaseUnit = item.stockInBaseUnit;
    // Hitung total stok yang sudah ada di keranjang untuk item ini (dalam satuan dasar)
    int currentCartStock = 0;
    for(final cartItem in state) {
      if(cartItem.id == item.id) {
        currentCartStock += cartItem.quantity * cartItem.conversionRate;
      }
    }
    
    // Stok yang tersisa dalam satuan dasar
    final remainingStock = stockInBaseUnit - currentCartStock;

    if (existingItemIndex != -1) {
      // Jika item dengan satuan yang sama sudah ada, tambah kuantitasnya
      // Pastikan penambahan tidak melebihi stok
      if (remainingStock >= unit.conversionRate) {
        final updatedItem = state[existingItemIndex];
        updatedItem.quantity++;
        state = List.from(state);
      }
    } else {
      // Jika item baru atau satuan berbeda, tambahkan ke keranjang
      // Pastikan stok cukup untuk 1 unit baru ini
       if (remainingStock >= unit.conversionRate) {
        state = [
          ...state,
          TransactionItem(
            id: item.id,
            name: item.name,
            price: unit.price,
            quantity: 1,
            purchasePrice: unit.purchasePrice,
            unitName: unit.name,
            conversionRate: unit.conversionRate,
          ),
        ];
      }
    }
  }

  void removeItem(String itemId, String unitName) {
    state = state.where((item) => !(item.id == itemId && item.unitName == unitName)).toList();
  }

  
  void setQuantity(String itemId, String unitName, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId, unitName);
      return;
    }

    state = [
      for (final item in state)
        if (item.id == itemId && item.unitName == unitName)
          TransactionItem(
              id: item.id,
              name: item.name,
              price: item.price,
              quantity: newQuantity,
              purchasePrice: item.purchasePrice,
              unitName: item.unitName,
              conversionRate: item.conversionRate)
        else
          item,
    ];
  }

  void clearCart() {
    state = [];
  }
  
  int get totalAmount {
    return state.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
}
