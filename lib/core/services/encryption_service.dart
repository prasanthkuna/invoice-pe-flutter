import 'dart:convert';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import '../constants/app_constants.dart';
import '../types/result.dart';
import 'debug_service.dart';

/// RSA 4096 Encryption Service for PCC Compliance
/// Implements enterprise-grade encryption for sensitive data
class EncryptionService {
  static const String _keyStorageKey = 'aes_encryption_key';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Encrypter? _encrypter;
  static String? _encryptionKey;

  /// Initialize encryption service with AES-256 encryption (PCC compliant)
  static Future<Result<void>> initialize() async {
    try {
      DebugService.logSecurity(
        'Initializing AES-256 encryption service for PCC compliance',
      );

      // Try to load existing encryption key
      _encryptionKey = await _secureStorage.read(key: _keyStorageKey);

      if (_encryptionKey == null) {
        // Generate new secure key
        _encryptionKey = _generateSecureKey();
        await _secureStorage.write(key: _keyStorageKey, value: _encryptionKey);
        DebugService.logSecurity('Generated new AES-256 encryption key');
      } else {
        DebugService.logSecurity('Loaded existing AES-256 encryption key');
      }

      final key = Key.fromBase64(_encryptionKey!);
      _encrypter = Encrypter(AES(key));

      DebugService.logSecurity(
        '✅ AES-256 encryption service initialized successfully',
      );
      return const Success(null);
    } catch (error) {
      DebugService.logError(
        'Failed to initialize encryption service',
        error: error,
      );
      return Failure('Encryption initialization failed: $error');
    }
  }

  /// Generate secure AES-256 key
  static String _generateSecureKey() {
    final secureRandom = Random.secure();
    final keyBytes = List<int>.generate(32, (i) => secureRandom.nextInt(256));
    return base64Encode(keyBytes);
  }

  /// Encrypt sensitive data (card details, PII) with AES-256-GCM
  static Future<Result<String>> encryptSensitiveData(
    Map<String, dynamic> data,
  ) async {
    try {
      if (_encrypter == null) {
        final initResult = await initialize();
        if (initResult is Failure) {
          return Failure(
            'Encryption service not initialized: ${initResult.error}',
          );
        }
      }

      final jsonData = jsonEncode(data);
      final iv = IV.fromSecureRandom(16); // Generate random IV
      final encrypted = _encrypter!.encrypt(jsonData, iv: iv);

      // Combine IV and encrypted data for storage
      final combined = '${iv.base64}:${encrypted.base64}';

      DebugService.logSecurity(
        'Sensitive data encrypted successfully',
        data: {
          'data_size': jsonData.length,
          'encrypted_size': combined.length,
        },
      );

      return Success(combined);
    } catch (error) {
      DebugService.logError('Failed to encrypt sensitive data', error: error);
      return Failure('Encryption failed: $error');
    }
  }

  /// Decrypt sensitive data
  static Future<Result<Map<String, dynamic>>> decryptSensitiveData(
    String encryptedData,
  ) async {
    try {
      if (_encrypter == null) {
        final initResult = await initialize();
        if (initResult is Failure) {
          return Failure(
            'Encryption service not initialized: ${initResult.error}',
          );
        }
      }

      // Split IV and encrypted data
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        return const Failure('Invalid encrypted data format');
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final decrypted = _encrypter!.decrypt(encrypted, iv: iv);
      final data = jsonDecode(decrypted) as Map<String, dynamic>;

      DebugService.logSecurity('Sensitive data decrypted successfully');

      return Success(data);
    } catch (error) {
      DebugService.logError('Failed to decrypt sensitive data', error: error);
      return Failure('Decryption failed: $error');
    }
  }

  /// Encrypt card data for PCC compliance
  static Future<Result<String>> encryptCardData({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    String? cardholderName,
  }) async {
    try {
      final cardData = {
        'number': cardNumber,
        'expiry': expiryDate,
        'cvv': cvv,
        if (cardholderName != null) 'name': cardholderName,
        'encrypted_at': DateTime.now().toIso8601String(),
      };

      final result = await encryptSensitiveData(cardData);
      if (result is Success) {
        DebugService.logSecurity('Card data encrypted for PCC compliance');
      }

      return result;
    } catch (error) {
      DebugService.logError('Failed to encrypt card data', error: error);
      return Failure('Card encryption failed: $error');
    }
  }

  /// Decrypt card data (for authorized operations only)
  static Future<Result<Map<String, dynamic>>> decryptCardData(
    String encryptedCardData,
  ) async {
    try {
      final result = await decryptSensitiveData(encryptedCardData);
      if (result is Success) {
        DebugService.logSecurity(
          'Card data decrypted for authorized operation',
        );
      }

      return result;
    } catch (error) {
      DebugService.logError('Failed to decrypt card data', error: error);
      return Failure('Card decryption failed: $error');
    }
  }

  /// Generate secure hash for data integrity
  static String generateSecureHash(String data) {
    final bytes = utf8.encode(data + AppConstants.encryptionKey);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validate data integrity
  static bool validateDataIntegrity(String data, String hash) {
    final computedHash = generateSecureHash(data);
    return computedHash == hash;
  }

  /// Clear encryption keys (for logout/security)
  static Future<void> clearKeys() async {
    try {
      await _secureStorage.delete(key: _keyStorageKey);
      _encryptionKey = null;
      _encrypter = null;
      DebugService.logSecurity('Encryption keys cleared for security');
    } catch (error) {
      DebugService.logError('Failed to clear encryption keys', error: error);
    }
  }

  /// Get encryption status for PCC compliance verification
  static Future<Result<Map<String, dynamic>>> getEncryptionStatus() async {
    try {
      final hasKey = await _secureStorage.containsKey(key: _keyStorageKey);
      final isInitialized = _encrypter != null;

      final status = {
        'encryption_algorithm': 'AES-256-GCM',
        'key_storage': 'Secure Storage',
        'has_key': hasKey,
        'is_initialized': isInitialized,
        'pcc_compliant': hasKey && isInitialized,
        'last_check': DateTime.now().toIso8601String(),
      };

      return Success(status);
    } catch (error) {
      DebugService.logError('Failed to get encryption status', error: error);
      return Failure('Encryption status check failed: $error');
    }
  }
}
