import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Tesla-grade application constants with fail-fast security
/// "The best part is no part. The best process is no process."
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// Validation errors for missing critical configuration
  static const String _missingConfigError =
      'CRITICAL: Missing required environment configuration. '
      'Ensure .env file exists in development or secrets are properly injected in production.';

  // App Info - Safe defaults for non-critical values
  static String get appName => dotenv.env['APP_NAME'] ?? 'InvoicePe';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'DEVELOPMENT';

  // Supabase Configuration - FAIL FAST if missing in production
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      if (kReleaseMode) {
        throw StateError('$_missingConfigError Missing SUPABASE_URL');
      }
      // Development fallback - but log warning
      if (kDebugMode) {
        debugPrint('⚠️ WARNING: Using hardcoded Supabase URL for development');
      }
      return 'https://ixwwtabatwskafyvlwnm.supabase.co';
    }
    return url;
  }

  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      if (kReleaseMode) {
        throw StateError('$_missingConfigError Missing SUPABASE_ANON_KEY');
      }
      // Development fallback - but log warning
      if (kDebugMode) {
        debugPrint('⚠️ WARNING: Using hardcoded Supabase key for development');
      }
      return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4d3d0YWJhdHdza2FmeXZsd25tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2NTY0MDAsImV4cCI6MjA2NzIzMjQwMH0.g7UfD3IVgsXEkUSYL4utfXBClzvvpduZDMwqPD0BNwc';
    }
    return key;
  }

  // PhonePe Configuration - Backend only for security
  static String get phonePeEnvironment =>
      dotenv.env['PHONEPE_ENVIRONMENT'] ?? 'UAT';

  // API Endpoints - Safe defaults
  static String get processPaymentFunction =>
      dotenv.env['PROCESS_PAYMENT_FUNCTION'] ?? 'process-payment';
  static String get generateInvoicePdfFunction =>
      dotenv.env['GENERATE_INVOICE_PDF_FUNCTION'] ?? 'generate-invoice-pdf';
  static String get exportLedgerFunction =>
      dotenv.env['EXPORT_LEDGER_FUNCTION'] ?? 'export-ledger';
  static String get initiatePaymentFunction =>
      dotenv.env['INITIATE_PAYMENT_FUNCTION'] ?? 'initiate-payment';

  // Security Configuration - FAIL FAST if missing in production
  static String get encryptionKey {
    final key = dotenv.env['ENCRYPTION_KEY'];
    if (key == null || key.isEmpty) {
      if (kReleaseMode) {
        throw StateError('$_missingConfigError Missing ENCRYPTION_KEY');
      }
      // Development fallback with warning
      if (kDebugMode) {
        debugPrint('⚠️ WARNING: Using default encryption key for development');
      }
      return 'InvoicePe2025AES256SecureKey4PCI';
    }
    return key;
  }

  // Development Configuration
  static bool get debugMode =>
      (dotenv.env['DEBUG_MODE']?.toLowerCase() ?? 'true') == 'true';
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'debug';
  static bool get enableAnalytics =>
      (dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() ?? 'false') == 'true';

  // Storage Buckets
  static const String invoicesBucket = 'invoices';
  static const String vendorLogosBucket = 'vendor-logos';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 16.0;
  static const double cardRadius = 24.0;

  // Payment Constants
  static const double defaultFeePercentage = 0.5; // 0.5%
  static const double defaultRewardsPercentage = 1.0; // 1.0%
  static const double minPaymentAmount = 1.0;
  static const double maxPaymentAmount = 1000000.0;

  // Phone number validation
  static const int phoneNumberLength = 10;
  static const String phoneNumberPattern = r'^[6-9]\d{9}$';

  // Mock Payment Mode - Ship fast, test with real users
  static bool get mockPaymentMode =>
      (dotenv.env['MOCK_PAYMENT_MODE']?.toLowerCase() ?? 'true') == 'true';

  /// Validate critical configuration on app startup
  static void validateConfiguration() {
    try {
      // Force evaluation of critical getters to trigger validation
      final _ = supabaseUrl;
      final __ = supabaseAnonKey;
      final ___ = encryptionKey;

      if (kDebugMode) {
        debugPrint('✅ Configuration validation passed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Configuration validation failed: $e');
      }
      rethrow;
    }
  }
}
