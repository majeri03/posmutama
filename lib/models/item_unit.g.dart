// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_unit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemUnitAdapter extends TypeAdapter<ItemUnit> {
  @override
  final int typeId = 5;

  @override
  ItemUnit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemUnit(
      name: fields[0] as String,
      purchasePrice: fields[1] as double,
      price: fields[2] as int,
      conversionRate: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ItemUnit obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.purchasePrice)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.conversionRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
