import 'package:hive/hive.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/transaction_item.dart';
import 'package:pos_mutama/models/payment_record.dart';

part 'transaction.g.dart';

@HiveType(typeId: 2)
class Transaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  List<TransactionItem> items;

  @HiveField(3)
  int totalAmount;

  @HiveField(4)
  Customer? customer;

  @HiveField(5)
  String status; // e.g., 'Lunas', 'Belum Lunas'


  @HiveField(7)
  int changeAmount;

  @HiveField(8)
  String paymentMethod;

  // --- FIELD BARU UNTUK RIWAYAT PEMBAYARAN ---
  @HiveField(9) // Gunakan nomor field berikutnya yang kosong
  List<PaymentRecord> paymentHistory;

  // --- paidAmount MENJADI GETTER ---
  int get paidAmount {
    if (paymentHistory.isEmpty) return 0;
    return paymentHistory.fold(0, (sum, record) => sum + record.amount);
  }


  Transaction({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.customer,
    required this.status,
    required this.changeAmount,
    required this.paymentMethod,
    required this.paymentHistory,
  });
   Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'totalAmount': totalAmount,
        'customer': customer?.toJson(),
        'status': status,
        'changeAmount': changeAmount,
        'paymentMethod': paymentMethod,
        'paymentHistory': paymentHistory.map((p) => p.toJson()).toList(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        date: DateTime.parse(json['date']),
        items: List<TransactionItem>.from(
            json['items']?.map((x) => TransactionItem.fromJson(x))),
        totalAmount: json['totalAmount'],
        customer: json['customer'] != null ? Customer.fromJson(json['customer']) : null,
        status: json['status'],
        changeAmount: json['changeAmount'],
        paymentMethod: json['paymentMethod'],
        paymentHistory: List<PaymentRecord>.from(
            json['paymentHistory']?.map((x) => PaymentRecord.fromJson(x)) ?? []),
  );
}
