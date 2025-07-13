import 'package:dart_mappable/dart_mappable.dart';

part 'transaction.mapper.dart';

@MappableEnum()
enum TransactionStatus { initiated, success, failure }

@MappableClass()
class Transaction with TransactionMappable {
  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.fee,
    required this.rewardsEarned,
    required this.status,
    this.vendorId,
    this.vendorName,
    this.invoiceId,
    this.paymentMethod,
    this.phonepeTransactionId,
    this.failureReason,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String? vendorId;
  final String? vendorName;
  final double amount;
  final double fee;
  final double rewardsEarned;
  final TransactionStatus status;
  final String? invoiceId;
  final String? paymentMethod;
  final String? phonepeTransactionId;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? completedAt;

  static Transaction fromMap(Map<String, dynamic> map) =>
      TransactionMapper.fromMap(map);
  static Transaction fromJson(String json) => TransactionMapper.fromJson(json);
}
