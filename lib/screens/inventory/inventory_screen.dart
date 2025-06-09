import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/screens/inventory/add_edit_item_screen.dart';
import 'package:pos_mutama/utils/csv_helper.dart';

// Provider untuk state pencarian
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider turunan (derived) untuk memfilter daftar barang berdasarkan pencarian
final filteredItemsProvider = Provider<List<Item>>((ref) {
  final items = ref.watch(itemProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  if (query.isEmpty) {
    return items;
  }

  return items.where((item) {
    final nameMatch = item.namaBarang.toLowerCase().contains(query);
    final barcodeMatch = item.barcode?.toLowerCase().contains(query) ?? false;
    return nameMatch || barcodeMatch;
  }).toList();
});

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mendengarkan perubahan pada daftar barang yang sudah difilter
    final filteredItems = ref.watch(filteredItemsProvider);
    final allItems = ref.watch(itemProvider); // Untuk ekspor semua data
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris Barang'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') {
                CsvHelper.importItemsFromCsv(context, ref);
              } else if (value == 'export') {
                CsvHelper.exportItemsToCsv(context, allItems);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'import',
                child: ListTile(leading: Icon(Icons.upload_file), title: Text('Import dari CSV')),
              ),
              const PopupMenuItem<String>(
                value: 'export',
                child: ListTile(leading: Icon(Icons.download_for_offline), title: Text('Export ke CSV')),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cari barang (nama atau barcode)...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
              // Setiap kali teks berubah, perbarui state pencarian
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
        ),
      ),
      body: filteredItems.isEmpty
          ? const Center(child: Text('Tidak ada barang. Silakan tambah.'))
          : ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(item.namaBarang),
                    subtitle: Text(
                      'Stok: ${item.stok} ${item.unit} | Harga: ${numberFormat.format(item.hargaJual)}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigasi ke halaman edit saat item di-tap
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditItemScreen(item: item),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigasi ke halaman tambah (tanpa mengirim item)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditItemScreen(),
            ),
          );
        },
        tooltip: 'Tambah Barang Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}
