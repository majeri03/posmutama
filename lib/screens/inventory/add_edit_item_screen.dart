// KODE LENGKAP DAN SUDAH DIPERBAIKI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/item_unit.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/screens/pos/scanner_screen.dart';

class AddEditItemScreen extends ConsumerStatefulWidget {
  final Item? item;

  const AddEditItemScreen({super.key, this.item});

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _barcodeController;

  final List<Map<String, TextEditingController>> _unitControllers = [];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _barcodeController = TextEditingController(text: item?.barcode ?? '');

    if (item != null) {
      _stockController = TextEditingController(text: item.stockInBaseUnit.toString());
      for (var unit in item.units) {
        _addUnitController(
          name: unit.name,
          purchasePrice: unit.purchasePrice.toString(),
          price: unit.price.toString(),
          conversionRate: unit.conversionRate.toString(),
        );
      }
    } else {
      _stockController = TextEditingController();
      _addUnitController(); // Mulai dengan satu unit dasar
    }
  }

  void _addUnitController({String? name, String? purchasePrice, String? price, String? conversionRate}) {
    setState(() {
      _unitControllers.add({
        'name': TextEditingController(text: name ?? ''),
        'purchasePrice': TextEditingController(text: purchasePrice ?? ''),
        'price': TextEditingController(text: price ?? ''),
        'conversionRate': TextEditingController(text: conversionRate ?? (_unitControllers.isEmpty ? '1' : '')),
      });
    });
  }

  void _removeUnitController(int index) {
    setState(() {
      for (var controller in _unitControllers[index].values) {
        controller.dispose();
      }
      _unitControllers.removeAt(index);
    });
  }
  
  // GANTI SELURUH FUNGSI LAMA DENGAN YANG INI
  void _suggestPriceMarkup() {
    if (_unitControllers.isEmpty || _unitControllers.first['purchasePrice']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi Harga Beli Satuan Dasar terlebih dahulu.")));
      return;
    }
    final basePurchasePrice = double.tryParse(_unitControllers.first['purchasePrice']!.text) ?? 0.0;
    if (basePurchasePrice == 0) return;

    showDialog(
      context: context,
      builder: (context) {
        final markupController = TextEditingController();
        return AlertDialog(
          title: const Text("Markup Harga (%)"),
          content: TextField(
            controller: markupController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Persentase Markup', hintText: 'Contoh: 20'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                final markup = double.tryParse(markupController.text) ?? 0;
                setState(() {
                  for (var unitController in _unitControllers) {
                    final conversionRate = int.tryParse(unitController['conversionRate']!.text) ?? 1;

                    // LOGIKA BARU: Hitung dan isi Harga Beli (Modal)
                    final calculatedPurchasePrice = basePurchasePrice * conversionRate;
                    unitController['purchasePrice']!.text = calculatedPurchasePrice.toStringAsFixed(0); // Dibulatkan tanpa desimal

                    // LOGIKA LAMA (disempurnakan): Hitung dan isi Harga Jual
                    final calculatedSellPrice = calculatedPurchasePrice * (1 + (markup / 100));
                    unitController['price']!.text = calculatedSellPrice.round().toString();
                  }
                });
                Navigator.pop(context);
              },
              child: const Text("Terapkan"),
            ),
          ],
        );
      },
    );
  }

  void _suggestPriceDivision() {
  if (_unitControllers.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur ini memerlukan minimal 2 satuan.")));
    return;
  }
  int largestUnitIndex = -1;
  int maxConversion = 0;
  for (int i = 0; i < _unitControllers.length; i++) {
    final rate = int.tryParse(_unitControllers[i]['conversionRate']!.text) ?? 0;
    if (rate > maxConversion) {
      maxConversion = rate;
      largestUnitIndex = i;
    }
  }

  final largestUnitPurchasePriceCtrl = _unitControllers[largestUnitIndex]['purchasePrice']!;
  final largestUnitSellPriceCtrl = _unitControllers[largestUnitIndex]['price']!;

  if (largestUnitPurchasePriceCtrl.text.isEmpty || largestUnitSellPriceCtrl.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi Harga Beli & Jual untuk satuan terbesar terlebih dahulu.")));
    return;
  }

  final largestUnitPurchasePrice = double.tryParse(largestUnitPurchasePriceCtrl.text) ?? 0.0;
  final largestUnitSellPrice = int.tryParse(largestUnitSellPriceCtrl.text) ?? 0;
  
  if (maxConversion == 0 || largestUnitPurchasePrice == 0 || largestUnitSellPrice == 0) return;

  final purchasePricePerBaseUnit = largestUnitPurchasePrice / maxConversion;
  final sellPricePerBaseUnit = largestUnitSellPrice / maxConversion;

  setState(() {
    for (var unitController in _unitControllers) {
      final conversionRate = int.tryParse(unitController['conversionRate']!.text) ?? 1;
      
      // LOGIKA BARU: Hitung Harga Beli
      final calculatedPurchasePrice = purchasePricePerBaseUnit * conversionRate;
      unitController['purchasePrice']!.text = calculatedPurchasePrice.toStringAsFixed(0);
      
      // LOGIKA LAMA (disempurnakan): Hitung Harga Jual
      final calculatedSellPrice = sellPricePerBaseUnit * conversionRate;
      unitController['price']!.text = calculatedSellPrice.round().toString();
    }
  });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Harga berhasil dihitung berdasarkan satuan terbesar."))
      );
  }
  
  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final stockInBaseUnit = int.tryParse(_stockController.text) ?? 0;
      final barcode = _barcodeController.text.isNotEmpty ? _barcodeController.text : null;
      final List<ItemUnit> units = _unitControllers.map((controllers) {
        return ItemUnit(
          name: controllers['name']!.text,
          purchasePrice: double.parse(controllers['purchasePrice']!.text),
          price: int.parse(controllers['price']!.text),
          conversionRate: int.parse(controllers['conversionRate']!.text),
        );
      }).toList();
      if (widget.item == null) {
        ref.read(itemProvider.notifier).addItem(name, stockInBaseUnit, barcode, units);
      } else {
        ref.read(itemProvider.notifier).editItem(widget.item!.id, name, stockInBaseUnit, barcode, units);
      }
      Navigator.of(context).pop();
    }
  }

  void _showGuidanceDialog() {
  showDialog(
    context: context,
    builder: (context) {
      final headerStyle = const TextStyle(fontWeight: FontWeight.bold);
      final cellPadding = const EdgeInsets.all(8.0);
      return AlertDialog(
        title: const Text('Panduan Pengisian Satuan'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Konsep utama adalah "Satuan Dasar", yaitu satuan terkecil dari item Anda (contoh: Gram, Pcs, Ml).\n',
              ),
              const Text(
                '1. Satuan pertama yang Anda isi dianggap sebagai Satuan Dasar. Kolom "Isi/Konversi"-nya harus selalu diisi "1".',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '2. Satuan berikutnya diukur berdasarkan Satuan Dasar tersebut.',
              ),
              const SizedBox(height: 16),
              const Text('Contoh Kasus: Paku (Satuan Dasar = Gram)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Table(
                border: TableBorder.all(color: Colors.grey),
                children: [
                  TableRow(children: [
                    Padding(padding: cellPadding, child: Text('Nama Satuan', style: headerStyle)),
                    Padding(padding: cellPadding, child: Text('Isi / Konversi', style: headerStyle)),
                  ]),
                  TableRow(children: [
                    Padding(padding: cellPadding, child: const Text('Gram (Dasar)')),
                    Padding(padding: cellPadding, child: const Text('1')),
                  ]),
                  TableRow(children: [
                    Padding(padding: cellPadding, child: const Text('1/4 kg')),
                    Padding(padding: cellPadding, child: const Text('250')),
                  ]),
                   TableRow(children: [
                    Padding(padding: cellPadding, child: const Text('1/2 kg')),
                    Padding(padding: cellPadding, child: const Text('500')),
                  ]),
                   TableRow(children: [
                    Padding(padding: cellPadding, child: const Text('1 kg')),
                    Padding(padding: cellPadding, child: const Text('1000')),
                  ]),
                ],
              ),
               const SizedBox(height: 16),
               const Text('Tips: Gunakan tombol "Markup" atau "Pembagian" untuk menghitung harga jual & beli secara otomatis.'),

            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      );
    },
  );
}

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    for (var map in _unitControllers) {
      for (var controller in map.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  // METHOD BUILD YANG HILANG SEKARANG SUDAH ADA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Tambah Item' : 'Edit Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Item'),
                validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stok (dalam satuan terkecil)'),
                keyboardType: TextInputType.number,
                validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode (Opsional)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Pindai Barcode',
                    onPressed: () async {
                      final String? scannedBarcode = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (context) => const ScannerScreen(),
                        ),
                      );

                      if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
                        setState(() {
                          _barcodeController.text = scannedBarcode;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(icon: const Icon(Icons.arrow_upward), onPressed: _suggestPriceMarkup, label: const Text("Markup")),
                  ElevatedButton.icon(icon: const Icon(Icons.arrow_downward), onPressed: _suggestPriceDivision, label: const Text("Pembagian")),
                ],
              ),
             const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Daftar Satuan", style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: _showGuidanceDialog, 
                      tooltip: 'Lihat Panduan Pengisian',
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _unitControllers.length,
                itemBuilder: (context, index) {
                  final isBaseUnit = index == 0;
                  // Dapatkan gaya teks untuk label agar konsisten
                  final labelStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w600
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Ratakan semua ke kiri
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Satuan ${index + 1}${isBaseUnit ? ' (Dasar)' : ''}",
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isBaseUnit)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeUnitController(index),
                                  tooltip: 'Hapus Satuan',
                                )
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 12),

                          // --- PERBAIKAN UI DIMULAI DI SINI ---

                          // Label untuk Nama Satuan
                          Text("Nama Satuan", style: labelStyle),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _unitControllers[index]['name'],
                            decoration: const InputDecoration(hintText: 'Contoh: Pcs, Dus, Sak'),
                            validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Label untuk Harga Beli
                          Text("Harga Beli (Modal)", style: labelStyle),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _unitControllers[index]['purchasePrice'],
                            decoration: const InputDecoration(hintText: '0', prefixText: 'Rp '),
                            keyboardType: TextInputType.number,
                            validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Label untuk Harga Jual
                          Text("Harga Jual", style: labelStyle),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _unitControllers[index]['price'],
                            decoration: const InputDecoration(hintText: '0', prefixText: 'Rp '),
                            keyboardType: TextInputType.number,
                            validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          // Label untuk Konversi
                          Text("Isi / Konversi ke Satuan Dasar", style: labelStyle),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _unitControllers[index]['conversionRate'],
                            decoration: InputDecoration(
                              hintText: 'Contoh: 12 (untuk Lusin)',
                              enabled: !isBaseUnit,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Tambah Satuan"),
                onPressed: _addUnitController,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveItem,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}