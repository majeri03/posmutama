import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/transaction_item.dart';

// State untuk keranjang belanja
class CartState {
  final List<TransactionItem> items;
  final int total;

  CartState({required this.items, required this.total});

  CartState.initial() : items = [], total = 0;

  CartState copyWith({List<TransactionItem>? items, int? total}) {
    return CartState(
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }
}

// Notifier untuk keranjang belanja
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.initial());

  // Menambah barang ke keranjang atau menambah jumlahnya jika sudah ada
  void addItemToCart(Item item) {
    final existingItemIndex = state.items.indexWhere((txItem) => txItem.idBarang == item.id);

    if (existingItemIndex >= 0) {
      // Jika barang sudah ada, tambah jumlahnya
      final updatedItems = List<TransactionItem>.from(state.items);
      final existingTxItem = updatedItems[existingItemIndex];

      // Pastikan tidak melebihi stok
      if (existingTxItem.jumlahBeli < item.stok) {
        final updatedTxItem = TransactionItem(
          idBarang: existingTxItem.idBarang,
          namaBarang: existingTxItem.namaBarang,
          hargaJualSaatTransaksi: existingTxItem.hargaJualSaatTransaksi,
          hargaBeliSaatTransaksi: existingTxItem.hargaBeliSaatTransaksi,
          jumlahBeli: existingTxItem.jumlahBeli + 1,
          subtotal: existingTxItem.hargaJualSaatTransaksi * (existingTxItem.jumlahBeli + 1),
        );
        updatedItems[existingItemIndex] = updatedTxItem;
        state = state.copyWith(items: updatedItems);
      }
    } else {
      // Jika barang baru, tambahkan ke keranjang
      final newTxItem = TransactionItem(
        idBarang: item.id,
        namaBarang: item.namaBarang,
        hargaJualSaatTransaksi: item.hargaJual,
        hargaBeliSaatTransaksi: item.hargaBeli,
        jumlahBeli: 1,
        subtotal: item.hargaJual,
      );
      state = state.copyWith(items: [...state.items, newTxItem]);
    }
    _calculateTotal();
  }

  // Menghapus barang dari keranjang atau mengurangi jumlahnya
  void removeItemFromCart(String itemId) {
    final existingItemIndex = state.items.indexWhere((txItem) => txItem.idBarang == itemId);
    if (existingItemIndex < 0) return;

    final updatedItems = List<TransactionItem>.from(state.items);
    final existingTxItem = updatedItems[existingItemIndex];

    if (existingTxItem.jumlahBeli > 1) {
      // Jika jumlah lebih dari 1, kurangi
      final updatedTxItem = TransactionItem(
        idBarang: existingTxItem.idBarang,
        namaBarang: existingTxItem.namaBarang,
        hargaJualSaatTransaksi: existingTxItem.hargaJualSaatTransaksi,
        hargaBeliSaatTransaksi: existingTxItem.hargaBeliSaatTransaksi,
        jumlahBeli: existingTxItem.jumlahBeli - 1,
        subtotal: existingTxItem.hargaJualSaatTransaksi * (existingTxItem.jumlahBeli - 1),
      );
      updatedItems[existingItemIndex] = updatedTxItem;
      state = state.copyWith(items: updatedItems);
    } else {
      // Jika jumlah hanya 1, hapus dari keranjang
      updatedItems.removeAt(existingItemIndex);
      state = state.copyWith(items: updatedItems);
    }
    _calculateTotal();
  }
  
  // Menghapus item sepenuhnya dari keranjang
  void clearItemFromCart(String itemId) {
     final updatedItems = List<TransactionItem>.from(state.items)
      ..removeWhere((item) => item.idBarang == itemId);
    state = state.copyWith(items: updatedItems);
    _calculateTotal();
  }

  // Menghitung ulang total belanja
  void _calculateTotal() {
    final total = state.items.fold(0, (sum, item) => sum + item.subtotal);
    state = state.copyWith(total: total);
  }

  // Mengosongkan keranjang setelah transaksi selesai
  void clearCart() {
    state = CartState.initial();
  }
}

// Provider untuk CartNotifier
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
