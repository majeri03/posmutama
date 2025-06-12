import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:pos_mutama/screens/customers/add_edit_customer_screen.dart';
import 'package:pos_mutama/screens/reports/transaction_detail_screen.dart';

// --- PERUBAHAN 1: Ubah menjadi ConsumerStatefulWidget ---
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  // --- PERUBAHAN 2: Tambahkan state untuk pencarian ---
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allCustomers = ref.watch(customerProvider);
    final transactions = ref.watch(transactionProvider);

    // --- PERUBAHAN 3: Logika untuk memfilter pelanggan ---
    final filteredCustomers = allCustomers.where((customer) {
      if (_searchQuery.isEmpty) {
        return true;
      }
      final query = _searchQuery.toLowerCase();
      final nameMatches = customer.name.toLowerCase().contains(query);
      final phoneMatches = customer.phone?.toLowerCase().contains(query) ?? false;
      final addressMatches = customer.address?.toLowerCase().contains(query) ?? false;
      
      return nameMatches || phoneMatches || addressMatches;
    }).toList();


    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
      ),
      // --- PERUBAHAN 4: Tambahkan Kolom Pencarian di atas daftar ---
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama, no. HP, atau alamat...',
                prefixIcon: const Icon(Icons.search),
                // Tambahkan tombol clear jika ada teks
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(child: Text('Pelanggan tidak ditemukan.'))
                : ListView.builder(
                    itemCount: filteredCustomers.length, // Gunakan daftar yang sudah difilter
                    itemBuilder: (context, index) {
                      final customer = filteredCustomers[index]; // Gunakan daftar yang sudah difilter
                      final customerTransactions =
                          transactions.where((t) => t.customer?.id == customer.id).toList();
                      
                      // Hitung total utang dari transaksi yang berstatus 'Belum Lunas' atau 'DP'
                      final unpaidAmount = customerTransactions
                          .where((t) => t.status == 'Belum Lunas' || t.status == 'DP')
                          .fold(0, (sum, t) => sum + (t.totalAmount - t.paidAmount));
                          
                      final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ExpansionTile(
                          title: Text(customer.name),
                          subtitle: unpaidAmount > 0
                              ? Text(
                                  'Total Utang: ${numberFormat.format(unpaidAmount)}',
                                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                )
                              : const Text('Tidak ada utang'),
                          children: [
                            ListTile(
                              leading: const Icon(Icons.phone),
                              title: Text(customer.phone ?? 'No. HP tidak ada'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(customer.address ?? 'Alamat tidak ada'),
                            ),
                            const Divider(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Text("Riwayat Transaksi",
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            if (customerTransactions.isEmpty)
                              const ListTile(title: Text("Tidak ada riwayat transaksi."))
                            else
                              ...customerTransactions.map((tx) => ListTile(
                                    title: Text("ID: ${tx.id.substring(0, 8)}"),
                                    subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(tx.date)),
                                    trailing: Text(numberFormat.format(tx.totalAmount),
                                        style: TextStyle(
                                            color: tx.status == 'Lunas' ? Colors.green : Colors.orange,
                                            fontWeight: FontWeight.bold)),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => TransactionDetailScreen(transactionId: tx.id),
                                        ),
                                      );
                                    },
                                  )),
                            OverflowBar(
                              alignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Edit Pelanggan',
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AddEditCustomerScreen(customer: customer),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  tooltip: 'Hapus Pelanggan',
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Hapus Pelanggan'),
                                        content: const Text(
                                            'Anda yakin ingin menghapus pelanggan ini? Aksi ini tidak dapat dibatalkan.'),
                                        actions: [
                                          TextButton(
                                            child: const Text('Batal'),
                                            onPressed: () => Navigator.of(ctx).pop(),
                                          ),
                                          TextButton(
                                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                            onPressed: () {
                                              ref.read(customerProvider.notifier).deleteCustomer(customer.id);
                                              Navigator.of(ctx).pop();
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditCustomerScreen(),
            ),
          );
        },
        tooltip: 'Tambah Pelanggan Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}