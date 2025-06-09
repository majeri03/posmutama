import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/services/hive_service.dart';
import 'package:pos_mutama/providers/item_provider.dart'; // Untuk mengakses hiveServiceProvider
import 'package:uuid/uuid.dart';

// Provider untuk state notifier pelanggan
final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return CustomerNotifier(hiveService);
});

// Kelas Notifier untuk logika bisnis pelanggan
class CustomerNotifier extends StateNotifier<List<Customer>> {
  final HiveService _hiveService;

  // Constructor: memuat data awal dari Hive
  CustomerNotifier(this._hiveService) : super([]) {
    loadCustomers();
  }

  // Memuat semua pelanggan dan memperbarui state
  void loadCustomers() {
    state = _hiveService.getAllCustomers()
      ..sort((a, b) => a.namaPelanggan.toLowerCase().compareTo(b.namaPelanggan.toLowerCase()));
  }

  // Menambah pelanggan baru
  void addCustomer({
    required String namaPelanggan,
    String? noHp,
    String? alamat,
  }) {
    final newCustomer = Customer(
      id: const Uuid().v4(), // ID unik
      namaPelanggan: namaPelanggan,
      noHp: noHp,
      alamat: alamat,
      totalUtang: 0, // Utang awal selalu 0
    );
    _hiveService.saveCustomer(newCustomer);
    loadCustomers(); // Muat ulang daftar
  }

  // Memperbarui data pelanggan
  void updateCustomer(Customer updatedCustomer) {
    _hiveService.saveCustomer(updatedCustomer);
    loadCustomers(); // Muat ulang daftar
  }
  
  // Memperbarui utang pelanggan
  void updateCustomerDebt(String customerId, int amount) {
    final customer = _hiveService.getCustomer(customerId);
    if (customer != null) {
        customer.totalUtang += amount;
        _hiveService.saveCustomer(customer);
        loadCustomers();
    }
  }

  // Menghapus pelanggan
  void deleteCustomer(String id) {
    _hiveService.deleteCustomer(id);
    loadCustomers(); // Muat ulang daftar
  }
}
