// KODE PENGGANTI LENGKAP UNTUK: lib/screens/reports/edit_transaction_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/item_unit.dart'; // Pastikan ini diimpor
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/models/transaction_item.dart';
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
  late List<TransactionItem> _itemsInCart;
  late Customer? _selectedCustomer;
  late int _totalAmount;
  final _searchController = TextEditingController();
  late List<Item> _allItems;

  @override
  void initState() {
    super.initState();
    _allItems = ref.read(itemProvider);
    _itemsInCart = widget.originalTransaction.items.map((item) {
      return TransactionItem(
        id: item.id, name: item.name, price: item.price,
        quantity: item.quantity, purchasePrice: item.purchasePrice,
        unitName: item.unitName, conversionRate: item.conversionRate,
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

  int _getAvailableStockForEdit(String itemId) {
    final itemInDb = _allItems.firstWhere((i) => i.id == itemId);
    final originalTxItem = widget.originalTransaction.items.firstWhereOrNull((i) => i.id == itemId);
    final originalQuantityInBase = originalTxItem != null ? (originalTxItem.quantity * originalTxItem.conversionRate) : 0;
    return itemInDb.stockInBaseUnit + originalQuantityInBase;
  }

  int _getCurrentCartStockInBase(String itemId) {
    return _itemsInCart.where((i) => i.id == itemId)
        .fold(0, (sum, item) => sum + (item.quantity * item.conversionRate));
  }

  void _calculateTotal() {
    setState(() {
      _totalAmount = _itemsInCart.fold(0, (sum, item) => sum + (item.price * item.quantity));
    });
  }

  // =======================================================================
  // ==================== SOLUSI BAGIAN 1 ADA DI SINI ======================
  // =======================================================================
  
  // FUNGSI BARU: Menampilkan dialog pemilihan satuan
  void _showUnitSelectionDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pilih Satuan untuk ${item.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: item.units.length,
              itemBuilder: (context, index) {
                final unit = item.units[index];
                return ListTile(
                  title: Text(unit.name),
                  subtitle: Text('Harga: Rp ${unit.price}'),
                  onTap: () => Navigator.of(context).pop(unit),
                );
              },
            ),
          ),
        );
      },
    ).then((selectedUnit) {
      if (selectedUnit != null && selectedUnit is ItemUnit) {
        // Panggil _addItemToCart dengan satuan yang dipilih
        _addItemToCart(item, selectedUnit);
      }
    });
  }

  // FUNGSI DIPERBARUI: Menerima parameter ItemUnit
  void _addItemToCart(Item item, ItemUnit selectedUnit) {
    final availableStock = _getAvailableStockForEdit(item.id);
    final cartStock = _getCurrentCartStockInBase(item.id);

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
          id: item.id, name: item.name, price: selectedUnit.price,
          quantity: 1, purchasePrice: selectedUnit.purchasePrice,
          unitName: selectedUnit.name, conversionRate: selectedUnit.conversionRate,
        ));
      }
    });
    _calculateTotal();
  }

  void _increaseQuantity(String itemId, String unitName) {
    final availableStock = _getAvailableStockForEdit(itemId);
    final cartStock = _getCurrentCartStockInBase(itemId);
    final itemInCart = _itemsInCart.firstWhere((i) => i.id == itemId && i.unitName == unitName);
    
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

  // =======================================================================
  // ==================== SOLUSI BAGIAN 2 ADA DI SINI ======================
  // =======================================================================

  // FUNGSI DIPERBARUI: Logika status yang fleksibel
  void _onSaveChanges() {
    // Hitung total bayar dari riwayat pembayaran yang sudah ada
    final int totalPaidAmount = widget.originalTransaction.paidAmount;
    
    // Tentukan status dan kembalian BARU berdasarkan total yang diedit
    String newStatus;
    int newChangeAmount;

    if (totalPaidAmount >= _totalAmount) {
      newStatus = 'Lunas';
      newChangeAmount = totalPaidAmount - _totalAmount;
    } else if (totalPaidAmount > 0) {
      newStatus = 'DP';
      newChangeAmount = 0;
    } else {
      newStatus = 'Belum Lunas';
      newChangeAmount = 0;
    }

    final newTransaction = Transaction(
      id: widget.originalTransaction.id,
      date: widget.originalTransaction.date,
      items: _itemsInCart,
      totalAmount: _totalAmount,
      customer: _selectedCustomer,
      // Gunakan status & kembalian yang baru dihitung
      status: newStatus, 
      changeAmount: newChangeAmount,
      // Bawa serta data lama yang tidak berubah
      paymentMethod: widget.originalTransaction.paymentMethod,
      paymentHistory: widget.originalTransaction.paymentHistory,
    );

    ref.read(transactionProvider.notifier).updateTransaction(widget.originalTransaction, newTransaction);

    Navigator.of(context).pop(); // Keluar dari halaman edit
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // Keluar dari halaman detail (jika ada)
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksi berhasil diperbarui!")));
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _itemsInCart.isNotEmpty ? _onSaveChanges : null,
          )
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return constraints.maxWidth > 800
          ? _buildWideLayout(searchedItems)
          : _buildNarrowLayout(searchedItems);
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
              maxCrossAxisExtent: 200, childAspectRatio: 3 / 2,
              crossAxisSpacing: 10, mainAxisSpacing: 10,
            ),
            itemCount: searchedItems.length,
            itemBuilder: (context, index) {
              final item = searchedItems[index];
              final availableStockForEdit = _getAvailableStockForEdit(item.id);
              final currentCartStock = _getCurrentCartStockInBase(item.id);
              final remainingStockInBase = availableStockForEdit - currentCartStock;
              final baseUnitName = item.units.first.name;
              final canAdd = remainingStockInBase > 0;

              return Card(
                child: InkWell(
                  // FUNGSI ONTAP DIPERBARUI
                  onTap: canAdd
                      ? () {
                          if (item.units.length > 1) {
                            _showUnitSelectionDialog(item);
                          } else {
                            _addItemToCart(item, item.units.first);
                          }
                        }
                      : null,
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: Text(item.name),
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
  
  // (Sisa kode _buildCart() tetap sama dan tidak perlu diubah)
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