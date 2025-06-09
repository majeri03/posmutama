// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemAdapter extends TypeAdapter<Item> {
  @override
  final int typeId = 0;

  @override
  Item read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Item(
      id: fields[0] as String,
      namaBarang: fields[1] as String,
      barcode: fields[2] as String?,
      hargaBeli: fields[3] as int,
      hargaJual: fields[4] as int,
      stok: fields[5] as int,
      unit: fields[6] as String,
      tanggalDitambahkan: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Item obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.namaBarang)
      ..writeByte(2)
      ..write(obj.barcode)
      ..writeByte(3)
      ..write(obj.hargaBeli)
      ..writeByte(4)
      ..write(obj.hargaJual)
      ..writeByte(5)
      ..write(obj.stok)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.tanggalDitambahkan);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
