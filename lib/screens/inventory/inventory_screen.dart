import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/screens/inventory/add_edit_item_screen.dart';
import 'package:pos_mutama/utils/csv_helper.dart';
import 'package:pos_mutama/screens/pos/scanner_screen.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';

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

  Future<void> _downloadSampleCsv(BuildContext context) async {
    try {
      // 1. Siapkan data contoh
      List<List<dynamic>> rows = [];
      // Header
      rows.add([
        'item_id', 'item_name', 'item_barcode', 'stock_in_base_unit',
        'unit_name', 'unit_purchase_price', 'unit_sell_price', 'unit_conversion_rate'
      ]);
      // Contoh Item 1 (Semen)
      rows.add([
        'uuid-semen-123', 'Semen Tiga Roda', '899123456001', '100',
        'Sak', '50000', '55000', '1'
      ]);
      rows.add([
        'uuid-semen-123', 'Semen Tiga Roda', '899123456001', '100',
        'Palet', '3950000', '4300000', '80'
      ]);
      // Contoh Item 2 (Paku)
      rows.add([
        'uuid-paku-456', 'Paku 5 inch', '', '5000',
        'Gram', '15', '25', '1'
      ]);
      rows.add([
        'uuid-paku-456', 'Paku 5 inch', '', '5000',
        'Kg', '14500', '24000', '1000'
      ]);

      // 2. Konversi ke format string CSV
      String csvString = const ListToCsvConverter().convert(rows);

      // 3. Simpan file menggunakan file_saver
      await FileSaver.instance.saveFile(
        name: 'contoh_import_item',
        bytes: Uint8List.fromList(utf8.encode(csvString)),
        ext: 'csv',
        mimeType: MimeType.csv,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File contoh berhasil diunduh.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // TAMBAHKAN METHOD BARU INI
  void _showCsvFormatDialog(BuildContext context) {
    final headerStyle = const TextStyle(fontWeight: FontWeight.bold);
    final cellPadding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Panduan Format CSV'),
          content: SingleChildScrollView( // Agar konten dialog bisa di-scroll jika layar kecil
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Gunakan format ini di file CSV Anda. Setiap baris mewakili satu satuan produk.\n'),
                // Membuat tabel bisa di-scroll ke samping
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey),
                    // Atur lebar kolom agar sesuai konten
                    columnWidths: const <int, TableColumnWidth>{
                      0: IntrinsicColumnWidth(),
                      1: IntrinsicColumnWidth(),
                      2: IntrinsicColumnWidth(),
                      3: IntrinsicColumnWidth(),
                      4: IntrinsicColumnWidth(),
                      5: IntrinsicColumnWidth(),
                      6: IntrinsicColumnWidth(),
                      7: IntrinsicColumnWidth(),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // Baris Header
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: [
                          Padding(padding: cellPadding, child: Text('item_id', style: headerStyle)),
                          Padding(padding: cellPadding, child: Text('item_name', style: headerStyle)),
                          Padding(padding: cellPadding, child: Text('item_barcode', style: headerStyle)),
                          Padding(padding: cellPadding, child: Text('stock_in_base_unit', style: headerStyle)),
                          Padding(padding: cellPadding, child: Text('unit_name', style: headerStyle)),
                          Padding(padding: cellPadding, child: Text('unit_purchase_price', style: headerStyle)),
                          Padding(padding: cellPadding, child: Text('unit_sell_price', style: headerStyle)),
                          Padding(padding: cellPadding, child: Text('unit_conversion_rate', style: headerStyle)),
                        ],
                      ),
                      // Baris Contoh 1
                      TableRow(children: [
                        Padding(padding: cellPadding, child: const Text('uuid-semen-123')),
                        Padding(padding: cellPadding, child: const Text('Semen Tiga Roda')),
                        Padding(padding: cellPadding, child: const Text('899123456001')),
                        Padding(padding: cellPadding, child: const Text('100')),
                        Padding(padding: cellPadding, child: const Text('Sak')),
                        Padding(padding: cellPadding, child: const Text('50000')),
                        Padding(padding: cellPadding, child: const Text('55000')),
                        Padding(padding: cellPadding, child: const Text('1')),
                      ]),
                      // Baris Contoh 2
                      TableRow(children: [
                        Padding(padding: cellPadding, child: const Text('uuid-semen-123')),
                        Padding(padding: cellPadding, child: const Text('Semen Tiga Roda')),
                        Padding(padding: cellPadding, child: const Text('899123456001')),
                        Padding(padding: cellPadding, child: const Text('100')),
                        Padding(padding: cellPadding, child: const Text('Palet')),
                        Padding(padding: cellPadding, child: const Text('3950000')),
                        Padding(padding: cellPadding, child: const Text('4300000')),
                        Padding(padding: cellPadding, child: const Text('80')),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('PENTING: item_id, item_name, dan stock_in_base_unit harus sama untuk item yang sama.'),
              ],
            ),
          ),
          actions: [
            // Tombol unduh contoh
            ElevatedButton.icon(
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Unduh Contoh'),
              onPressed: () => _downloadSampleCsv(context),
            ),
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
              decoration: InputDecoration( 
                hintText: 'Cari nama atau pindai barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Pindai untuk Mencari',
                  onPressed: () async {
                    final String? scannedBarcode = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (context) => const ScannerScreen(),
                      ),
                    );

                    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
                      _searchController.text = scannedBarcode;
                    }
                  },
                ),
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
                          subtitle: Text('Stok Dasar: ${item.stockInBaseUnit} ${item.units.first.name} | Barcode: ${item.barcode ?? '-'}'),
                          trailing: Text(numberFormat.format(item.units.first.price)),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(item.name),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Stok Satuan Dasar: ${item.stockInBaseUnit}'),
                                    Text('Harga Jual (Dasar): ${numberFormat.format(item.units.first.price)}'),
                                    Text('Harga Beli (Dasar): ${numberFormat.format(item.units.first.purchasePrice)}'),
                                    Text('Barcode: ${item.barcode ?? '-'}'),
                                    const Divider(),
                                    const Text('Satuan Lain:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ...item.units.map((unit) => Text('- ${unit.name} (1 = ${unit.conversionRate} unit dasar)')),
                                  ],
                                ),
                                actions: [
                                  // Tombol Hapus (BARU)
                                  TextButton(
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    onPressed: () {
                                      // Tutup dialog pertama
                                      Navigator.of(ctx).pop(); 
                                      // Tampilkan dialog konfirmasi kedua (Peringatan Keras)
                                      showDialog(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text('HAPUS ITEM INI?'),
                                          content: const Text(
                                            'Anda yakin ingin menghapus item ini secara permanen? Aksi ini TIDAK DAPAT DIBATALKAN.',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: const Text('Batal'),
                                              onPressed: () => Navigator.of(dialogContext).pop(),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red, // Warna merah untuk menegaskan
                                              ),
                                              child: const Text('Ya, Hapus Permanen'),
                                              onPressed: () {
                                                // Panggil provider untuk hapus item
                                                ref.read(itemProvider.notifier).deleteItem(item.id);
                                                // Tutup dialog konfirmasi
                                                Navigator.of(dialogContext).pop();
                                                // Beri notifikasi
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Item "${item.name}" berhasil dihapus.'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  TextButton(
                                    child: const Text('Edit'),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      if (context.mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => AddEditItemScreen(item: item),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  // Tombol Tutup kita pindah ke paling kanan agar lebih standar
                                  ElevatedButton(
                                    child: const Text('Tutup'),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
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
