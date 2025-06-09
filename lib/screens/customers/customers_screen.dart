import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/providers/customer_provider.dart';
import 'package:pos_mutama/screens/customers/add_edit_customer_screen.dart';

// Provider untuk query pencarian
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

// Provider untuk memfilter daftar pelanggan
final filteredCustomersProvider = Provider<List<Customer>>((ref) {
  final customers = ref.watch(customerProvider);
  final query = ref.watch(customerSearchQueryProvider).toLowerCase();

  if (query.isEmpty) {
    return customers;
  }

  return customers.where((customer) {
    final nameMatch = customer.namaPelanggan.toLowerCase().contains(query);
    final phoneMatch = customer.noHp?.toLowerCase().contains(query) ?? false;
    return nameMatch || phoneMatch;
  }).toList();
});

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(filteredCustomersProvider);
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Pelanggan'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari pelanggan (nama atau no. HP)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
              onChanged: (value) {
                ref.read(customerSearchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: customers.isEmpty
          ? const Center(child: Text('Belum ada data pelanggan.'))
          : ListView.builder(
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(customer.namaPelanggan),
                    subtitle: Text(
                      'No. HP: ${customer.noHp ?? '-'} | Utang: ${numberFormat.format(customer.totalUtang)}',
                      style: TextStyle(
                        color: customer.totalUtang > 0 ? Colors.red : null,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditCustomerScreen(customer: customer),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditCustomerScreen(),
            ),
          );
        },
        tooltip: 'Tambah Pelanggan Baru',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
