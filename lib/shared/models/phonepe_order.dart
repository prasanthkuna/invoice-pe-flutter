import 'package:dart_mappable/dart_mappable.dart';

part 'phonepe_order.mapper.dart';

@MappableEnum()
enum PhonePeOrderStatus {
  created, // Order created
  pending, // Payment in progress
  success, // Payment successful
  failure, // Payment failed
  cancelled, // Payment cancelled
  expired, // Payment expired
}

@MappableClass()
class PhonePeOrder with PhonePeOrderMappable {
  const PhonePeOrder({
    required this.orderId,
    required this.merchantOrderId,
    required this.token,
    required this.amount,
    required this.status,
    this.merchantUserId,
    this.createdAt,
    this.expiresAt,
    this.paymentMethod,
    this.errorCode,
    this.errorMessage,
  });

  final String orderId; // PhonePe Order ID (OMO123456789)
  final String merchantOrderId; // Our internal order ID
  final String token; // Order token for SDK
  final int amount; // Amount in paise
  final PhonePeOrderStatus status; // Order status
  final String? merchantUserId; // User identifier
  final DateTime? createdAt; // Order creation time
  final DateTime? expiresAt; // Order expiration time
  final String? paymentMethod; // Payment method used
  final String? errorCode; // Error code if failed
  final String? errorMessage; // Error message if failed

  /// Get amount in rupees
  double get amountInRupees => amount / 100.0;

  /// Check if order is expired
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Check if order is successful
  bool get isSuccessful => status == PhonePeOrderStatus.success;

  /// Check if order is pending
  bool get isPending => status == PhonePeOrderStatus.pending;

  /// Check if order has failed
  bool get hasFailed => status == PhonePeOrderStatus.failure;

  static const PhonePeOrder Function(Map<String, dynamic> map) fromMap =
      PhonePeOrderMapper.fromMap;
  static const PhonePeOrder Function(String json) fromJson =
      PhonePeOrderMapper.fromJson;
}
