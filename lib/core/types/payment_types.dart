import 'result.dart';

/// Payment result types using modern sealed classes
/// Eliminates enum-based error handling and provides compile-time safety

/// Payment processing result
sealed class PaymentResult {
  const PaymentResult();
}

/// Payment completed successfully
final class PaymentSuccess extends PaymentResult {
  final String transactionId;
  final String invoiceId;
  final double amount;
  final double rewards;
  final String message;
  
  const PaymentSuccess({
    required this.transactionId,
    required this.invoiceId,
    required this.amount,
    required this.rewards,
    this.message = 'Payment completed successfully',
  });
  
  @override
  String toString() => 'PaymentSuccess(txnId: $transactionId, amount: $amount, rewards: $rewards)';
}

/// Payment failed
final class PaymentFailure extends PaymentResult {
  final String error;
  final String? transactionId;
  final String? invoiceId;
  
  const PaymentFailure({
    required this.error,
    this.transactionId,
    this.invoiceId,
  });
  
  @override
  String toString() => 'PaymentFailure(error: $error, txnId: $transactionId)';
}

/// Payment cancelled by user
final class PaymentCancelled extends PaymentResult {
  final String? transactionId;
  final String? reason;
  
  const PaymentCancelled({
    this.transactionId,
    this.reason = 'Payment cancelled by user',
  });
  
  @override
  String toString() => 'PaymentCancelled(reason: $reason, txnId: $transactionId)';
}

/// Payment is processing
final class PaymentProcessing extends PaymentResult {
  final String transactionId;
  final String message;
  
  const PaymentProcessing({
    required this.transactionId,
    this.message = 'Payment is being processed',
  });
  
  @override
  String toString() => 'PaymentProcessing(txnId: $transactionId, message: $message)';
}

/// Payment initiation data
class PaymentInitData {
  final String body;
  final String callbackUrl;
  final String checksum;
  final String merchantTransactionId;
  final String invoiceId;
  final double amount;
  
  const PaymentInitData({
    required this.body,
    required this.callbackUrl,
    required this.checksum,
    required this.merchantTransactionId,
    required this.invoiceId,
    required this.amount,
  });
  
  @override
  String toString() => 'PaymentInitData(txnId: $merchantTransactionId, amount: $amount)';
}

/// Payment initiation result
typedef PaymentInitResult = Result<PaymentInitData>;

/// Convenience extensions for PaymentResult
extension PaymentResultExtensions on PaymentResult {
  /// Check if payment was successful
  bool get isSuccess => this is PaymentSuccess;
  
  /// Check if payment failed
  bool get isFailure => this is PaymentFailure;
  
  /// Check if payment was cancelled
  bool get isCancelled => this is PaymentCancelled;
  
  /// Check if payment is processing
  bool get isProcessing => this is PaymentProcessing;
  
  /// Get transaction ID if available
  String? get transactionId => switch (this) {
    PaymentSuccess(transactionId: final id) => id,
    PaymentFailure(transactionId: final id) => id,
    PaymentCancelled(transactionId: final id) => id,
    PaymentProcessing(transactionId: final id) => id,
  };
  
  /// Get user-friendly message
  String get message => switch (this) {
    PaymentSuccess(message: final msg) => msg,
    PaymentFailure(error: final error) => error,
    PaymentCancelled(reason: final reason) => reason ?? 'Payment cancelled',
    PaymentProcessing(message: final msg) => msg,
  };
  
  /// Get amount if successful
  double? get amount => switch (this) {
    PaymentSuccess(amount: final amount) => amount,
    _ => null,
  };
  
  /// Get rewards if successful
  double? get rewards => switch (this) {
    PaymentSuccess(rewards: final rewards) => rewards,
    _ => null,
  };
}

/// PhonePe response handling
class PhonePeResponse {
  final String status;
  final String? code;
  final String? message;
  final Map<String, dynamic>? data;
  
  const PhonePeResponse({
    required this.status,
    this.code,
    this.message,
    this.data,
  });
  
  factory PhonePeResponse.fromMap(Map<String, dynamic> map) {
    return PhonePeResponse(
      status: map['status']?.toString() ?? 'UNKNOWN',
      code: map['code']?.toString(),
      message: map['message']?.toString(),
      data: map['data'] as Map<String, dynamic>?,
    );
  }
  
  /// Check if response indicates success
  bool get isSuccess => status == 'SUCCESS' || code == 'PAYMENT_SUCCESS';
  
  /// Check if response indicates failure
  bool get isFailure => status == 'FAILURE' || status == 'FAILED';
  
  /// Check if response indicates cancellation
  bool get isCancelled => status == 'CANCELLED' || code == 'PAYMENT_CANCELLED';
  
  @override
  String toString() => 'PhonePeResponse(status: $status, code: $code, message: $message)';
}

/// Payment fee calculation
class PaymentFeeCalculator {
  static const double defaultFeePercentage = 0.02; // 2%
  static const double defaultRewardsPercentage = 0.015; // 1.5%
  
  /// Calculate payment fee
  static double calculateFee(double amount, {double? feePercentage}) {
    final rate = feePercentage ?? defaultFeePercentage;
    return (amount * rate * 100).round() / 100; // Round to 2 decimal places
  }
  
  /// Calculate rewards
  static double calculateRewards(double amount, {double? rewardsPercentage}) {
    final rate = rewardsPercentage ?? defaultRewardsPercentage;
    return (amount * rate * 100).round() / 100; // Round to 2 decimal places
  }
  
  /// Calculate net amount after fee
  static double calculateNetAmount(double amount, {double? feePercentage}) {
    final fee = calculateFee(amount, feePercentage: feePercentage);
    return amount - fee;
  }
  
  /// Calculate total amount including fee
  static double calculateTotalAmount(double amount, {double? feePercentage}) {
    final fee = calculateFee(amount, feePercentage: feePercentage);
    return amount + fee;
  }
}
