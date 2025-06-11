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

  @override
  void initState() {
    super.initState();
    // Inisialisasi state lokal dengan data dari transaksi asli
    _itemsInCart = widget.originalTransaction.items.map((item) {
      // Buat salinan item agar tidak mengubah data asli secara langsung
      return TransactionItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        purchasePrice: item.purchasePrice,
        unitName: item.unitName, // TAMBAHKAN INI
        conversionRate: item.conversionRate, // TAMBAHKAN INI
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

  // --- Helper Methods untuk Mengelola Keranjang Lokal ---
  void _calculateTotal() {
    setState(() {
      _totalAmount = _itemsInCart.fold(0, (sum, item) => sum + (item.price * item.quantity));
    });
  }

  void _addItemToCart(Item item) {
    setState(() {
      final existingIndex = _itemsInCart.indexWhere((i) => i.id == item.id);
      if (existingIndex != -1) {
        _itemsInCart[existingIndex].quantity++;
      } else {
        _itemsInCart.add(TransactionItem(
          id: item.id,
          name: item.name,
          price: item.units.first.price, // Ambil dari satuan dasar
          quantity: 1,
          purchasePrice: item.units.first.purchasePrice, // Ambil dari satuan dasar
          unitName: item.units.first.name, // TAMBAHKAN INI
          conversionRate: item.units.first.conversionRate, // TAMBAHKAN INI
        ));
      }
    });
    _calculateTotal();
  }

  void _increaseQuantity(String itemId) {
    setState(() {
      final item = _itemsInCart.firstWhere((i) => i.id == itemId);
      item.quantity++;
    });
    _calculateTotal();
  }

  void _decreaseQuantity(String itemId) {
    setState(() {
      final item = _itemsInCart.firstWhere((i) => i.id == itemId);
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _itemsInCart.removeWhere((i) => i.id == itemId);
      }
    });
    _calculateTotal();
  }

  void _onSaveChanges() {
    // Buat objek transaksi baru berdasarkan state lokal saat ini
    final newTransaction = Transaction(
      id: widget.originalTransaction.id,
      date: widget.originalTransaction.date,
      items: _itemsInCart,
      totalAmount: _totalAmount,
      customer: _selectedCustomer,
      // Pertahankan detail pembayaran asli
      status: widget.originalTransaction.status,
      paidAmount: widget.originalTransaction.paidAmount,
      changeAmount: widget.originalTransaction.changeAmount,
      paymentMethod: widget.originalTransaction.paymentMethod,
    );

    // Panggil provider untuk update
    ref.read(transactionProvider.notifier).updateTransaction(widget.originalTransaction, newTransaction);

    // Kembali ke dua layar sebelumnya (ke daftar laporan)
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi berhasil diperbarui!")));
  }

  // --- Tampilan UI (mirip dengan POSScreen) ---
  @override
  Widget build(BuildContext context) {
    final allItems = ref.watch(itemProvider);
    final searchedItems = allItems.where((item) {
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
          return _buildWideLayout(allItems, searchedItems);
        }
        return _buildNarrowLayout(allItems, searchedItems);
      }),
    );
  }

  Widget _buildWideLayout(List<Item> allItems, List<Item> searchedItems) {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildItemGrid(allItems, searchedItems)),
        Expanded(flex: 1, child: _buildCart(allItems)),
      ],
    );
  }

  Widget _buildNarrowLayout(List<Item> allItems, List<Item> searchedItems) {
    return Column(
      children: [
        Expanded(flex: 1, child: _buildCart(allItems)),
        Expanded(flex: 1, child: _buildItemGrid(allItems, searchedItems)),
      ],
    );
  }

  Widget _buildItemGrid(List<Item> allItems, List<Item> searchedItems) {
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
              final originalTxItem = widget.originalTransaction.items.firstWhereOrNull((i) => i.id == item.id);
              final itemInCart = _itemsInCart.firstWhereOrNull((i) => i.id == item.id);

              final initialStock = item.stockInBaseUnit + (originalTxItem != null ? (originalTxItem.quantity * originalTxItem.conversionRate) : 0);
              final displayedStock = initialStock - (itemInCart?.quantity ?? 0);

              return Card(
                child: InkWell(
                  onTap: displayedStock > 0 ? () => _addItemToCart(item) : null,
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: Text(item.name),
                      subtitle: Text('Stok: $displayedStock'),
                    ),
                    child: displayedStock <= 0
                        ? Container(color: Colors.black54, child: const Center(child: Text('Stok Habis')))
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

  Widget _buildCart(List<Item> allItems) {
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
                        title: Text(cartItem.name),
                        subtitle: Text(numberFormat.format(cartItem.price)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _decreaseQuantity(cartItem.id), icon: const Icon(Icons.remove)),
                            Text(cartItem.quantity.toString()),
                            IconButton(onPressed: () => _increaseQuantity(cartItem.id), icon: const Icon(Icons.add)),
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