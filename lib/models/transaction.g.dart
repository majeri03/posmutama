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
      tanggalTransaksi: fields[1] as DateTime,
      items: (fields[2] as List).cast<TransactionItem>(),
      totalBelanja: fields[3] as int,
      totalBayar: fields[4] as int,
      kembalian: fields[5] as int,
      metodePembayaran: fields[6] as String,
      statusPembayaran: fields[7] as String,
      idPelanggan: fields[8] as String?,
      namaKasir: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tanggalTransaksi)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.totalBelanja)
      ..writeByte(4)
      ..write(obj.totalBayar)
      ..writeByte(5)
      ..write(obj.kembalian)
      ..writeByte(6)
      ..write(obj.metodePembayaran)
      ..writeByte(7)
      ..write(obj.statusPembayaran)
      ..writeByte(8)
      ..write(obj.idPelanggan)
      ..writeByte(9)
      ..write(obj.namaKasir);
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
