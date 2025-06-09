import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/providers/item_provider.dart';
import 'package:pos_mutama/screens/pos/scanner_screen.dart'; // Impor halaman scanner baru

class AddEditItemScreen extends ConsumerStatefulWidget {
  final Item? item;

  const AddEditItemScreen({super.key, this.item});

  @override
  ConsumerState<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends ConsumerState<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;

  bool get _isEditMode => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.namaBarang ?? '');
    _barcodeController = TextEditingController(text: widget.item?.barcode ?? '');
    _purchasePriceController =
        TextEditingController(text: widget.item?.hargaBeli.toString() ?? '');
    _sellingPriceController =
        TextEditingController(text: widget.item?.hargaJual.toString() ?? '');
    _stockController =
        TextEditingController(text: widget.item?.stok.toString() ?? '');
    _unitController = TextEditingController(text: widget.item?.unit ?? 'Pcs');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  // Fungsi untuk scan barcode (DIGANTI)
  Future<void> _scanBarcode() async {
    // Buka halaman scanner dan tunggu hasilnya
    final barcodeResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    // Jika ada hasil (tidak null) dan widget masih ada, masukkan ke controller
    if (barcodeResult != null && mounted) {
      setState(() {
        _barcodeController.text = barcodeResult;
      });
    }
  }

  void _saveItem() {
    if (_formKey.currentState!.validate()) {
      final itemNotifier = ref.read(itemProvider.notifier);

      if (_isEditMode) {
        final updatedItem = Item(
          id: widget.item!.id,
          namaBarang: _nameController.text,
          barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
          hargaBeli: int.parse(_purchasePriceController.text),
          hargaJual: int.parse(_sellingPriceController.text),
          stok: int.parse(_stockController.text),
          unit: _unitController.text,
          tanggalDitambahkan: widget.item!.tanggalDitambahkan,
        );
        itemNotifier.updateItem(updatedItem);
      } else {
        itemNotifier.addItem(
          namaBarang: _nameController.text,
          barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
          hargaBeli: int.parse(_purchasePriceController.text),
          hargaJual: int.parse(_sellingPriceController.text),
          stok: int.parse(_stockController.text),
          unit: _unitController.text,
        );
      }
      Navigator.pop(context);
    }
  }
  
  void _deleteItem() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: const Text('Apakah Anda yakin ingin menghapus barang ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(itemProvider.notifier).deleteItem(widget.item!.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Barang' : 'Tambah Barang Baru'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteItem,
              tooltip: 'Hapus Barang',
            ),
        ],
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
                decoration: const InputDecoration(labelText: 'Nama Barang'),
                validator: (value) =>
                    value!.isEmpty ? 'Nama barang tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode (Opsional)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(labelText: 'Harga Beli'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value!.isEmpty ? 'Harga beli tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(labelText: 'Harga Jual'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value!.isEmpty ? 'Harga jual tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stok'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                       validator: (value) =>
                          value!.isEmpty ? 'Stok tidak boleh kosong' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      validator: (value) =>
                          value!.isEmpty ? 'Unit tidak boleh kosong' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveItem,
                icon: const Icon(Icons.save),
                label: const Text('Simpan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
