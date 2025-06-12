// File: lib/screens/reports/edit_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/models/transaction_item.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:collection/collection.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction originalTransaction;

  const EditTransactionScreen({super.key, required this.originalTransaction});

  @override
  ConsumerState<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends ConsumerState<EditTransactionScreen> {
  // --- State Lokal untuk Mengelola Perubahan ---
  late List<TransactionItem> _itemsInCart;
  late Customer? _selectedCustomer;
  late int _totalAmount;
  final _searchController = TextEditingController();
  // Kebutuhan data item asli untuk perhitungan stok
  late List<Item> _allItems; 

  @override
  void initState() {
    super.initState();
    // Ambil data item sekali saja saat inisialisasi
    _allItems = ref.read(itemProvider);

    // Salin item transaksi ke keranjang edit lokal
    _itemsInCart = widget.originalTransaction.items.map((item) {
      return TransactionItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        purchasePrice: item.purchasePrice,
        unitName: item.unitName,
        conversionRate: item.conversionRate,
      );
    }).toList();

    _selectedCustomer = widget.originalTransaction.customer;
    _calculateTotal();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- HELPER BARU: Menghitung total stok yang tersedia untuk sesi edit ---
  // Stok ini adalah: Stok gudang saat ini + Stok yang "dikembalikan" dari transaksi asli
  int _getAvailableStockForEdit(String itemId) {
    final itemInDb = _allItems.firstWhere((i) => i.id == itemId);
    final originalTxItem = widget.originalTransaction.items.firstWhereOrNull((i) => i.id == itemId);
    
    // Jika item ada di transaksi asli, kembalikan stoknya secara virtual
    final originalQuantityInBase = originalTxItem != null ? (originalTxItem.quantity * originalTxItem.conversionRate) : 0;
    
    return itemInDb.stockInBaseUnit + originalQuantityInBase;
  }

  // --- HELPER BARU: Menghitung stok item yang saat ini ada di keranjang edit (dalam satuan dasar) ---
  int _getCurrentCartStockInBase(String itemId) {
    return _itemsInCart
        .where((i) => i.id == itemId)
        .fold(0, (sum, item) => sum + (item.quantity * item.conversionRate));
  }

  void _calculateTotal() {
    setState(() {
      _totalAmount = _itemsInCart.fold(0, (sum, item) => sum + (item.price * item.quantity));
    });
  }

  // --- FUNGSI DIPERBAIKI DENGAN VALIDASI STOK ---
  void _addItemToCart(Item item) {
    final availableStock = _getAvailableStockForEdit(item.id);
    final cartStock = _getCurrentCartStockInBase(item.id);
    final selectedUnit = item.units.first; // Asumsi satuan dasar

    // Cek apakah masih ada sisa stok untuk ditambah
    if (cartStock + selectedUnit.conversionRate > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok tidak cukup untuk menambah item ini'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      final existingIndex = _itemsInCart.indexWhere((i) => i.id == item.id && i.unitName == selectedUnit.name);
      if (existingIndex != -1) {
        _itemsInCart[existingIndex].quantity++;
      } else {
        _itemsInCart.add(TransactionItem(
          id: item.id,
          name: item.name,
          price: selectedUnit.price,
          quantity: 1,
          purchasePrice: selectedUnit.purchasePrice,
          unitName: selectedUnit.name,
          conversionRate: selectedUnit.conversionRate,
        ));
      }
    });
    _calculateTotal();
  }

  // --- FUNGSI DIPERBAIKI DENGAN VALIDASI STOK ---
  void _increaseQuantity(String itemId, String unitName) {
    final availableStock = _getAvailableStockForEdit(itemId);
    final cartStock = _getCurrentCartStockInBase(itemId);
    final itemInCart = _itemsInCart.firstWhere((i) => i.id == itemId && i.unitName == unitName);
    
    // Cek apakah penambahan 1 unit masih dalam batas stok
    if (cartStock + itemInCart.conversionRate > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok tidak cukup!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      itemInCart.quantity++;
    });
    _calculateTotal();
  }

  void _decreaseQuantity(String itemId, String unitName) {
    setState(() {
      final item = _itemsInCart.firstWhere((i) => i.id == itemId && i.unitName == unitName);
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _itemsInCart.removeWhere((i) => i.id == itemId && i.unitName == unitName);
      }
    });
    _calculateTotal();
  }

  void _onSaveChanges() {
    final newTransaction = Transaction(
      id: widget.originalTransaction.id,
      date: widget.originalTransaction.date,
      items: _itemsInCart,
      totalAmount: _totalAmount,
      customer: _selectedCustomer,
      status: widget.originalTransaction.status,
      paidAmount: widget.originalTransaction.paidAmount,
      changeAmount: widget.originalTransaction.changeAmount,
      paymentMethod: widget.originalTransaction.paymentMethod,
    );

    ref.read(transactionProvider.notifier).updateTransaction(widget.originalTransaction, newTransaction);

    Navigator.of(context).pop();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi berhasil diperbarui!")));
  }

  @override
  Widget build(BuildContext context) {
    // _allItems sudah di-cache di initState, kita tinggal filter di sini
    final searchedItems = _allItems.where((item) {
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) || (item.barcode?.contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Transaksi #${widget.originalTransaction.id.substring(0, 8)}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Simpan Perubahan',
            onPressed: _onSaveChanges,
          )
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildWideLayout(searchedItems);
        }
        return _buildNarrowLayout(searchedItems);
      }),
    );
  }

  Widget _buildWideLayout(List<Item> searchedItems) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildItemGrid(searchedItems)),
        Expanded(flex: 1, child: _buildCart()),
      ],
    );
  }

  Widget _buildNarrowLayout(List<Item> searchedItems) {
    return Column(
      children: [
        Expanded(flex: 1, child: _buildCart()),
        Expanded(flex: 1, child: _buildItemGrid(searchedItems)),
      ],
    );
  }

  Widget _buildItemGrid(List<Item> searchedItems) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari untuk menambah item...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: searchedItems.length,
            itemBuilder: (context, index) {
              final item = searchedItems[index];

              // --- LOGIKA STOK DIPERBAIKI ---
              final availableStockForEdit = _getAvailableStockForEdit(item.id);
              final currentCartStock = _getCurrentCartStockInBase(item.id);
              final remainingStockInBase = availableStockForEdit - currentCartStock;
              
              final baseUnitName = item.units.first.name;
              final canAdd = remainingStockInBase > 0;

              return Card(
                child: InkWell(
                  onTap: canAdd ? () => _addItemToCart(item) : null,
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: Text(item.name),
                      // Tampilkan sisa stok yang bisa diedit
                      subtitle: Text('Sisa Stok: $remainingStockInBase $baseUnitName'),
                    ),
                    child: !canAdd
                        ? Container(color: Colors.black54, child: const Center(child: Text('Stok Habis', style: TextStyle(color: Colors.white))))
                        : Container(color: Colors.teal.shade100, child: const Icon(Icons.add_shopping_cart)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCart() {
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Item dalam Transaksi', style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
            child: _itemsInCart.isEmpty
                ? const Center(child: Text('Tidak ada item'))
                : ListView.builder(
                    itemCount: _itemsInCart.length,
                    itemBuilder: (context, index) {
                      final cartItem = _itemsInCart[index];
                      return ListTile(
                        title: Text('${cartItem.name} (${cartItem.unitName})'),
                        subtitle: Text(numberFormat.format(cartItem.price)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _decreaseQuantity(cartItem.id, cartItem.unitName), icon: const Icon(Icons.remove)),
                            Text(cartItem.quantity.toString()),
                            IconButton(onPressed: () => _increaseQuantity(cartItem.id, cartItem.unitName), icon: const Icon(Icons.add)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                Text(numberFormat.format(_totalAmount), style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          )
        ],
      ),
    );
  }
}
