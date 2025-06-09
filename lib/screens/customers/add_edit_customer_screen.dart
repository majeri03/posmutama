import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/providers/customer_provider.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool get _isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.namaPelanggan ?? '');
    _phoneController = TextEditingController(text: widget.customer?.noHp ?? '');
    _addressController = TextEditingController(text: widget.customer?.alamat ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      final customerNotifier = ref.read(customerProvider.notifier);
      final noHp = _phoneController.text.isNotEmpty ? _phoneController.text : null;
      final alamat = _addressController.text.isNotEmpty ? _addressController.text : null;

      if (_isEditMode) {
        final updatedCustomer = Customer(
          id: widget.customer!.id,
          namaPelanggan: _nameController.text,
          noHp: noHp,
          alamat: alamat,
          totalUtang: widget.customer!.totalUtang, // Utang tidak diubah di form ini
        );
        customerNotifier.updateCustomer(updatedCustomer);
      } else {
        customerNotifier.addCustomer(
          namaPelanggan: _nameController.text,
          noHp: noHp,
          alamat: alamat,
        );
      }
      Navigator.pop(context);
    }
  }

  void _deleteCustomer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Anda yakin ingin menghapus ${widget.customer!.namaPelanggan}? Aksi ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(customerProvider.notifier).deleteCustomer(widget.customer!.id);
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke daftar pelanggan
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
        title: Text(_isEditMode ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCustomer,
              tooltip: 'Hapus Pelanggan',
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
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'No. HP (Opsional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat (Opsional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveCustomer,
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
