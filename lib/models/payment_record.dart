import 'package:hive/hive.dart';

part 'payment_record.g.dart';

@HiveType(typeId: 6) // Pastikan typeId ini unik (belum dipakai)
class PaymentRecord extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int amount;

  PaymentRecord({
    required this.date,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'amount': amount,
  };

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    date: DateTime.parse(json['date']),
    amount: json['amount'],
  );
}