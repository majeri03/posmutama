import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/providers/cart_provider.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:pos_mutama/screens/inventory/inventory_screen.dart'; // Untuk mengakses filteredItemsProvider
import 'package:pos_mutama/screens/pos/receipt_screen.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    Future<void> scanBarcodeAndAddItem() async {
      // FIXED: use_build_context_synchronously
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        final barcode = await FlutterBarcodeScanner.scanBarcode(
            '#ff6666', 'Batal', true, ScanMode.BARCODE);
        
        if (barcode == '-1') return; // User membatalkan

        final allItems = ref.read(itemProvider);
        final foundItem = allItems.firstWhere(
          (item) => item.barcode == barcode,
          orElse: () => Item(id: '', namaBarang: '', hargaBeli: 0, hargaJual: 0, stok: -1, unit: '', tanggalDitambahkan: DateTime.now()), // Dummy item
        );

        if (foundItem.stok != -1) {
          ref.read(cartProvider.notifier).addItemToCart(foundItem);
        } else {
            scaffoldMessenger.showSnackBar(
             const SnackBar(content: Text('Barang dengan barcode ini tidak ditemukan.')),
           );
        }
      } catch (e) {
         scaffoldMessenger.showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
         );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir (POS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: scanBarcodeAndAddItem,
            tooltip: 'Scan Barcode',
          ),
        ],
      ),
      body: Column(
        children: [
          // Bagian Keranjang Belanja
          Expanded(
            flex: 2,
            child: cartState.items.isEmpty
                ? const Center(child: Text('Keranjang masih kosong.\nScan atau cari barang untuk memulai.'))
                : ListView.builder(
                    itemCount: cartState.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = cartState.items[index];
                      return ListTile(
                        title: Text(cartItem.namaBarang),
                        // FIXED: unnecessary_string_interpolations
                        subtitle: Text(numberFormat.format(cartItem.hargaJualSaatTransaksi)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => ref.read(cartProvider.notifier).removeItemFromCart(cartItem.idBarang),
                            ),
                            Text(cartItem.jumlahBeli.toString(), style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                final itemMaster = ref.read(itemProvider).firstWhere((i) => i.id == cartItem.idBarang);
                                ref.read(cartProvider.notifier).addItemToCart(itemMaster);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => ref.read(cartProvider.notifier).clearItemFromCart(cartItem.idBarang),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(thickness: 2),
          
          // Bagian Daftar Produk
          Expanded(
            flex: 3,
            child: Consumer(builder: (context, ref, _) {
              final items = ref.watch(filteredItemsProvider); // Reuse dari InventoryScreen
              return Column(
                children: [
                   Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Cari barang...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(25.0))),
                      ),
                      onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.namaBarang),
                          subtitle: Text('Stok: ${item.stok} | ${numberFormat.format(item.hargaJual)}'),
                          onTap: item.stok > 0
                              ? () => ref.read(cartProvider.notifier).addItemToCart(item)
                              : null, // Disable tap jika stok habis
                          // FIXED: deprecated_member_use
                          tileColor: item.stok <= 0 ? Colors.grey.withAlpha(77) : null,
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
      // Tombol bayar di bawah
      bottomNavigationBar: cartState.items.isEmpty
          ? null
          : BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total: ${numberFormat.format(cartState.total)}', style: Theme.of(context).textTheme.headlineSmall),
                    ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(context, ref, cartState.total),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      icon: const Icon(Icons.payment),
                      label: const Text('Bayar'),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  // Fungsi untuk menampilkan dialog pembayaran
  void _showPaymentDialog(BuildContext context, WidgetRef ref, int totalBelanja) {
    showDialog(
      context: context,
      builder: (context) {
        return PaymentDialog(totalBelanja: totalBelanja);
      },
    );
  }
}


// Widget untuk dialog pembayaran
class PaymentDialog extends ConsumerStatefulWidget {
  final int totalBelanja;
  const PaymentDialog({required this.totalBelanja, super.key});

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _paymentController = TextEditingController();

  String _paymentMethod = 'Cash';
  String _paymentStatus = 'Lunas';
  Customer? _selectedCustomer;

  @override
  void initState() {
    super.initState();
    // Jika lunas, otomatis isi jumlah bayar
    _paymentController.text = widget.totalBelanja.toString();
  }
  
  @override
  void dispose() {
    _paymentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerProvider);

    return AlertDialog(
      title: const Text('Proses Pembayaran'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Belanja: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(widget.totalBelanja)}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _paymentController,
                decoration: const InputDecoration(labelText: 'Jumlah Bayar'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Metode Pembayaran'),
                items: ['Cash', 'Transfer'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _paymentStatus,
                decoration: const InputDecoration(labelText: 'Status Pembayaran'),
                items: ['Lunas', 'Belum Lunas', 'DP'].map((String value) {
                  return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                onChanged: (value) => setState(() => _paymentStatus = value!),
              ),
              if (_paymentStatus != 'Lunas') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<Customer>(
                  value: _selectedCustomer,
                  decoration: const InputDecoration(labelText: 'Pilih Pelanggan'),
                  items: customers.map((Customer customer) {
                    return DropdownMenuItem<Customer>(value: customer, child: Text(customer.namaPelanggan));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedCustomer = value!),
                  validator: (value) => value == null ? 'Pelanggan harus dipilih untuk utang' : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              // FIXED: use_build_context_synchronously
              final navigator = Navigator.of(context);
              final newTransaction = await ref.read(transactionProvider.notifier).addTransaction(
                    items: ref.read(cartProvider).items,
                    totalBelanja: widget.totalBelanja,
                    totalBayar: int.parse(_paymentController.text),
                    metodePembayaran: _paymentMethod,
                    statusPembayaran: _paymentStatus,
                    pelanggan: _selectedCustomer,
                  );

              if (newTransaction != null) {
                ref.read(cartProvider.notifier).clearCart(); // Kosongkan keranjang
                navigator.pop(); // Tutup dialog
                navigator.pushReplacement( // Ganti halaman, jangan bisa kembali ke kasir dengan data lama
                  MaterialPageRoute(builder: (context) => ReceiptScreen(transaction: newTransaction)),
                );
              }
            }
          },
          child: const Text('Proses & Cetak'),
        )
      ],
    );
  }
}