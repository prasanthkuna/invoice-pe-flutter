import 'package:dart_mappable/dart_mappable.dart';

part 'payment_result.mapper.dart';

@MappableClass()
class PaymentResult with PaymentResultMappable {
  const PaymentResult({
    required this.transactionId,
    required this.vendorId,
    required this.vendorName,
    required this.amount,
    required this.fee,
    required this.rewards,
    required this.total,
    required this.paymentMethod,
    required this.timestamp,
    this.phonepeTransactionId,
  });
  final String transactionId;
  final String vendorId;
  final String vendorName;
  final double amount;
  final double fee;
  final double rewards;
  final double total;
  final String paymentMethod;
  final DateTime timestamp;
  final String? phonepeTransactionId;

  static PaymentResult fromMap(Map<String, dynamic> map) =>
      PaymentResultMapper.fromMap(map);
  static PaymentResult fromJson(String json) =>
      PaymentResultMapper.fromJson(json);
}
