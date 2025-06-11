// KODE LENGKAP DAN SUDAH DIPERBAIKI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/item_unit.dart';
import 'package:pos_mutama/providers/item_provider.dart';

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
  
  void _suggestPriceMarkup() {
    if (_unitControllers.isEmpty || _unitControllers.first['purchasePrice']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Isi Harga Beli Satuan Dasar terlebih dahulu.")));
      return;
    }
    final basePurchasePrice = double.parse(_unitControllers.first['purchasePrice']!.text);

    showDialog(
      context: context,
      builder: (context) {
        final markupController = TextEditingController();
        return AlertDialog(
          title: const Text("Markup Harga (%)"),
          content: TextField(
            controller: markupController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Persentase Markup'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                final markup = double.tryParse(markupController.text) ?? 0;
                setState(() {
                  for (var unitController in _unitControllers) {
                    final conversionRate = int.tryParse(unitController['conversionRate']!.text) ?? 1;
                    final calculatedPrice = (basePurchasePrice * conversionRate) * (1 + (markup / 100));
                    unitController['price']!.text = calculatedPrice.round().toString();
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
    if (largestUnitIndex == -1 || _unitControllers[largestUnitIndex]['price']!.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Isi Harga Jual satuan terbesar terlebih dahulu.")));
      return;
    }
    final largestUnitPrice = int.parse(_unitControllers[largestUnitIndex]['price']!.text);
    if (maxConversion == 0) return;
    final pricePerBaseUnit = largestUnitPrice / maxConversion;
    setState(() {
      for (var unitController in _unitControllers) {
        final conversionRate = int.tryParse(unitController['conversionRate']!.text) ?? 1;
        final calculatedPrice = pricePerBaseUnit * conversionRate;
        unitController['price']!.text = calculatedPrice.round().toString();
      }
    });
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
                decoration: const InputDecoration(labelText: 'Barcode (Opsional)'),
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
              Text("Daftar Satuan", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _unitControllers.length,
                itemBuilder: (context, index) {
                  final isBaseUnit = index == 0;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Satuan ${index + 1}${isBaseUnit ? ' (Dasar)' : ''}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (!isBaseUnit)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeUnitController(index),
                                )
                            ],
                          ),
                          TextFormField(
                            controller: _unitControllers[index]['name'],
                            decoration: const InputDecoration(labelText: 'Nama Satuan (e.g. Pcs)'),
                            validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                          TextFormField(
                            controller: _unitControllers[index]['purchasePrice'],
                            decoration: const InputDecoration(labelText: 'Harga Beli (Modal)'),
                            keyboardType: TextInputType.number,
                            validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                          TextFormField(
                            controller: _unitControllers[index]['price'],
                            decoration: const InputDecoration(labelText: 'Harga Jual'),
                            keyboardType: TextInputType.number,
                            validator: (value) => (value?.isEmpty ?? true) ? 'Wajib diisi' : null,
                          ),
                          TextFormField(
                            controller: _unitControllers[index]['conversionRate'],
                            decoration: InputDecoration(
                              labelText: 'Isi / Konversi ke Satuan Dasar',
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