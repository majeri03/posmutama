import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/providers/cart_provider.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:pos_mutama/screens/customers/add_edit_customer_screen.dart';
import 'package:pos_mutama/screens/pos/receipt_screen.dart';
import 'package:pos_mutama/screens/pos/scanner_screen.dart';
import 'package:pos_mutama/models/transaction_item.dart';

// Class POSScreen & _POSScreenState tidak ada perubahan

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

  // --- TAMBAHKAN METHOD DIALOG BARU DI SINI ---
  void _showQuantityDialog(TransactionItem cartItem, int maxStock) {
    final quantityController = TextEditingController(text: cartItem.quantity.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ubah Kuantitas ${cartItem.name}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: quantityController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Jumlah',
                hintText: 'Stok tersedia: $maxStock',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah tidak boleh kosong';
                }
                final newQuantity = int.tryParse(value);
                if (newQuantity == null) {
                  return 'Masukkan angka yang valid';
                }
                if (newQuantity <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                if (newQuantity > maxStock) {
                  return 'Jumlah melebihi stok (maks: $maxStock)';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newQuantity = int.parse(quantityController.text);
                  ref.read(cartProvider.notifier).setQuantity(cartItem.id, newQuantity);
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
        Expanded(
          flex: 2,
          child: _buildItemGrid(allItems),
        ),
        Expanded(
          flex: 1,
          child: _buildCart(),
        ),
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
        Expanded(
          flex: 1,
          child: _buildCart(),
        ),
        Expanded(
          flex: 1,
          child: _buildItemGrid(allItems),
        ),
      ],
    );
  }
  
 // GANTI METHOD DI BAWAH INI
  Widget _buildItemGrid(List<Item> allItems) {
    // =======================================================================
    // PERUBAHAN UNTUK STOK REAL-TIME (BAGIAN 2)
    // =======================================================================
    // 1. Pantau (watch) состояние keranjang di sini
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
              final TransactionItem? cartItem = cart.firstWhere((ci) => ci.id == item.id, orElse: () => null);
              // 2. Cari item ini di dalam keranjang
              final cartItem = cart.firstWhere((ci) => ci.id == item.id, orElse: () => null);
              
              // 3. Hitung stok yang akan ditampilkan (Stok Awal - Jumlah di Keranjang)
              final displayedStock = item.stock - (cartItem?.quantity ?? 0);

              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  // 4. Gunakan displayedStock untuk menentukan apakah item bisa diklik
                  onTap: displayedStock > 0
                      ? () => ref.read(cartProvider.notifier).addItem(item)
                      : null,
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black45,
                      title: Text(item.name, overflow: TextOverflow.ellipsis),
                      // 5. Tampilkan displayedStock di subtitle
                      subtitle: Text('Stok: $displayedStock'),
                    ),
                    // 6. Gunakan displayedStock untuk menampilkan overlay "Stok Habis"
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

  
  // GANTI METHOD DI BAWAH INI
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
                // ========================================================
                // PERUBAHAN UNTUK TOMBOL RESET (BAGIAN 1)
                // ========================================================
                // Tampilkan tombol hanya jika keranjang tidak kosong
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
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Batal'),
                            ),
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
                      // Ambil stok asli dari 'allItems' untuk validasi
                      final originalItem = allItems.firstWhere((item) => item.id == cartItem.id,
                          orElse: () => Item(id: '', name: '', price: 0, stock: 0, purchasePrice: 0));

                      return ListTile(
                        title: Text(cartItem.name),
                        subtitle: Text(numberFormat.format(cartItem.price)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => ref.read(cartProvider.notifier).decreaseQuantity(cartItem.id),
                            ),
                            GestureDetector(
                              onTap: () {
                                _showQuantityDialog(cartItem, originalItem.stock);
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
                                if (cartItem.quantity < originalItem.stock) {
                                  ref.read(cartProvider.notifier).increaseQuantity(cartItem.id);
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
              final String? code = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );

              if (code != null && code.isNotEmpty) {
                final item = ref.read(itemProvider.notifier).findItemByBarcode(code);

                if (item != null) {
                  ref.read(cartProvider.notifier).addItem(item);
                  
                  if(mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} ditambahkan ke keranjang.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                } else {
                   if(mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: Barcode tidak ditemukan di database.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
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
      final paidAmount = int.tryParse(_paidAmountController.text.isNotEmpty ? _paidAmountController.text : "0") ?? 0;
      
      final changeAmount = (paidAmount >= totalAmount) ? paidAmount - totalAmount : 0;

      final newTransaction = await ref.read(transactionProvider.notifier).addTransaction(
        items: cart,
        totalAmount: totalAmount,
        customer: _selectedCustomer,
        paidAmount: paidAmount,
        changeAmount: changeAmount,
        paymentMethod: (paidAmount > 0) ? _paymentMethod : 'N/A',
      );

      for (var cartItem in cart) {
        ref.read(itemProvider.notifier).updateStock(cartItem.id, cartItem.quantity);
      }
      
      ref.read(cartProvider.notifier).clearCart();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close dialog
      
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _calculateChange(),
                    validator: (value){
                      if(value == null || value.isEmpty){
                        // Boleh kosong, akan dianggap 0
                      }
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
                       Text(numberFormat.format(_changeAmount < 0 ? 0 : _changeAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
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