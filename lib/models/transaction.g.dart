// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 2;

  @override
  Transaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Transaction(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      items: (fields[2] as List).cast<TransactionItem>(),
      totalAmount: fields[3] as int,
      customer: fields[4] as Customer?,
      status: fields[5] as String,
      changeAmount: fields[7] as int,
      paymentMethod: fields[8] as String,
      paymentHistory: (fields[9] as List).cast<PaymentRecord>(),
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.customer)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.changeAmount)
      ..writeByte(8)
      ..write(obj.paymentMethod)
      ..writeByte(9)
      ..write(obj.paymentHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
