// InvoicePe Encryption Service Tests - PCI DSS Compliance
// Mocktail-powered unit tests for cryptographic functions

import 'package:flutter_test/flutter_test.dart';
import 'package:invoice_pe_app/core/services/encryption_service.dart';
import 'package:invoice_pe_app/core/services/debug_service.dart';
import 'package:invoice_pe_app/core/types/result.dart';
import '../utils/test_helpers.dart';

void main() {
  group('🔐 EncryptionService Tests - PCI DSS Critical', () {
    setUpAll(() {
      TestHelpers.initializeTestEnvironment();
      DebugService.initialize();
    });

    group('AES-256-GCM Encryption', () {
      test('✅ Encrypt and decrypt sensitive data successfully', () async {
        TestPerformance.startTimer('AES Encryption/Decryption');

        final testData = {
          'card_number': '4111111111111111',
          'expiry': '12/25',
          'cvv': '123',
        };

        // Test encryption
        final encryptResult = await EncryptionService.encryptSensitiveData(
          testData,
        );
        expect(encryptResult, isA<Success<String>>());

        if (encryptResult is Success<String>) {
          final encryptedData = encryptResult.data;

          // Verify encrypted data properties
          expect(encryptedData.isNotEmpty, true);
          expect(encryptedData.contains('4111'), false); // No plaintext
          expect(encryptedData.length, greaterThan(50)); // Reasonable length

          // Test decryption
          final decryptResult = await EncryptionService.decryptSensitiveData(
            encryptedData,
          );
          expect(decryptResult, isA<Success<Map<String, dynamic>>>());

          if (decryptResult is Success<Map<String, dynamic>>) {
            final decryptedData = decryptResult.data;
            expect(
              decryptedData['card_number'],
              equals(testData['card_number']),
            );
            expect(decryptedData['expiry'], equals(testData['expiry']));
            expect(decryptedData['cvv'], equals(testData['cvv']));
          }
        }

        TestPerformance.endTimer(
          'AES Encryption/Decryption',
          maxExpected: const Duration(seconds: 1),
        );
      });

      test('❌ Handle encryption failure gracefully', () async {
        // Test with invalid data
        final result = await EncryptionService.encryptSensitiveData({});
        expect(result, isA<Failure<String>>());

        if (result is Failure<String>) {
          expect(result.error.isNotEmpty, true);
        }
      });

      test('❌ Handle decryption failure gracefully', () async {
        // Test with invalid encrypted data
        const invalidData = 'invalid_encrypted_data';
        final result = await EncryptionService.decryptSensitiveData(
          invalidData,
        );
        expect(result, isA<Failure<Map<String, dynamic>>>());
      });
    });

    group('Card Data Encryption', () {
      test('💳 Encrypt card data for PCI DSS compliance', () async {
        TestPerformance.startTimer('Card Data Encryption');

        final result = await EncryptionService.encryptCardData(
          cardNumber: '4111111111111111',
          expiryDate: '12/25',
          cvv: '123',
          cardholderName: 'John Doe',
        );

        expect(result, isA<Success<String>>());

        if (result is Success<String>) {
          final encryptedCard = result.data;
          expect(encryptedCard.isNotEmpty, true);
          expect(encryptedCard.contains('4111'), false);
          expect(encryptedCard.contains('123'), false);
          expect(encryptedCard.contains('John'), false);
        }

        TestPerformance.endTimer(
          'Card Data Encryption',
          maxExpected: const Duration(milliseconds: 500),
        );
      });

      test('❌ Reject invalid card data', () async {
        // Test with empty card number
        final result = await EncryptionService.encryptCardData(
          cardNumber: '',
          expiryDate: '12/25',
          cvv: '123',
        );

        expect(result, isA<Failure<String>>());
      });
    });

    group('Key Management', () {
      test('🔑 Encryption service initialization', () async {
        TestPerformance.startTimer('Service Initialization');

        final result = await EncryptionService.initialize();
        expect(result, isA<Success<void>>());

        TestPerformance.endTimer(
          'Service Initialization',
          maxExpected: const Duration(milliseconds: 100),
        );
      });

      test('🔑 Encryption status check', () async {
        final result = await EncryptionService.getEncryptionStatus();
        expect(result, isA<Success<Map<String, dynamic>>>());

        if (result is Success<Map<String, dynamic>>) {
          final status = result.data;
          expect(status['encryption_algorithm'], equals('AES-256-GCM'));
          expect(status['key_storage'], equals('Secure Storage'));
        }
      });
    });

    group('Security Properties', () {
      test('🔒 Encryption produces different output for same input', () async {
        final testData = {'test': 'data'};

        final result1 = await EncryptionService.encryptSensitiveData(testData);
        final result2 = await EncryptionService.encryptSensitiveData(testData);

        expect(result1, isA<Success<String>>());
        expect(result2, isA<Success<String>>());

        if (result1 is Success<String> && result2 is Success<String>) {
          // Different IVs should produce different ciphertext
          expect(result1.data, isNot(equals(result2.data)));
        }
      });

      test('🛡️ Tampered data fails decryption', () async {
        final testData = {'test': 'data'};

        final encryptResult = await EncryptionService.encryptSensitiveData(
          testData,
        );
        expect(encryptResult, isA<Success<String>>());

        if (encryptResult is Success<String>) {
          // Tamper with encrypted data
          final tamperedData =
              '${encryptResult.data.substring(0, encryptResult.data.length - 5)}XXXXX';

          final decryptResult = await EncryptionService.decryptSensitiveData(
            tamperedData,
          );
          expect(decryptResult, isA<Failure<Map<String, dynamic>>>());
        }
      });
    });

    group('Performance Tests', () {
      test('⚡ Encryption performance within limits', () async {
        final testData = {
          'large_data': 'x' * 1000, // 1KB of data
        };

        final stopwatch = Stopwatch()..start();
        final result = await EncryptionService.encryptSensitiveData(testData);
        stopwatch.stop();

        expect(result, isA<Success<String>>());
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
      });

      test('⚡ Decryption performance within limits', () async {
        final testData = {'test': 'data'};

        final encryptResult = await EncryptionService.encryptSensitiveData(
          testData,
        );
        expect(encryptResult, isA<Success<String>>());

        if (encryptResult is Success<String>) {
          final stopwatch = Stopwatch()..start();
          final decryptResult = await EncryptionService.decryptSensitiveData(
            encryptResult.data,
          );
          stopwatch.stop();

          expect(decryptResult, isA<Success<Map<String, dynamic>>>());
          expect(stopwatch.elapsedMilliseconds, lessThan(100));
        }
      });
    });
  });
}
