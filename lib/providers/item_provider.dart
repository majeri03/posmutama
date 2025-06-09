import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/services/hive_service.dart';
import 'package:uuid/uuid.dart';

// 1. Provider untuk instance HiveService.
// Ini adalah provider sederhana yang hanya membuat dan menyediakan instance HiveService
// agar bisa diakses oleh provider lain.
final hiveServiceProvider = Provider<HiveService>((ref) => HiveService());

// 2. Provider untuk State Notifier Inventaris.
// Ini adalah provider utama yang akan Anda gunakan di UI untuk mendapatkan data
// dan memanggil fungsi-fungsi terkait manajemen barang.
final itemProvider = StateNotifierProvider<ItemNotifier, List<Item>>((ref) {
  // Mengambil instance HiveService dari provider di atas.
  final hiveService = ref.watch(hiveServiceProvider);
  // Menginisialisasi Notifier dengan daftar barang awal dari database.
  return ItemNotifier(hiveService);
});

// Kelas Notifier yang berisi state (data) dan logika (fungsi) untuk
// memanipulasi state inventaris.
class ItemNotifier extends StateNotifier<List<Item>> {
  final HiveService _hiveService;

  // Constructor: saat Notifier pertama kali dibuat, ia akan memuat
  // data awal dari HiveService.
  ItemNotifier(this._hiveService) : super([]) {
    loadItems();
  }

  // Memuat semua barang dari database dan memperbarui state.
  // Ini akan secara otomatis memberi tahu UI untuk me-render ulang.
  void loadItems() {
    state = _hiveService.getAllItems()
      // Mengurutkan berdasarkan tanggal ditambahkannya, yang terbaru di atas.
      ..sort((a, b) => b.tanggalDitambahkan.compareTo(a.tanggalDitambahkan));
  }

  // Menambah barang baru ke database.
  void addItem({
    required String namaBarang,
    String? barcode,
    required int hargaBeli,
    required int hargaJual,
    required int stok,
    required String unit,
  }) {
    final newItem = Item(
      id: const Uuid().v4(), // Membuat ID unik untuk barang baru
      namaBarang: namaBarang,
      barcode: barcode,
      hargaBeli: hargaBeli,
      hargaJual: hargaJual,
      stok: stok,
      unit: unit,
      tanggalDitambahkan: DateTime.now(),
    );
    _hiveService.saveItem(newItem);
    loadItems(); // Memuat ulang daftar untuk menampilkan data baru di UI.
  }

  // Memperbarui data barang yang sudah ada.
  void updateItem(Item updatedItem) {
    _hiveService.saveItem(updatedItem);
    loadItems(); // Memuat ulang untuk menampilkan perubahan di UI.
  }
  
  // Mengurangi stok barang (akan digunakan nanti saat terjadi penjualan di kasir).
  void decreaseStock(String itemId, int quantity) {
    final item = _hiveService.getItem(itemId);
    if (item != null) {
      // Pastikan stok tidak menjadi negatif.
      if (item.stok >= quantity) {
        item.stok -= quantity;
        _hiveService.saveItem(item);
        loadItems();
      }
    }
  }

  // Menghapus barang dari database.
  void deleteItem(String id) {
    _hiveService.deleteItem(id);
    loadItems(); // Memuat ulang daftar.
  }
}
