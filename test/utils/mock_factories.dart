// InvoicePe Mock Factories - Mocktail Type-Safe Mocking
// InvoicePe's Principle: "Mock external services, test our logic"

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:invoice_pe_app/core/types/result.dart';
import 'package:invoice_pe_app/core/types/auth_types.dart' as auth_types;
import 'package:invoice_pe_app/core/types/payment_types.dart' as payment_types;

/// Mock Supabase Client for testing
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPostgrestClient extends Mock implements PostgrestClient {}

class MockPostgrestQueryBuilder extends Mock
    implements PostgrestQueryBuilder<dynamic> {}

// Use the actual SupabaseQueryBuilder type from supabase_flutter
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockFunctionResponse extends Mock implements FunctionResponse {}

/// Mock PhonePe SDK for payment testing
class MockPhonePePaymentSdk extends Mock {
  static Future<void> init(
    String environment,
    String merchantId,
    String appId,
    bool enableLogging,
  ) async {
    // Mock initialization
  }

  static Future<Map<String, dynamic>?> startTransaction(
    String body,
    String callbackUrl,
    String checksum,
    String? packageName,
  ) async {
    // Return mock successful payment response
    return {
      'status': 'SUCCESS',
      'data': {
        'merchantTransactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
        'transactionId': 'PHONEPE_${DateTime.now().millisecondsSinceEpoch}',
        'amount': 100000, // Amount in paise
        'state': 'COMPLETED',
      },
    };
  }
}

/// Mock Services Factory
class MockServicesFactory {
  /// Create mock PaymentService responses
  static payment_types.PaymentResult createMockPaymentSuccess({
    double amount = 1000.0,
    String? transactionId,
  }) {
    return payment_types.PaymentSuccess(
      transactionId:
          transactionId ?? 'TXN_${DateTime.now().millisecondsSinceEpoch}',
      invoiceId: 'INV_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      rewards: amount * 0.015,
      message: 'Payment completed successfully',
    );
  }

  static payment_types.PaymentResult createMockPaymentFailure({
    String? error,
  }) {
    return payment_types.PaymentFailure(
      error: error ?? 'Payment failed',
      transactionId: 'TXN_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Create mock AuthService responses
  static Result<String> createMockOtpSent({
    String phone = '+919876543210',
  }) {
    return Success('OTP sent to $phone');
  }

  static Result<String> createMockOtpFailed({
    String phone = '+919876543210',
    String? error,
  }) {
    return Failure(error ?? 'OTP sending failed');
  }

  static Result<auth_types.AuthData> createMockVerificationSuccess() {
    return Success(
      auth_types.AuthData(
        user: User(
          id: 'test-user-id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
        session: Session(
          accessToken: 'test-access-token',
          refreshToken: 'test-refresh-token',
          expiresIn: 3600,
          tokenType: 'bearer',
          user: User(
            id: 'test-user-id',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ),
      ),
    );
  }

  /// Create mock EncryptionService responses
  static Result<String> createMockEncryptionSuccess({
    String? encryptedData,
  }) {
    return Success(
      encryptedData ??
          'encrypted_data_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  static Result<String> createMockEncryptionFailure({
    String? error,
  }) {
    return Failure(error ?? 'Encryption failed');
  }

  /// Create mock ValidationService responses
  static Result<String> createMockValidationSuccess(String value) {
    return Success(value);
  }

  static Result<String> createMockValidationFailure({
    String? error,
  }) {
    return Failure(error ?? 'Validation failed');
  }
}

/// Supabase Mock Responses Factory
class SupabaseMockFactory {
  /// Mock successful database response
  static List<Map<String, dynamic>> createMockDatabaseResponse({
    int count = 1,
    Map<String, dynamic>? data,
  }) {
    return List.generate(
      count,
      (index) =>
          data ??
          {
            'id': 'test-id-$index',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
    );
  }

  /// Mock successful function response
  static Map<String, dynamic> createMockFunctionResponse({
    bool success = true,
    Map<String, dynamic>? data,
  }) {
    return {
      'success': success,
      'data': data ?? {'message': 'Function executed successfully'},
      if (!success) 'error': 'Function execution failed',
    };
  }

  /// Mock PhonePe payment initiation response
  static Map<String, dynamic> createMockPaymentInitResponse() {
    return {
      'success': true,
      'body': 'mock_payment_body',
      'callbackUrl': 'https://test.callback.url',
      'checksum': 'mock_checksum',
      'merchantTransactionId': 'TXN_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  /// Mock transaction data
  static Map<String, dynamic> createMockTransactionData({
    String status = 'success',
    double amount = 1000.0,
  }) {
    return {
      'id': 'test-txn-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': 'test-user-id',
      'vendor_id': 'test-vendor-id',
      'invoice_id': 'test-invoice-id',
      'amount': amount,
      'fee': amount * 0.02,
      'rewards_earned': amount * 0.015,
      'status': status,
      'payment_method': 'Credit Card',
      'phonepe_transaction_id':
          'PHONEPE_${DateTime.now().millisecondsSinceEpoch}',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Mock vendor data
  static Map<String, dynamic> createMockVendorData({
    String? name,
  }) {
    return {
      'id': 'test-vendor-${DateTime.now().millisecondsSinceEpoch}',
      'user_id': 'test-user-id',
      'name': name ?? 'Test Vendor',
      'upi_id': 'test@paytm',
      'phone': '+919876543210',
      'email': 'test@vendor.com',
      'created_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Known Answer Test Data for PCI DSS Compliance
class SecurityTestData {
  /// AES-256-GCM test vectors (NIST standard)
  static const Map<String, String> aesTestVectors = {
    'plaintext': 'Test card data for PCI DSS compliance',
    'key': '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f',
    'iv': '000102030405060708090a0b',
    'expectedCiphertext': 'known_encrypted_value_for_testing',
  };

  /// XSS test payloads
  static const List<String> xssTestPayloads = [
    '<script>alert("xss")</script>',
    'javascript:alert("xss")',
    '<img src="x" onerror="alert(1)">',
    '"><script>alert("xss")</script>',
  ];

  /// SQL injection test payloads
  static const List<String> sqlInjectionPayloads = [
    "'; DROP TABLE users; --",
    "1' OR '1'='1",
    "admin'--",
    "1' UNION SELECT * FROM users--",
  ];
}
