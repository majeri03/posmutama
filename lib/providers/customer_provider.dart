import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/services/hive_service.dart';
import 'package:uuid/uuid.dart';

final customerProvider = StateNotifierProvider<CustomerNotifier, List<Customer>>((ref) {
  return CustomerNotifier();
});

class CustomerNotifier extends StateNotifier<List<Customer>> {
  final Box<Customer> _box;
  final _uuid = const Uuid();

  CustomerNotifier()
      : _box = Hive.box<Customer>(HiveService.customersBoxName),
        super([]) {
    state = _box.values.toList();
  }

  Future<void> addCustomer(String name, String? phone, String? address) async {
    final newCustomer = Customer(
      id: _uuid.v4(),
      name: name,
      phone: phone,
      address: address,
    );
    await _box.put(newCustomer.id, newCustomer);
    state = _box.values.toList();
  }

  Future<void> editCustomer(String id, String name, String? phone, String? address) async {
    final customer = _box.get(id);
    if (customer != null) {
      customer.name = name;
      customer.phone = phone;
      customer.address = address;
      await customer.save();
      state = _box.values.toList();
    }
  }

  Future<void> deleteCustomer(String id) async {
    await _box.delete(id);
    state = _box.values.toList();
  }
}
