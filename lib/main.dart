import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pos_mutama/models/store_info.dart';
import 'package:pos_mutama/screens/main_screen.dart';
import 'package:pos_mutama/screens/settings/store_setup_screen.dart';
import 'package:pos_mutama/services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final hiveService = HiveService();
  await hiveService.init();

  final storeInfoBox = Hive.box<StoreInfo>(HiveService.storeInfoBoxName);
  final bool isFirstRun = storeInfoBox.isEmpty;

  runApp(
    ProviderScope(
      child: MyApp(isFirstRun: isFirstRun),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isFirstRun;
  const MyApp({super.key, required this.isFirstRun});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Mutama',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always, 
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: isFirstRun ? const StoreSetupScreen() : const MainScreen(),
    );
  }
}
