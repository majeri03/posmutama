import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:pos_mutama/models/store_info.dart';
import 'package:pos_mutama/services/hive_service.dart';

final storeInfoProvider = StateNotifierProvider<StoreInfoNotifier, StoreInfo?>((ref) {
  return StoreInfoNotifier();
});

class StoreInfoNotifier extends StateNotifier<StoreInfo?> {
  final Box<StoreInfo> _box;

  StoreInfoNotifier()
      : _box = Hive.box<StoreInfo>(HiveService.storeInfoBoxName),
        super(null) {
    if (_box.isNotEmpty) {
      state = _box.getAt(0);
    }
  }

  Future<void> saveStoreInfo(String name, String address) async {
    final storeInfo = StoreInfo(name: name, address: address);
    await _box.clear();
    await _box.add(storeInfo);
    state = storeInfo;
  }

  void updateStoreInfo(String name, String address) {
     if (state != null) {
      state!.name = name;
      state!.address = address;
      state!.save();
      // To trigger UI update
      state = StoreInfo(name: state!.name, address: state!.address);
    }
  }
}
