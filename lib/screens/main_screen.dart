import 'package:flutter/material.dart';
import 'package:pos_mutama/screens/customers/customers_screen.dart';
import 'package:pos_mutama/screens/inventory/inventory_screen.dart';
import 'package:pos_mutama/screens/pos/pos_screen.dart';
import 'package:pos_mutama/screens/reports/reports_screen.dart';
import 'package:pos_mutama/screens/settings/settings_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    POSScreen(),
    InventoryScreen(),
    ReportsScreen(),
    CustomersScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    // Panggil pengecekan setelah frame pertama selesai di-render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerAutoBackup();
    });
  }

  Future<void> _checkAndTriggerAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    // Ambil timestamp backup terakhir, jika tidak ada, anggap 0
    final lastBackupTimestamp = prefs.getInt('lastBackupTimestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // Durasi 7 hari dalam milidetik
    const sevenDaysInMillis = 7 * 24 * 60 * 60 * 1000;

    if ((now - lastBackupTimestamp) > sevenDaysInMillis) {
      // Jika sudah lebih dari 7 hari, tampilkan dialog wajib backup
      _showForcedBackupDialog();
    }
  }

  void _showForcedBackupDialog() {
    final backupHelper = BackupRestoreHelper();

    showDialog(
      context: context,
      // Mencegah dialog ditutup dengan menekan area luar
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Mencegah dialog ditutup dengan tombol "back" di Android
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text('Backup Data Mingguan'),
            content: const Text(
                'Sudah lebih dari 7 hari sejak backup terakhir. Untuk keamanan, Anda wajib melakukan backup data sekarang.'),
            actions: [
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Simpan Backup Sekarang'),
                onPressed: () async {
                  // Lakukan proses backup
                  final result = await backupHelper.createBackup();
                  
                  // Cek apakah context masih valid sebelum digunakan
                  if (!dialogContext.mounted) return;

                  // Tampilkan hasil backup
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(result)),
                  );

                  // Jika backup berhasil (ada path yang dikembalikan oleh file_saver)
                  if (!result.contains("Gagal")) {
                    // Simpan timestamp baru
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('lastBackupTimestamp', DateTime.now().millisecondsSinceEpoch);
                    
                    // Tutup dialog
                    Navigator.of(dialogContext).pop();
                  }
                },
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Kasir',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventaris',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Laporan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Pelanggan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}