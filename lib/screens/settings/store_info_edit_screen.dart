import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/providers/store_info_provider.dart';

class StoreInfoEditScreen extends ConsumerStatefulWidget {
  const StoreInfoEditScreen({super.key});

  @override
  ConsumerState<StoreInfoEditScreen> createState() => _StoreInfoEditScreenState();
}

class _StoreInfoEditScreenState extends ConsumerState<StoreInfoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final storeInfo = ref.read(storeInfoProvider);
    if (storeInfo != null) {
      _nameController.text = storeInfo.name;
      _addressController.text = storeInfo.address;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _saveStoreInfo() {
    if (_formKey.currentState!.validate()) {
      ref.read(storeInfoProvider.notifier).saveStoreInfo(_nameController.text, _addressController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informasi toko berhasil diperbarui')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubah Informasi Toko'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Nama toko tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Toko',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Alamat toko tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveStoreInfo,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}