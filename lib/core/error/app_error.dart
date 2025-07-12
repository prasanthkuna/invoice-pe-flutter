// InvoicePe - Comprehensive Error Handling System
// Provides user-friendly error messages and proper exception handling

import 'dart:async';
import 'package:dart_mappable/dart_mappable.dart';

part 'app_error.mapper.dart';

/// Base class for all application errors
@MappableClass()
abstract class AppError with AppErrorMappable {
  const AppError({
    required this.message,
    required this.code,
    this.details,
    this.stackTrace,
  });

  /// User-friendly error message
  final String message;
  
  /// Error code for programmatic handling
  final String code;
  
  /// Additional error details for debugging
  final Map<String, dynamic>? details;
  
  /// Stack trace for debugging
  final String? stackTrace;

  /// Convert to user-friendly display message
  String get displayMessage => message;
  
  /// Check if error should be reported to crash analytics
  bool get shouldReport => true;
}

/// Authentication related errors
@MappableClass()
class AuthError extends AppError with AuthErrorMappable {
  const AuthError({
    required super.message,
    required super.code,
    super.details,
    super.stackTrace,
  });

  factory AuthError.invalidCredentials() => const AuthError(
    message: 'Invalid phone number or OTP. Please try again.',
    code: 'AUTH_INVALID_CREDENTIALS',
  );

  factory AuthError.sessionExpired() => const AuthError(
    message: 'Your session has expired. Please login again.',
    code: 'AUTH_SESSION_EXPIRED',
  );

  factory AuthError.otpExpired() => const AuthError(
    message: 'OTP has expired. Please request a new one.',
    code: 'AUTH_OTP_EXPIRED',
  );

  factory AuthError.tooManyAttempts() => const AuthError(
    message: 'Too many failed attempts. Please try again later.',
    code: 'AUTH_TOO_MANY_ATTEMPTS',
  );
}

/// Network and API related errors
@MappableClass()
class NetworkError extends AppError with NetworkErrorMappable {
  const NetworkError({
    required super.message,
    required super.code,
    super.details,
    super.stackTrace,
  });

  factory NetworkError.noConnection() => const NetworkError(
    message: 'No internet connection. Please check your network and try again.',
    code: 'NETWORK_NO_CONNECTION',
  );

  factory NetworkError.timeout() => const NetworkError(
    message: 'Request timed out. Please try again.',
    code: 'NETWORK_TIMEOUT',
  );

  factory NetworkError.serverError() => const NetworkError(
    message: 'Server error occurred. Please try again later.',
    code: 'NETWORK_SERVER_ERROR',
  );
}

/// Payment related errors
@MappableClass()
class PaymentError extends AppError with PaymentErrorMappable {
  const PaymentError({
    required super.message,
    required super.code,
    super.details,
    super.stackTrace,
  });

  factory PaymentError.insufficientFunds() => const PaymentError(
    message: 'Insufficient funds in your account.',
    code: 'PAYMENT_INSUFFICIENT_FUNDS',
  );

  factory PaymentError.cardDeclined() => const PaymentError(
    message: 'Your card was declined. Please try a different card.',
    code: 'PAYMENT_CARD_DECLINED',
  );

  factory PaymentError.processingFailed() => const PaymentError(
    message: 'Payment processing failed. Please try again.',
    code: 'PAYMENT_PROCESSING_FAILED',
  );
}

/// Data validation errors
@MappableClass()
class ValidationError extends AppError with ValidationErrorMappable {
  const ValidationError({
    required super.message,
    required super.code,
    super.details,
    super.stackTrace,
  });

  factory ValidationError.invalidInput(String field) => ValidationError(
    message: 'Invalid $field. Please check and try again.',
    code: 'VALIDATION_INVALID_INPUT',
    details: {'field': field},
  );

  factory ValidationError.requiredField(String field) => ValidationError(
    message: '$field is required.',
    code: 'VALIDATION_REQUIRED_FIELD',
    details: {'field': field},
  );
}

/// Unknown or unexpected errors
@MappableClass()
class UnknownError extends AppError with UnknownErrorMappable {
  const UnknownError({
    required super.message,
    required super.code,
    super.details,
    super.stackTrace,
  });

  factory UnknownError.generic() => const UnknownError(
    message: 'An unexpected error occurred. Please try again.',
    code: 'UNKNOWN_ERROR',
  );
}

/// Utility class for error handling
class ErrorHandler {
  /// Convert any exception to AppError
  static AppError fromException(dynamic exception, [StackTrace? stackTrace]) {
    final stackTraceString = stackTrace?.toString();
    
    if (exception is AppError) {
      return exception;
    }
    
    // Handle common exception types
    if (exception is FormatException) {
      return ValidationError(
        message: 'Invalid data format: ${exception.message}',
        code: 'VALIDATION_FORMAT_ERROR',
        stackTrace: stackTraceString,
      );
    }
    
    if (exception is TimeoutException) {
      return NetworkError.timeout();
    }
    
    // Default to unknown error
    return UnknownError(
      message: exception.toString(),
      code: 'UNKNOWN_ERROR',
      stackTrace: stackTraceString,
    );
  }
  
  /// Get user-friendly message from any error
  static String getUserMessage(dynamic error) {
    if (error is AppError) {
      return error.displayMessage;
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
