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

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartProvider.notifier).totalAmount;
    final allItems = ref.watch(itemProvider);
    if (_searchedItems.isEmpty && _searchController.text.isEmpty) {
      _searchedItems = allItems;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
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
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: item.stock > 0 ? () => ref.read(cartProvider.notifier).addItem(item) : null,
                          child: GridTile(
                            footer: GridTileBar(
                              backgroundColor: Colors.black45,
                              title: Text(item.name, overflow: TextOverflow.ellipsis),
                              subtitle: Text('Stok: ${item.stock}'),
                            ),
                            child: item.stock <= 0
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
            ),
          ),
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Keranjang', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  Expanded(
                    child: cart.isEmpty
                        ? const Center(child: Text('Keranjang kosong'))
                        : ListView.builder(
                            itemCount: cart.length,
                            itemBuilder: (context, index) {
                              final cartItem = cart[index];
                              return ListTile(
                                title: Text(cartItem.name),
                                subtitle: Text('${cartItem.quantity} x Rp ${cartItem.price}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => ref.read(cartProvider.notifier).decreaseQuantity(cartItem.id),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        final originalItem = allItems.firstWhere((item) => item.id == cartItem.id);
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
                            Text('Rp $totalAmount', style: Theme.of(context).textTheme.titleLarge),
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
            ),
          ),
        ],
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
  String _paymentStatus = 'Lunas';
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


  void _processPayment() {
    if (_formKey.currentState!.validate()) {
      final cart = ref.read(cartProvider);
      final totalAmount = ref.read(cartProvider.notifier).totalAmount;
      final paidAmount = int.tryParse(_paidAmountController.text) ?? 0;
      
      if (_paymentStatus == 'Lunas' && paidAmount < totalAmount) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jumlah bayar kurang dari total belanja')),
          );
        return;
      }

      ref.read(transactionProvider.notifier).addTransaction(
        items: cart,
        totalAmount: totalAmount,
        customer: _selectedCustomer,
        status: _paymentStatus,
        paidAmount: _paymentStatus == 'Lunas' ? paidAmount : 0,
        changeAmount: _paymentStatus == 'Lunas' ? _changeAmount : 0,
        paymentMethod: _paymentStatus == 'Lunas' ? _paymentMethod : 'N/A',
      );

      for (var cartItem in cart) {
        ref.read(itemProvider.notifier).updateStock(cartItem.id, cartItem.quantity);
      }

      final lastTransaction = ref.read(transactionProvider).first;

      ref.read(cartProvider.notifier).clearCart();
      
      Navigator.of(context).pop(); // Close dialog
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ReceiptScreen(transaction: lastTransaction),
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
                 DropdownButtonFormField<Customer?>(
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
                 const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                    value: _paymentStatus,
                    decoration: const InputDecoration(labelText: 'Status Pembayaran'),
                    items: ['Lunas', 'Belum Lunas']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _paymentStatus = value!;
                        if (_paymentStatus == 'Belum Lunas') {
                          _paidAmountController.clear();
                          _changeAmount = 0;
                        }
                      });
                    },
                  ),
                 const SizedBox(height: 16),
                 TextFormField(
                    controller: _paidAmountController,
                    decoration: const InputDecoration(labelText: 'Jumlah Bayar'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: _paymentStatus == 'Lunas',
                    onChanged: (_) => _calculateChange(),
                    validator: (value){
                      if(_paymentStatus == 'Lunas' && (value == null || value.isEmpty)){
                        return 'Jumlah bayar tidak boleh kosong';
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
                    onChanged: _paymentStatus == 'Lunas' ? (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    } : null,
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
