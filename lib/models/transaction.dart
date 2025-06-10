import 'package:hive/hive.dart';
import 'package:pos_mutama/models/customer.dart';
import 'package:pos_mutama/models/transaction_item.dart';

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

  @HiveField(6)
  int paidAmount;

  @HiveField(7)
  int changeAmount;

  @HiveField(8)
  String paymentMethod;

  Transaction({
    required this.id,
    required this.date,
    required this.items,
    required this.totalAmount,
    this.customer,
    required this.status,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
        'totalAmount': totalAmount,
        'customer': customer?.toJson(),
        'status': status,
        'paidAmount': paidAmount,
        'changeAmount': changeAmount,
        'paymentMethod': paymentMethod,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        date: DateTime.parse(json['date']),
        items: List<TransactionItem>.from(
            json['items']?.map((x) => TransactionItem.fromJson(x))),
        totalAmount: json['totalAmount'],
        customer: json['customer'] != null
            ? Customer.fromJson(json['customer'])
            : null,
        status: json['status'],
        paidAmount: json['paidAmount'],
        changeAmount: json['changeAmount'],
        paymentMethod: json['paymentMethod'],
      );
}
