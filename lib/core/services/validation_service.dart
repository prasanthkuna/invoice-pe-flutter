import 'dart:convert';
import '../types/result.dart';
import 'logger.dart';

final _log = Log.component('validation');

/// Enhanced Input Validation Service for PCC Compliance
/// Implements XSS protection, SQL injection prevention, and security hardening
class ValidationService {
  // XSS Protection patterns
  static final RegExp _xssPattern = RegExp(
    r'<script[^>]*>.*?</script>|javascript:|on\w+\s*=|<iframe|<object|<embed|<link|<meta',
    caseSensitive: false,
    multiLine: true,
  );

  // SQL Injection patterns
  static final RegExp _sqlInjectionPattern = RegExp(
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)|('|('')|;|--|/\*|\*/)",
    caseSensitive: false,
  );

  // Malicious file patterns
  static final RegExp _maliciousFilePattern = RegExp(
    r'\.(exe|bat|cmd|com|pif|scr|vbs|js|jar|php|asp|jsp)$',
    caseSensitive: false,
  );

  // Phone number validation (international format)
  static final RegExp _phonePattern = RegExp(r'^\+?[1-9]\d{1,14}$');

  // Email validation (simplified but reliable)
  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // UPI ID validation
  static final RegExp _upiPattern = RegExp(
    r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$',
  );

  // GSTIN validation
  static final RegExp _gstinPattern = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  // Account number validation (9-18 digits)
  static final RegExp _accountNumberPattern = RegExp(r'^\d{9,18}$');

  // IFSC code validation
  static final RegExp _ifscPattern = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  /// Sanitize input to prevent XSS attacks
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;

    // Remove potential XSS patterns
    var sanitized = input.replaceAll(_xssPattern, '');

    // HTML encode special characters
    sanitized = sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');

    // Log if sanitization occurred
    if (sanitized != input) {
      _log.info(
        'XSS attempt detected and sanitized',
        context: {
          'original_length': input.length,
          'sanitized_length': sanitized.length,
          'input_hash': input.hashCode.toString(),
        },
      );
    }

    return sanitized.trim();
  }

  /// Validate and sanitize text input
  static Result<String> validateTextInput(
    String input, {
    required String fieldName,
    int? minLength,
    int? maxLength,
    bool allowEmpty = false,
    bool sanitize = true,
  }) {
    try {
      // Check for empty input
      if (input.trim().isEmpty && !allowEmpty) {
        return Failure('$fieldName is required');
      }

      // Sanitize input if requested
      final validatedInput = sanitize ? sanitizeInput(input) : input.trim();

      // Check for SQL injection attempts
      if (_sqlInjectionPattern.hasMatch(validatedInput)) {
        _log.info(
          'SQL injection attempt detected',
          context: {
            'field': fieldName,
            'input_hash': input.hashCode.toString(),
          },
        );
        return Failure('Invalid characters detected in $fieldName');
      }

      // Length validation
      if (minLength != null && validatedInput.length < minLength) {
        return Failure('$fieldName must be at least $minLength characters');
      }

      if (maxLength != null && validatedInput.length > maxLength) {
        return Failure('$fieldName must not exceed $maxLength characters');
      }

      return Success(validatedInput);
    } catch (error) {
      _log.info('Text validation failed'.error(_log.info('Text validation failed', error: error$(if () { ", stackTrace: " } else { "" }));
      return Failure('Validation error for $fieldName');
    }
  }

  /// Validate phone number
  static Result<String> validatePhoneNumber(String phone) {
    final sanitized = sanitizeInput(phone);

    if (sanitized.isEmpty) {
      return const Failure('Phone number is required');
    }

    // Remove spaces and special characters except +
    final cleaned = sanitized.replaceAll(RegExp(r'[^\d+]'), '');

    if (!_phonePattern.hasMatch(cleaned)) {
      return const Failure('Enter a valid phone number');
    }

    return Success(cleaned);
  }

  /// Validate email address
  static Result<String> validateEmail(String email, {bool required = true}) {
    final sanitized = sanitizeInput(email);

    if (sanitized.isEmpty) {
      return required ? const Failure('Email is required') : const Success('');
    }

    if (!_emailPattern.hasMatch(sanitized)) {
      return const Failure('Enter a valid email address');
    }

    return Success(sanitized.toLowerCase());
  }

  /// Validate UPI ID
  static Result<String> validateUpiId(String upiId) {
    final sanitized = sanitizeInput(upiId);

    if (sanitized.isEmpty) {
      return const Failure('UPI ID is required');
    }

    if (!_upiPattern.hasMatch(sanitized)) {
      return const Failure('Enter a valid UPI ID (e.g., user@paytm)');
    }

    return Success(sanitized.toLowerCase());
  }

  /// Validate amount (financial)
  static Result<double> validateAmount(
    String amount, {
    double? minAmount,
    double? maxAmount,
  }) {
    final sanitized = sanitizeInput(amount);

    if (sanitized.isEmpty) {
      return const Failure('Amount is required');
    }

    final parsedAmount = double.tryParse(sanitized);
    if (parsedAmount == null) {
      return const Failure('Enter a valid amount');
    }

    if (parsedAmount <= 0) {
      return const Failure('Amount must be greater than 0');
    }

    if (minAmount != null && parsedAmount < minAmount) {
      return Failure('Amount must be at least Ã¢â€šÂ¹$minAmount');
    }

    if (maxAmount != null && parsedAmount > maxAmount) {
      return Failure('Amount cannot exceed Ã¢â€šÂ¹$maxAmount');
    }

    return Success(parsedAmount);
  }

  /// Validate GSTIN
  static Result<String> validateGstin(String gstin, {bool required = false}) {
    final sanitized = sanitizeInput(gstin);

    if (sanitized.isEmpty) {
      return required ? const Failure('GSTIN is required') : const Success('');
    }

    if (!_gstinPattern.hasMatch(sanitized)) {
      return const Failure('Enter a valid GSTIN (15 characters)');
    }

    return Success(sanitized.toUpperCase());
  }

  /// Validate account number
  static Result<String> validateAccountNumber(String accountNumber) {
    final sanitized = sanitizeInput(accountNumber);

    if (sanitized.isEmpty) {
      return const Failure('Account number is required');
    }

    if (!_accountNumberPattern.hasMatch(sanitized)) {
      return const Failure('Enter a valid account number (9-18 digits)');
    }

    return Success(sanitized);
  }

  /// Validate IFSC code
  static Result<String> validateIfscCode(String ifsc) {
    final sanitized = sanitizeInput(ifsc);

    if (sanitized.isEmpty) {
      return const Failure('IFSC code is required');
    }

    if (!_ifscPattern.hasMatch(sanitized)) {
      return const Failure('Enter a valid IFSC code (e.g., SBIN0001234)');
    }

    return Success(sanitized.toUpperCase());
  }

  /// Validate file upload
  static Result<String> validateFileUpload(
    String fileName, {
    List<String>? allowedExtensions,
    int? maxSizeBytes,
  }) {
    final sanitized = sanitizeInput(fileName);

    if (sanitized.isEmpty) {
      return const Failure('File name is required');
    }

    // Check for malicious file types
    if (_maliciousFilePattern.hasMatch(sanitized)) {
      _log.info(
        'Malicious file upload attempt',
        context: {
          'filename': sanitized,
        },
      );
      return const Failure('File type not allowed for security reasons');
    }

    // Check allowed extensions
    if (allowedExtensions != null) {
      final extension = sanitized.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        return Failure(
          'Only ${allowedExtensions.join(', ')} files are allowed',
        );
      }
    }

    return Success(sanitized);
  }

  /// Validate JSON input for API calls
  static Result<Map<String, dynamic>> validateJsonInput(String jsonString) {
    try {
      final sanitized = sanitizeInput(jsonString);

      if (sanitized.isEmpty) {
        return const Failure('JSON data is required');
      }

      final decoded = jsonDecode(sanitized);
      if (decoded is! Map<String, dynamic>) {
        return const Failure('Invalid JSON format');
      }
      final data = decoded;

      // Additional security checks for JSON
      _validateJsonSecurity(data);

      return Success(data);
    } catch (error) {
      _log.info('JSON validation failed'.error(_log.info('JSON validation failed', error: error$(if () { ", stackTrace: " } else { "" }));
      return const Failure('Invalid JSON format');
    }
  }

  /// Security validation for JSON data
  static void _validateJsonSecurity(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is String) {
        // Check for XSS in string values
        if (_xssPattern.hasMatch(value)) {
          _log.info(
            'XSS attempt in JSON data',
            context: {
              'field': key,
              'value_hash': value.hashCode.toString(),
            },
          );
        }

        // Check for SQL injection in string values
        if (_sqlInjectionPattern.hasMatch(value)) {
          _log.info(
            'SQL injection attempt in JSON data',
            context: {
              'field': key,
              'value_hash': value.hashCode.toString(),
            },
          );
        }
      } else if (value is Map<String, dynamic>) {
        // Recursively validate nested objects
        _validateJsonSecurity(value);
      } else if (value is List) {
        // Validate list items
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            _validateJsonSecurity(item);
          }
        }
      }
    });
  }

  /// Rate limiting validation (prevent brute force)
  static final Map<String, List<DateTime>> _rateLimitMap = {};

  static Result<void> validateRateLimit(
    String identifier, {
    int maxAttempts = 5,
    Duration timeWindow = const Duration(minutes: 15),
  }) {
    final now = DateTime.now();
    final attempts = _rateLimitMap[identifier] ?? [];

    // Remove old attempts outside the time window
    attempts.removeWhere((attempt) => now.difference(attempt) > timeWindow);

    if (attempts.length >= maxAttempts) {
      _log.info(
        'Rate limit exceeded',
        context: {
          'identifier': identifier,
          'attempts': attempts.length,
          'time_window_minutes': timeWindow.inMinutes,
        },
      );
      return Failure(
        'Too many attempts. Please try again in ${timeWindow.inMinutes} minutes.',
      );
    }

    // Add current attempt
    attempts.add(now);
    _rateLimitMap[identifier] = attempts;

    return const Success(null);
  }

  /// Clear rate limit for identifier (on successful operation)
  static void clearRateLimit(String identifier) {
    _rateLimitMap.remove(identifier);
  }
}
