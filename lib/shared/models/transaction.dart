import 'package:dart_mappable/dart_mappable.dart';

part 'transaction.mapper.dart';

@MappableEnum()
enum TransactionStatus {
  initiated,    // Payment initiated
  pending,      // Payment in progress
  success,      // Payment completed successfully
  failure,      // Payment failed
  cancelled,    // Payment cancelled by user
  expired       // Payment expired/timed out
}

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

    // NEW: PhonePe SDK 3.0.0 fields
    this.phonepeOrderId,
    this.phonepeOrderToken,
    this.phonepeOrderStatus,
    this.phonepeMerchantOrderId,
    this.phonepeErrorDetails,
    this.phonepeResponseData,
    this.webhookReceivedAt,
    this.webhookVerified,
    this.webhookData,
    this.lastStatusCheckAt,
    this.statusCheckCount,
    this.autoPollingEnabled = true,
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

  // NEW: PhonePe SDK 3.0.0 fields
  final String? phonepeOrderId;           // PhonePe Order ID (OMO123456789)
  final String? phonepeOrderToken;        // Order Token for SDK
  final String? phonepeOrderStatus;       // Order Status (separate from transaction)
  final String? phonepeMerchantOrderId;   // Our internal order reference
  final Map<String, dynamic>? phonepeErrorDetails;  // Detailed error codes/messages
  final Map<String, dynamic>? phonepeResponseData;  // Complete PhonePe response
  final DateTime? webhookReceivedAt;      // Webhook timestamp
  final bool? webhookVerified;            // Webhook signature verified
  final Map<String, dynamic>? webhookData; // Webhook payload
  final DateTime? lastStatusCheckAt;      // Last polling timestamp
  final int? statusCheckCount;            // Polling retry count
  final bool autoPollingEnabled;          // Enable/disable polling

  static Transaction fromMap(Map<String, dynamic> map) =>
      TransactionMapper.fromMap(map);
  static Transaction fromJson(String json) => TransactionMapper.fromJson(json);
}
