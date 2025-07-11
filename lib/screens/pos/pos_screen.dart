// KODE LENGKAP PENGGANTI UNTUK pos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/item_unit.dart'; // Import yang diperlukan
import 'package:pos_mutama/models/transaction_item.dart';
import 'package:pos_mutama/providers/cart_provider.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:pos_mutama/screens/customers/add_edit_customer_screen.dart';
import 'package:pos_mutama/screens/pos/receipt_screen.dart';
import 'package:pos_mutama/screens/pos/scanner_screen.dart';

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final _searchController = TextEditingController();
  List<Item> _searchedItems = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchedItems = ref.read(itemProvider.notifier).searchItems(_searchController.text);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _showPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => const PaymentDialog(),
    );
  }

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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            )
          ],
        );
      },
    ).then((selectedUnit) {
      if (selectedUnit != null && selectedUnit is ItemUnit) {
        ref.read(cartProvider.notifier).addItem(item, selectedUnit);
      }
    });
  }

  void _showQuantityDialog(TransactionItem cartItem, int maxStockInBase) {
    final quantityController = TextEditingController(text: cartItem.quantity.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ubah Kuantitas ${cartItem.name} (${cartItem.unitName})'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: quantityController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Jumlah'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Jumlah tidak boleh kosong';
                final newQuantity = int.tryParse(value);
                if (newQuantity == null || newQuantity <= 0) return 'Jumlah harus lebih dari 0';

                final cart = ref.read(cartProvider);
                int currentStockInCartBaseUnit = 0;
                for (final ci in cart) {
                  if (ci.id == cartItem.id && ci.unitName != cartItem.unitName) {
                    currentStockInCartBaseUnit += ci.quantity * ci.conversionRate;
                  }
                }
                final availableStockForThisUnit = maxStockInBase - currentStockInCartBaseUnit;
                if ((newQuantity * cartItem.conversionRate) > availableStockForThisUnit) {
                  return 'Stok tidak cukup (Maks: ${availableStockForThisUnit ~/ cartItem.conversionRate})';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newQuantity = int.parse(quantityController.text);
                  ref.read(cartProvider.notifier).setQuantity(cartItem.id, cartItem.unitName, newQuantity);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWideLayout() {
    final allItems = ref.watch(itemProvider);
    if (_searchedItems.isEmpty && _searchController.text.isEmpty) {
      _searchedItems = allItems;
    }
    return Row(
      children: [
        Expanded(flex: 2, child: _buildItemGrid(allItems)),
        Expanded(flex: 1, child: _buildCart()),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    final allItems = ref.watch(itemProvider);
    if (_searchedItems.isEmpty && _searchController.text.isEmpty) {
      _searchedItems = allItems;
    }
    return Column(
      children: [
        Expanded(flex: 1, child: _buildCart()),
        Expanded(flex: 1, child: _buildItemGrid(allItems)),
      ],
    );
  }

  Widget _buildItemGrid(List<Item> allItems) {
    final cart = ref.watch(cartProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari item atau scan barcode...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 3 / 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _searchedItems.length,
            itemBuilder: (context, index) {
              final item = _searchedItems[index];
              int currentStockInCartBaseUnit = 0;
              for (final cartItem in cart) {
                if (cartItem.id == item.id) {
                  currentStockInCartBaseUnit += cartItem.quantity * cartItem.conversionRate;
                }
              }
              final displayedStock = item.stockInBaseUnit - currentStockInCartBaseUnit;

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: displayedStock > 0
                      ? () {
                          if (item.units.length > 1) {
                            _showUnitSelectionDialog(item);
                          } else if (item.units.isNotEmpty) {
                            ref.read(cartProvider.notifier).addItem(item, item.units.first);
                          }
                        }
                      : null,
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: Text(item.name, overflow: TextOverflow.ellipsis),
                      subtitle: Text('Stok: $displayedStock ${item.units.first.name}'),
                    ),
                    child: displayedStock <= 0
                        ? Container(
                            color: Colors.black54,
                            child: const Center(
                                child: Text('Stok Habis',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))
                        : Container(color: Colors.indigo.shade100, child: const Icon(Icons.add_shopping_cart)),
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
    final cart = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartProvider.notifier).totalAmount;
    final allItems = ref.watch(itemProvider);
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Keranjang', style: Theme.of(context).textTheme.headlineSmall),
                if (cart.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    color: Colors.red,
                    tooltip: 'Kosongkan Keranjang',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Konfirmasi'),
                          content: const Text('Anda yakin ingin mengosongkan keranjang?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              onPressed: () {
                                ref.read(cartProvider.notifier).clearCart();
                                Navigator.of(ctx).pop();
                              },
                              child: const Text('Ya, Kosongkan'),
                            )
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('Keranjang kosong'))
                : ListView.builder(
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      final cartItem = cart[index];
                      final subtotal = cartItem.price * cartItem.quantity;
                      return ListTile(
                        title: Text('${cartItem.name} (${cartItem.unitName})'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${cartItem.quantity} x ${numberFormat.format(cartItem.price)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            Text(
                              'Subtotal: ${numberFormat.format(subtotal)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                ref.read(cartProvider.notifier).setQuantity(
                                      cartItem.id,
                                      cartItem.unitName,
                                      cartItem.quantity - 1,
                                    );
                              },
                            ),
                            GestureDetector(
                              onTap: () {
                                final originalItem = allItems.firstWhere((item) => item.id == cartItem.id);
                                _showQuantityDialog(cartItem, originalItem.stockInBaseUnit);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  cartItem.quantity.toString(),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                final originalItem = allItems.firstWhere((i) => i.id == cartItem.id);
                                int currentStockInCartBaseUnit = 0;
                                for (final ci in cart) {
                                  if (ci.id == cartItem.id) {
                                    currentStockInCartBaseUnit += ci.quantity * ci.conversionRate;
                                  }
                                }
                                if ((currentStockInCartBaseUnit + cartItem.conversionRate) <= originalItem.stockInBaseUnit) {
                                  ref.read(cartProvider.notifier).setQuantity(
                                        cartItem.id,
                                        cartItem.unitName,
                                        cartItem.quantity + 1,
                                      );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Stok tidak mencukupi')),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: Theme.of(context).textTheme.titleLarge),
                    Text(numberFormat.format(totalAmount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.isNotEmpty ? _showPaymentDialog : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Bayar'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              if (!context.mounted) return;
              final String? code = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );
              if (code != null && code.isNotEmpty) {
                final item = ref.read(itemProvider.notifier).findItemByBarcode(code);
                if (item != null) {
                  if (item.units.length > 1) {
                    _showUnitSelectionDialog(item);
                  } else if (item.units.isNotEmpty) {
                    ref.read(cartProvider.notifier).addItem(item, item.units.first);
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Barcode tidak ditemukan di database.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          const double wideLayoutThreshold = 800;
          if (constraints.maxWidth > wideLayoutThreshold) {
            return _buildWideLayout();
          } else {
            return _buildNarrowLayout();
          }
        },
      ),
    );
  }
}

class PaymentDialog extends ConsumerStatefulWidget {
  const PaymentDialog({super.key});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paidAmountController = TextEditingController();
  Customer? _selectedCustomer;
  String _paymentMethod = 'Tunai';
  int _changeAmount = 0;

  @override
  void dispose() {
    _paidAmountController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final totalAmount = ref.read(cartProvider.notifier).totalAmount;
    final paidAmount = int.tryParse(_paidAmountController.text) ?? 0;
    setState(() {
      _changeAmount = paidAmount - totalAmount;
    });
  }

  void _processPayment() async {
    if (_formKey.currentState!.validate()) {
      final cart = ref.read(cartProvider);
      final totalAmount = ref.read(cartProvider.notifier).totalAmount;
      final paidAmount =
          int.tryParse(_paidAmountController.text.isNotEmpty ? _paidAmountController.text : "0") ?? 0;

      final changeAmount = (paidAmount >= totalAmount) ? paidAmount - totalAmount : 0;

      final newTransaction = await ref.read(transactionProvider.notifier).addTransaction(
            items: cart,
            totalAmount: totalAmount,
            customer: _selectedCustomer,
            paidAmount: paidAmount,
            changeAmount: changeAmount,
            paymentMethod: (paidAmount > 0) ? _paymentMethod : 'N/A',
          );

      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(transaction: newTransaction),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);
    final totalAmount = ref.watch(cartProvider.notifier).totalAmount;
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return AlertDialog(
      title: const Text('Pembayaran'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(numberFormat.format(totalAmount), style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Customer?>(
                        value: _selectedCustomer,
                        decoration: const InputDecoration(labelText: 'Pelanggan (Opsional)'),
                        items: [
                          const DropdownMenuItem<Customer?>(
                            value: null,
                            child: Text('Pelanggan Umum'),
                          ),
                          ...customers.map((customer) => DropdownMenuItem(
                                value: customer,
                                child: Text(customer.name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCustomer = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () async {
                        final newCustomer = await Navigator.of(context).push<Customer>(
                          MaterialPageRoute(builder: (context) => const AddEditCustomerScreen()),
                        );
                        if (newCustomer != null) {
                          setState(() {
                            _selectedCustomer = newCustomer;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _paidAmountController,
                  decoration: const InputDecoration(labelText: 'Jumlah Bayar (Isi 0 jika utang)'),
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calculateChange(),
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                  items: ['Tunai', 'Transfer', 'QRIS']
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kembalian:'),
                    Text(numberFormat.format(_changeAmount < 0 ? 0 : _changeAmount),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _processPayment,
          child: const Text('Proses'),
        ),
      ],
    );
  }
}