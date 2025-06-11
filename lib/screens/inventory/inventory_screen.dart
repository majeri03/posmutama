import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/screens/inventory/add_edit_item_screen.dart';
import 'package:pos_mutama/utils/csv_helper.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
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

  // TAMBAHKAN METHOD BARU INI
  void _showCsvFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final headerStyle = const TextStyle(fontWeight: FontWeight.bold);
        return AlertDialog(
          title: const Text('Contoh Format CSV untuk Impor'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Gunakan format ini di file CSV Anda. Setiap baris mewakili satu satuan produk.\n'),
                Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: IntrinsicColumnWidth(),
                    2: IntrinsicColumnWidth(),
                  },
                  children: [
                    TableRow(children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('item_id', style: headerStyle)),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('item_name', style: headerStyle)),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('item_barcode', style: headerStyle)),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('stock_in_base_unit', style: headerStyle)),
                    ]),
                     TableRow(children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('uuid-123')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('Semen Gresik')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('899...')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('100')),
                    ]),
                     TableRow(children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('uuid-123')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('Semen Gresik')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('899...')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('100')),
                    ]),
                  ],
                ),
                 const SizedBox(height: 8),
                 Table(
                  border: TableBorder.all(),
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: IntrinsicColumnWidth(),
                    2: IntrinsicColumnWidth(),
                    3: IntrinsicColumnWidth(),
                  },
                   children: [
                     TableRow(children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('unit_name', style: headerStyle)),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('unit_purchase_price', style: headerStyle)),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('unit_sell_price', style: headerStyle)),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('unit_conversion_rate', style: headerStyle)),
                    ]),
                     TableRow(children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('Sak')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('50000')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('55000')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('1')),
                    ]),
                     TableRow(children: [
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('Palet')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('4000000')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('4400000')),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text('80')),
                    ]),
                   ],
                 )
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemProvider).where((item) {
      if (_searchQuery.isEmpty) {
        return true; // Jika tidak ada query, tampilkan semua item
      }
      final searchQuery = _searchQuery.toLowerCase();
      final nameMatches = item.name.toLowerCase().contains(searchQuery);
      // Cek barcode (pastikan barcode tidak null sebelum dicek)
      final barcodeMatches = item.barcode?.toLowerCase().contains(searchQuery) ?? false;

      // Kembalikan true jika nama atau barcode cocok
      return nameMatches || barcodeMatches;
    }).toList();
    final numberFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () async {
              final result = await importItemsFromCsv(ref);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () async {
              await exportItemsToCsv(items);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data item diekspor')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Lihat Format CSV',
            onPressed: () {
              _showCsvFormatDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari berdasarkan nama atau barcode...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('Tidak ada item.'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          title: Text(item.name),
                          subtitle: Text('Stok: ${item.stock} | Barcode: ${item.barcode ?? '-'}'),
                          trailing: Text(numberFormat.format(item.price)),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(item.name),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Stok: ${item.stock}'),
                                    Text('Harga Jual: ${numberFormat.format(item.price)}'),
                                    Text('Harga Beli: ${numberFormat.format(item.purchasePrice)}'),
                                    Text('Barcode: ${item.barcode ?? '-'}'),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Tutup'),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                  TextButton(
                                    child: const Text('Edit'),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => AddEditItemScreen(item: item),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
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
              builder: (context) => const AddEditItemScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
