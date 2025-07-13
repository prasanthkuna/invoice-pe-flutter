// InvoicePe ValidationService Tests - Security Critical
// XSS/SQL injection prevention and input validation

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pe_app/core/services/validation_service.dart';
import 'package:invoice_pe_app/core/services/debug_service.dart';
import 'package:invoice_pe_app/core/types/result.dart';
import '../utils/test_helpers.dart' as test_helpers;

void main() {
  group('🛡️ ValidationService Tests - Security Critical', () {
    setUpAll(() {
      test_helpers.TestHelpers.initializeTestEnvironment();
      DebugService.initialize();
    });

    group('XSS Prevention', () {
      test('🚨 Block XSS script tags', () {
        test_helpers.TestPerformance.startTimer('XSS Prevention');

        for (final payload in test_helpers.SecurityTestData.xssTestPayloads) {
          final result = ValidationService.validateTextInput(
            payload,
            fieldName: 'test_field',
            sanitize: true,
          );

          if (result is Success<String>) {
            final sanitized = result.data;
            expect(sanitized.contains('<script>'), false);
            expect(sanitized.contains('javascript:'), false);
            expect(sanitized.contains('onerror='), false);
            expect(sanitized.contains('alert('), false);
          } else if (result is Failure<String>) {
            // Validation rejection is also acceptable
            expect(result.error.isNotEmpty, true);
          }
        }

        DebugService.logSecurity('✅ XSS prevention verified');

        test_helpers.TestPerformance.endTimer(
          'XSS Prevention',
          maxExpected: const Duration(milliseconds: 100),
        );
      });

      test('✅ Allow safe text input', () {
        final safeInputs = [
          'John Doe',
          'Test Vendor Ltd.',
          'Payment for services',
          'user@example.com',
          '+919876543210',
        ];

        for (final input in safeInputs) {
          final result = ValidationService.validateTextInput(
            input,
            fieldName: 'test_field',
            sanitize: true,
          );

          expect(result, isA<Success<String>>());

          if (result is Success<String>) {
            expect(result.data, equals(input));
          }
        }
      });
    });

    group('SQL Injection Prevention', () {
      test('💉 Block SQL injection attempts', () {
        test_helpers.TestPerformance.startTimer('SQL Injection Prevention');

        for (final payload
            in test_helpers.SecurityTestData.sqlInjectionPayloads) {
          final result = ValidationService.validateTextInput(
            payload,
            fieldName: 'test_field',
            sanitize: true,
          );

          if (result is Success<String>) {
            final sanitized = result.data;
            expect(sanitized.contains('DROP TABLE'), false);
            expect(sanitized.contains('UNION SELECT'), false);
            expect(sanitized.contains("'--"), false);
            expect(sanitized.contains('OR 1=1'), false);
          } else if (result is Failure<String>) {
            // Validation rejection is also acceptable
            expect(result.error.isNotEmpty, true);
          }
        }

        DebugService.logSecurity('✅ SQL injection prevention verified');

        test_helpers.TestPerformance.endTimer(
          'SQL Injection Prevention',
          maxExpected: const Duration(milliseconds: 100),
        );
      });
    });

    group('Email Validation', () {
      test('✅ Validate correct email formats', () {
        final validEmails = [
          'user@example.com',
          'test.email@domain.co.in',
          'user+tag@example.org',
          'firstname.lastname@company.com',
        ];

        for (final email in validEmails) {
          final result = ValidationService.validateEmail(email);
          expect(result, isA<Success<String>>());

          if (result is Success<String>) {
            expect(result.data, equals(email));
          }
        }
      });

      test('❌ Reject invalid email formats', () {
        final invalidEmails = [
          'invalid-email',
          '@domain.com',
          'user@',
          'user..double.dot@domain.com',
          'user@domain',
        ];

        for (final email in invalidEmails) {
          final result = ValidationService.validateEmail(email);
          expect(result, isA<Failure<String>>());
        }
      });

      test('🛡️ Sanitize malicious email inputs', () {
        final maliciousEmails = [
          'test@example.com<script>alert(1)</script>',
          'test+<script>@example.com',
          'test@example.com"; DROP TABLE users; --',
        ];

        for (final email in maliciousEmails) {
          final result = ValidationService.validateEmail(email);

          if (result is Success<String>) {
            final sanitized = result.data;
            expect(sanitized.contains('<script>'), false);
            expect(sanitized.contains('DROP TABLE'), false);
          }
        }
      });
    });

    group('Phone Number Validation', () {
      test('✅ Validate correct phone formats', () {
        final validPhones = [
          '+919876543210',
          '+1234567890',
          '+447700900123',
          '+33123456789',
        ];

        for (final phone in validPhones) {
          final result = ValidationService.validatePhoneNumber(phone);
          expect(result, isA<Success<String>>());

          if (result is Success<String>) {
            expect(result.data, equals(phone));
          }
        }
      });

      test('❌ Reject invalid phone formats', () {
        final invalidPhones = [
          '9876543210', // Missing country code
          '+91987654321', // Too short
          '+919876543210123', // Too long
          'invalid-phone', // Non-numeric
          '+91-987-654-3210', // With dashes
        ];

        for (final phone in invalidPhones) {
          final result = ValidationService.validatePhoneNumber(phone);
          expect(result, isA<Failure<String>>());
        }
      });

      test('🛡️ Sanitize malicious phone inputs', () {
        final maliciousPhones = [
          '+91<script>alert(1)</script>',
          '+91"; DROP TABLE users; --',
          '+91javascript:alert(1)',
        ];

        for (final phone in maliciousPhones) {
          final result = ValidationService.validatePhoneNumber(phone);

          if (result is Success<String>) {
            final sanitized = result.data;
            expect(sanitized.contains('<script>'), false);
            expect(sanitized.contains('javascript:'), false);
            expect(sanitized.contains('DROP TABLE'), false);
          }
        }
      });
    });

    group('Amount Validation', () {
      test('✅ Validate correct amounts', () {
        final validAmounts = ['1.0', '100.0', '1000.0', '50000.0'];
        final expectedValues = [1.0, 100.0, 1000.0, 50000.0];

        for (var i = 0; i < validAmounts.length; i++) {
          final result = ValidationService.validateAmount(validAmounts[i]);
          expect(result, isA<Success<double>>());

          if (result is Success<double>) {
            expect(result.data, equals(expectedValues[i]));
          }
        }
      });

      test('❌ Reject invalid amounts', () {
        final invalidAmounts = ['-100.0', '0.0', '0.5', '1000000.0'];

        for (final amount in invalidAmounts) {
          final result = ValidationService.validateAmount(amount);
          expect(result, isA<Failure<double>>());
        }
      });

      test('💰 Validate amount ranges', () {
        // Test minimum amount
        final minResult = ValidationService.validateAmount('0.99');
        expect(minResult, isA<Failure<double>>());

        // Test maximum amount
        final maxResult = ValidationService.validateAmount('100001.0');
        expect(maxResult, isA<Failure<double>>());

        // Test valid range
        final validResult = ValidationService.validateAmount('5000.0');
        expect(validResult, isA<Success<double>>());
      });
    });

    group('UPI ID Validation', () {
      test('✅ Validate correct UPI formats', () {
        final validUpiIds = [
          'user@paytm',
          'test@phonepe',
          'merchant@googlepay',
          'user123@okaxis',
        ];

        for (final upiId in validUpiIds) {
          final result = ValidationService.validateUpiId(upiId);
          expect(result, isA<Success<String>>());

          if (result is Success<String>) {
            expect(result.data, equals(upiId));
          }
        }
      });

      test('❌ Reject invalid UPI formats', () {
        final invalidUpiIds = [
          'invalid-upi',
          '@paytm',
          'user@',
          'user@invalid-provider',
        ];

        for (final upiId in invalidUpiIds) {
          final result = ValidationService.validateUpiId(upiId);
          expect(result, isA<Failure<String>>());
        }
      });
    });

    group('Performance Tests', () {
      test('⚡ Validation performance within limits', () {
        test_helpers.TestPerformance.startTimer('Validation Performance');

        final stopwatch = Stopwatch()..start();

        // Perform 1000 validations
        for (var i = 0; i < 1000; i++) {
          ValidationService.validateEmail('test@example.com');
          ValidationService.validatePhoneNumber('+919876543210');
          ValidationService.validateAmount('1000.0');
          ValidationService.validateUpiId('test@paytm');
        }

        stopwatch.stop();

        // Should complete in under 100ms
        expect(stopwatch.elapsedMilliseconds, lessThan(100));

        test_helpers.TestPerformance.endTimer(
          'Validation Performance',
          maxExpected: const Duration(milliseconds: 100),
        );
      });
    });

    group('Edge Cases', () {
      test('🔍 Handle empty and null inputs', () {
        // Test empty string
        final emptyResult = ValidationService.validateTextInput(
          '',
          fieldName: 'test_field',
        );
        expect(emptyResult, isA<Failure<String>>());

        // Test whitespace only
        final whitespaceResult = ValidationService.validateTextInput(
          '   ',
          fieldName: 'test_field',
        );
        expect(whitespaceResult, isA<Failure<String>>());
      });

      test('📏 Handle length limits', () {
        // Test very long input
        final longInput = 'x' * 1000;
        final result = ValidationService.validateTextInput(
          longInput,
          fieldName: 'test_field',
          maxLength: 100,
        );
        expect(result, isA<Failure<String>>());
      });
    });
  });
}
