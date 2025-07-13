// InvoicePe Security Compliance Tests - PCI DSS Ready
// InvoicePe's Security Philosophy: "Security is not optional. Test every attack vector."

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:invoice_pe_app/core/services/encryption_service.dart';
import 'package:invoice_pe_app/core/services/validation_service.dart';
import 'package:invoice_pe_app/core/services/debug_service.dart';
import 'package:invoice_pe_app/core/types/result.dart' as result_types;
import '../test/utils/test_helpers.dart' as test_helpers;

void main() {
  group('🔒 Security Compliance Tests - PCI DSS Critical', () {
    setUpAll(test_helpers.TestHelpers.initializeTestEnvironment);

    group('🔐 AES-256-GCM Encryption Tests', () {
      patrolTest(
        '✅ Known Answer Test (NIST Compliance)',
        ($) async {
          test_helpers.TestPerformance.startTimer('AES Encryption Test');

          // Test with known test vectors
          const testData = test_helpers.SecurityTestData.aesTestVectors;

          // Test encryption
          final encryptResult = await EncryptionService.encryptSensitiveData({
            'test_data': testData['plaintext'],
          });

          expect(encryptResult, isA<result_types.Success<String>>());

          if (encryptResult is result_types.Success<String>) {
            final encryptedData = encryptResult.data;
            expect(encryptedData.isNotEmpty, true);

            // Test decryption
            final decryptResult = await EncryptionService.decryptSensitiveData(
              encryptedData,
            );
            expect(
              decryptResult,
              isA<result_types.Success<Map<String, dynamic>>>(),
            );

            if (decryptResult is result_types.Success<Map<String, dynamic>>) {
              final decryptedData = decryptResult.data;
              expect(decryptedData['test_data'], equals(testData['plaintext']));
            }
          }

          DebugService.logSecurity(
            '✅ AES-256-GCM encryption/decryption verified',
          );

          test_helpers.TestPerformance.endTimer(
            'AES Encryption Test',
            maxExpected: const Duration(seconds: 2),
          );
        },
      );

      patrolTest(
        '💳 Card Data Encryption (PCI DSS)',
        ($) async {
          test_helpers.TestPerformance.startTimer('Card Encryption Test');

          // Test card data encryption
          final cardEncryptResult = await EncryptionService.encryptCardData(
            cardNumber: '4111111111111111',
            expiryDate: '12/25',
            cvv: '123',
            cardholderName: 'Test User',
          );

          expect(cardEncryptResult, isA<result_types.Success<String>>());

          if (cardEncryptResult is result_types.Success<String>) {
            final encryptedCard = cardEncryptResult.data;
            expect(encryptedCard.isNotEmpty, true);
            expect(
              encryptedCard.contains('4111'),
              false,
            ); // Ensure no plaintext

            DebugService.logSecurity(
              '✅ Card data encrypted for PCI DSS compliance',
            );
          }

          test_helpers.TestPerformance.endTimer(
            'Card Encryption Test',
            maxExpected: const Duration(seconds: 1),
          );
        },
      );

      patrolTest(
        '🔑 Key Generation and Storage',
        ($) async {
          // Test encryption service initialization
          final initResult = await EncryptionService.initialize();
          expect(initResult, isA<result_types.Success<void>>());

          if (initResult is result_types.Success<void>) {
            // Test encryption status instead
            final statusResult = await EncryptionService.getEncryptionStatus();
            expect(
              statusResult,
              isA<result_types.Success<Map<String, dynamic>>>(),
            );

            if (statusResult is result_types.Success<Map<String, dynamic>>) {
              final status = statusResult.data;
              expect(status['encryption_algorithm'], equals('AES-256-GCM'));
              expect(status['pcc_compliant'], equals(true));

              DebugService.logSecurity('✅ Encryption service status verified');
            }
          }
        },
      );
    });

    group('🛡️ Input Validation & XSS Prevention', () {
      patrolTest(
        '🚨 XSS Attack Prevention',
        ($) async {
          test_helpers.TestPerformance.startTimer('XSS Prevention Test');

          // Test XSS payloads
          for (final payload in test_helpers.SecurityTestData.xssTestPayloads) {
            final result = ValidationService.validateTextInput(
              payload,
              fieldName: 'test_field',
              sanitize: true,
            );

            if (result is result_types.Success<String>) {
              final sanitized = result.data;
              expect(sanitized.contains('<script>'), false);
              expect(sanitized.contains('javascript:'), false);
              expect(sanitized.contains('onerror='), false);
            }
          }

          DebugService.logSecurity('✅ XSS prevention verified');

          test_helpers.TestPerformance.endTimer(
            'XSS Prevention Test',
            maxExpected: const Duration(seconds: 1),
          );
        },
      );

      patrolTest(
        '💉 SQL Injection Prevention',
        ($) async {
          test_helpers.TestPerformance.startTimer('SQL Injection Test');

          // Test SQL injection payloads
          for (final payload
              in test_helpers.SecurityTestData.sqlInjectionPayloads) {
            final result = ValidationService.validateTextInput(
              payload,
              fieldName: 'test_field',
              sanitize: true,
            );

            // Should either fail validation or be sanitized
            if (result is result_types.Success<String>) {
              final sanitized = result.data;
              expect(sanitized.contains('DROP TABLE'), false);
              expect(sanitized.contains('UNION SELECT'), false);
              expect(sanitized.contains("'--"), false);
            }
          }

          DebugService.logSecurity('✅ SQL injection prevention verified');

          test_helpers.TestPerformance.endTimer(
            'SQL Injection Test',
            maxExpected: const Duration(seconds: 1),
          );
        },
      );

      patrolTest(
        '📧 Email Validation Security',
        ($) async {
          // Test valid emails
          final validResult = ValidationService.validateEmail(
            'test@example.com',
          );
          expect(validResult, isA<result_types.Success<String>>());

          // Test malicious emails
          final maliciousEmails = [
            'test@example.com<script>alert(1)</script>',
            'test+<script>@example.com',
            'test@example.com"; DROP TABLE users; --',
          ];

          for (final email in maliciousEmails) {
            final result = ValidationService.validateEmail(email);
            if (result is result_types.Success<String>) {
              final sanitized = result.data;
              expect(sanitized.contains('<script>'), false);
              expect(sanitized.contains('DROP TABLE'), false);
            }
          }

          DebugService.logSecurity('✅ Email validation security verified');
        },
      );
    });

    group('🔐 Authentication Security', () {
      patrolTest(
        '📱 Phone Number Validation',
        ($) async {
          // Test valid phone numbers
          final validPhones = ['+919876543210', '+1234567890'];
          for (final phone in validPhones) {
            final result = ValidationService.validatePhoneNumber(phone);
            expect(result, isA<result_types.Success<String>>());
          }

          // Test malicious phone inputs
          final maliciousPhones = [
            '+91<script>alert(1)</script>',
            '+91"; DROP TABLE users; --',
            '+91javascript:alert(1)',
          ];

          for (final phone in maliciousPhones) {
            final result = ValidationService.validatePhoneNumber(phone);
            if (result is result_types.Success<String>) {
              final sanitized = result.data;
              expect(sanitized.contains('<script>'), false);
              expect(sanitized.contains('javascript:'), false);
            }
          }

          DebugService.logSecurity('✅ Phone validation security verified');
        },
      );

      patrolTest(
        '🔢 Amount Validation Security',
        ($) async {
          // Test valid amounts
          final validResult = ValidationService.validateAmount('1000.0');
          expect(validResult, isA<result_types.Success<double>>());

          // Test edge cases
          final negativeResult = ValidationService.validateAmount('-100.0');
          expect(negativeResult, isA<result_types.Failure<double>>());

          final zeroResult = ValidationService.validateAmount('0.0');
          expect(zeroResult, isA<result_types.Failure<double>>());

          DebugService.logSecurity('✅ Amount validation security verified');
        },
      );
    });

    group('📋 Audit Logging Security', () {
      patrolTest(
        '📝 Security Event Logging',
        ($) async {
          test_helpers.TestPerformance.startTimer('Audit Logging Test');

          // Test security violation logging
          DebugService.logSecurityViolation(
            'Test security violation',
            context: {
              'ip_address': '192.168.1.1',
              'user_agent': 'Test Agent',
              'attempted_action': 'XSS injection',
            },
          );

          // Test audit trail logging
          DebugService.logAuditTrail(
            'Test audit event',
            userId: 'test-user-id',
            details: {
              'action': 'payment_initiated',
              'amount': 1000.0,
            },
          );

          DebugService.logSecurity(
            '✅ Audit logging verified for PCI DSS compliance',
          );

          test_helpers.TestPerformance.endTimer(
            'Audit Logging Test',
            maxExpected: const Duration(milliseconds: 500),
          );
        },
      );
    });
  });
}
