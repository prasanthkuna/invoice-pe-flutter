// InvoicePe Test Helpers - Elon-Style Minimal Code, Maximum Impact
// AI-Assisted utilities for revolutionary testing efficiency

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:invoice_pe_app/main.dart';
import 'package:invoice_pe_app/core/providers/data_providers.dart';
import 'package:invoice_pe_app/core/services/debug_service.dart';

/// Elon's Test Philosophy: "Setup once, test everything"
class TestHelpers {
  static late ProviderContainer _container;

  /// Initialize test environment with mocked dependencies
  static void initializeTestEnvironment() {
    DebugService.initialize();

    // Register fallback values for Mocktail
    registerFallbackValue(Uri.parse('https://test.com'));
    registerFallbackValue(const Duration(seconds: 1));
  }

  /// Create test app with mocked providers
  static Widget createTestApp({
    List<Override> overrides = const [],
    Widget? home,
  }) {
    _container = ProviderContainer(
      overrides: [
        // Mock authentication as true for testing
        isAuthenticatedProvider.overrideWith((ref) => true),
        ...overrides,
      ],
    );

    return UncontrolledProviderScope(
      container: _container,
      child: home ?? const InvoicePeApp(),
    );
  }

  /// Dispose test container
  static void disposeTestContainer() {
    _container.dispose();
  }

  /// Pump and settle with timeout for reliable testing
  static Future<void> pumpAndSettleWithTimeout(
    WidgetTester tester, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Navigate and verify screen
  static Future<void> navigateAndVerify(
    WidgetTester tester, {
    required String buttonText,
    required String expectedScreenText,
  }) async {
    await tester.tap(find.text(buttonText));
    await pumpAndSettleWithTimeout(tester);
    expect(find.text(expectedScreenText), findsOneWidget);
    DebugService.logInfo('✅ Navigation to $expectedScreenText successful');
  }

  /// Wait for loading to complete (supports both WidgetTester and PatrolIntegrationTester)
  static Future<void> waitForLoading(dynamic tester) async {
    // Wait for any CircularProgressIndicator to disappear
    await tester.pumpAndSettle();
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Verify error state
  static void verifyErrorState(String expectedError) {
    expect(find.text(expectedError), findsOneWidget);
    DebugService.logInfo('✅ Error state verified: $expectedError');
  }

  /// Verify success state
  static void verifySuccessState(String expectedSuccess) {
    expect(find.text(expectedSuccess), findsOneWidget);
    DebugService.logInfo('✅ Success state verified: $expectedSuccess');
  }
}

/// Performance monitoring for tests
class TestPerformance {
  static final Stopwatch _stopwatch = Stopwatch();

  static void startTimer(String testName) {
    _stopwatch.reset();
    _stopwatch.start();
    DebugService.logInfo('⏱️ Starting timer for: $testName');
  }

  static void endTimer(String testName, {Duration? maxExpected}) {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsed;

    DebugService.logInfo(
      '⏱️ $testName completed in: ${elapsed.inMilliseconds}ms',
    );

    if (maxExpected != null && elapsed > maxExpected) {
      DebugService.logError(
        'Performance warning: $testName took ${elapsed.inMilliseconds}ms (expected <${maxExpected.inMilliseconds}ms)',
      );
    }
  }
}

/// Security test data for compliance testing
class SecurityTestData {
  /// XSS test payloads for input validation
  static const List<String> xssTestPayloads = [
    '<script>alert("XSS")</script>',
    'javascript:alert("XSS")',
    '<img src="x" onerror="alert(1)">',
    '<svg onload="alert(1)">',
    '"><script>alert("XSS")</script>',
    "'; DROP TABLE users; --",
    '<iframe src="javascript:alert(1)"></iframe>',
  ];

  /// SQL injection test payloads
  static const List<String> sqlInjectionPayloads = [
    "'; DROP TABLE users; --",
    "' OR '1'='1",
    "' UNION SELECT * FROM users --",
    "admin'--",
    "' OR 1=1 --",
  ];

  /// AES test vectors for encryption validation
  static const Map<String, String> aesTestVectors = {
    'plaintext': 'Hello, World! This is a test message for AES encryption.',
    'key': '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    'iv': '0123456789abcdef0123456789abcdef',
  };

  /// Test card data for PCI DSS compliance
  static const Map<String, String> testCardData = {
    'number': '4111111111111111', // Test Visa card
    'expiry': '12/25',
    'cvv': '123',
    'name': 'Test Cardholder',
  };
}

/// Test data generators (AI-assisted patterns)
class TestDataFactory {
  /// Generate realistic test phone number
  static String generateTestPhone() => '+919876543210';

  /// Generate test OTP
  static String generateTestOtp() => '123456';

  /// Generate test vendor data
  static Map<String, dynamic> generateVendorData({
    String? name,
    String? upiId,
  }) => {
    'name': name ?? 'Test Vendor ${DateTime.now().millisecondsSinceEpoch}',
    'upi_id': upiId ?? 'test@paytm',
    'phone': '+919876543210',
    'email': 'test@vendor.com',
    'user_id': 'test-user-id',
  };

  /// Generate test payment data
  static Map<String, dynamic> generatePaymentData({
    double? amount,
    String? vendorId,
  }) => {
    'amount': amount ?? 1000.0,
    'vendor_id': vendorId ?? 'test-vendor-id',
    'description': 'Test payment',
    'fee': (amount ?? 1000.0) * 0.02,
    'rewards': (amount ?? 1000.0) * 0.015,
  };

  /// Generate test transaction data
  static Map<String, dynamic> generateTransactionData({
    String? status,
    double? amount,
  }) => {
    'id': 'test-txn-${DateTime.now().millisecondsSinceEpoch}',
    'amount': amount ?? 1000.0,
    'status': status ?? 'success',
    'created_at': DateTime.now().toIso8601String(),
    'phonepe_transaction_id':
        'PHONEPE_${DateTime.now().millisecondsSinceEpoch}',
  };
}
