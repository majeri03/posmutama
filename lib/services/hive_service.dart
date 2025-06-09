import 'package:hive/hive.dart';
import 'package:pos_mutama/constants/app_constants.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/transaction.dart';

// Kelas ini berfungsi sebagai jembatan antara aplikasi dan database Hive.
// Semua operasi CRUD (Create, Read, Update, Delete) untuk semua model data
// didefinisikan di sini.
class HiveService {
  // --- Operasi untuk Barang (Item) ---

  // Mendapatkan box (tabel) untuk Item
  Box<Item> get _itemBox => Hive.box<Item>(AppConstants.itemBox);

  // Menambah atau Memperbarui Item
  Future<void> saveItem(Item item) async {
    // `put` akan menambah data baru jika `key` belum ada,
    // atau memperbarui data jika `key` sudah ada.
    await _itemBox.put(item.id, item);
  }

  // Mendapatkan satu Item berdasarkan ID
  Item? getItem(String id) {
    return _itemBox.get(id);
  }

  // Mendapatkan semua Item
  List<Item> getAllItems() {
    // KESALAHAN ADA DI SINI, SEKARANG SUDAH DIPERBAIKI
    return _itemBox.values.toList();
  }

  // Menghapus Item berdasarkan ID
  Future<void> deleteItem(String id) async {
    await _itemBox.delete(id);
  }

  // --- Operasi untuk Pelanggan (Customer) ---

  // Mendapatkan box untuk Customer
  Box<Customer> get _customerBox => Hive.box<Customer>(AppConstants.customerBox);

  // Menambah atau Memperbarui Pelanggan
  Future<void> saveCustomer(Customer customer) async {
    await _customerBox.put(customer.id, customer);
  }

  // Mendapatkan satu Pelanggan berdasarkan ID
  Customer? getCustomer(String id) {
    return _customerBox.get(id);
  }

  // Mendapatkan semua Pelanggan
  List<Customer> getAllCustomers() {
    return _customerBox.values.toList();
  }

  // Menghapus Pelanggan berdasarkan ID
  Future<void> deleteCustomer(String id) async {
    await _customerBox.delete(id);
  }

  // --- Operasi untuk Transaksi (Transaction) ---

  // Mendapatkan box untuk Transaction
  Box<Transaction> get _transactionBox => Hive.box<Transaction>(AppConstants.transactionBox);

  // Menambah Transaksi baru
  Future<void> saveTransaction(Transaction transaction) async {
    await _transactionBox.put(transaction.id, transaction);
  }

  // Mendapatkan semua Transaksi
  List<Transaction> getAllTransactions() {
    // Mengurutkan dari yang terbaru ke yang terlama
    var transactions = _transactionBox.values.toList();
    transactions.sort((a, b) => b.tanggalTransaksi.compareTo(a.tanggalTransaksi));
    return transactions;
  }
}