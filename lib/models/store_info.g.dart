// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_info.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StoreInfoAdapter extends TypeAdapter<StoreInfo> {
  @override
  final int typeId = 4;

  @override
  StoreInfo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StoreInfo(
      name: fields[0] as String,
      address: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, StoreInfo obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.address);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreInfoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
