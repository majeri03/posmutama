import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/providers/transaction_provider.dart';
import 'package:pos_mutama/screens/customers/add_edit_customer_screen.dart';
import 'package:pos_mutama/screens/reports/transaction_detail_screen.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customerProvider);
    final transactions = ref.watch(transactionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelanggan'),
      ),
      body: customers.isEmpty
          ? const Center(child: Text('Tidak ada pelanggan.'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                final customerTransactions = transactions.where((t) => t.customer?.id == customer.id).toList();
                final unpaidAmount = customerTransactions
                    .where((t) => t.status == 'Belum Lunas')
                    .fold(0, (sum, t) => sum + t.totalAmount);
                final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    title: Text(customer.name),
                    subtitle: unpaidAmount > 0
                        ? Text(
                            'Utang: ${numberFormat.format(unpaidAmount)}',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          )
                        : const Text('Tidak ada utang'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(customer.phone ?? 'No Phone'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(customer.address ?? 'No Address'),
                      ),
                       const Divider(),
                       Padding(
                         padding: const EdgeInsets.all(8.0),
                         child: Text("Riwayat Transaksi", style: Theme.of(context).textTheme.titleSmall),
                       ),
                       if (customerTransactions.isEmpty)
                         const ListTile(title: Text("Tidak ada riwayat transaksi."))
                       else
                        ...customerTransactions.map((tx) => ListTile(
                          title: Text("ID: ${tx.id.substring(0,8)}"),
                          subtitle: Text(DateFormat('dd/MM/yy').format(tx.date)),
                          trailing: Text(numberFormat.format(tx.totalAmount), style: TextStyle(
                            color: tx.status == 'Lunas' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold
                          )),
                          onTap: (){
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
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => AddEditCustomerScreen(customer: customer),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Pelanggan'),
                                  content: const Text('Anda yakin ingin menghapus pelanggan ini?'),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditCustomerScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
