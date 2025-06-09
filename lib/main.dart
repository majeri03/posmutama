import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/item.dart';
import 'package:pos_mutama/models/transaction.dart';
import 'package:pos_mutama/models/transaction_item.dart';
import 'package:pos_mutama/screens/main_screen.dart';
import 'package:pos_mutama/constants/app_constants.dart';

Future<void> main() async {
  // Pastikan binding Flutter sudah siap
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Hive
  await initHive();

  // Jalankan aplikasi dengan ProviderScope untuk Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

// Fungsi untuk inisialisasi Hive
Future<void> initHive() async {
  // Dapatkan direktori aplikasi untuk menyimpan database
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Daftarkan semua adapter dari model
  Hive.registerAdapter(ItemAdapter());
  Hive.registerAdapter(CustomerAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionItemAdapter());

  // Buka semua box yang akan digunakan di aplikasi
  await Hive.openBox<Item>(AppConstants.itemBox);
  await Hive.openBox<Customer>(AppConstants.customerBox);
  await Hive.openBox<Transaction>(AppConstants.transactionBox);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS mUtama',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system, // Otomatis mengikuti tema sistem
      home: const MainScreen(),
    );
  }
}
