import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_mutama/screens/settings/store_info_edit_screen.dart';
import 'package:pos_mutama/utils/backup_restore_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupHelper = BackupRestoreHelper();

    void showRestoreConfirmation() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Konfirmasi Pemulihan Data'),
          content: const Text(
              'Aksi ini akan MENGHAPUS SEMUA data saat ini dan menggantinya dengan data dari file backup. Anda yakin ingin melanjutkan?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(ctx).pop();
                final result = await backupHelper.restoreFromBackup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
                }
              },
              child: const Text('Ya, Lanjutkan'),
            )
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Informasi Toko'),
            subtitle: const Text('Ubah nama dan alamat toko'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const StoreInfoEditScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            subtitle: const Text('Simpan semua data ke sebuah file'),
            onTap: () async {
              final result = await backupHelper.createBackup();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            subtitle: const Text('Pulihkan data dari sebuah file'),
            onTap: showRestoreConfirmation,
          ),
        ],
      ),
    );
  }
}