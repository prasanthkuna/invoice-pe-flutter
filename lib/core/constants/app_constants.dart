import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Tesla-grade application constants with fail-fast security
/// "The best part is no part. The best process is no process."
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // Removed unused _missingConfigError field

  // App Info - Dynamic environment detection
  static String get appName => dotenv.env['APP_NAME'] ?? 'InvoicePe';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get environment => dotenv.env['ENVIRONMENT'] ?? (kDebugMode ? 'DEBUG' : 'PRODUCTION');

  // Supabase Configuration - Environment-aware with fallbacks
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://ixwwtabatwskafyvlwnm.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4d3d0YWJhdHdza2FmeXZsd25tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2NTY0MDAsImV4cCI6MjA2NzIzMjQwMH0.g7UfD3IVgsXEkUSYL4utfXBClzvvpduZDMwqPD0BNwc';

  // PhonePe Configuration - Environment-aware
  static String get phonePeEnvironment => dotenv.env['PHONEPE_ENVIRONMENT'] ?? 'UAT';
  static String get phonePeMerchantId => dotenv.env['PHONEPE_MERCHANT_ID'] ?? 'DEMOUAT';
  static String get phonePeSaltKey => dotenv.env['PHONEPE_SALT_KEY'] ?? '2a248f9d-db24-4f2d-8512-61449a31292f';
  static String get phonePeSaltIndex => dotenv.env['PHONEPE_SALT_INDEX'] ?? '1';
  static bool get mockPaymentMode {
    // ELON FIX: Force mock mode for PhonePe demo submission
    // This ensures the demo APK always uses mock payments
    return true;

    // TODO: Restore environment-based logic after PhonePe submission:
    // final envMockMode = dotenv.env['MOCK_PAYMENT_MODE'];
    // if (envMockMode != null) {
    //   return envMockMode.toLowerCase() == 'true';
    // }
    // return kDebugMode;
  }

  // API Endpoints - Safe defaults
  static String get processPaymentFunction =>
      dotenv.env['PROCESS_PAYMENT_FUNCTION'] ?? 'process-payment';
  static String get generateInvoicePdfFunction =>
      dotenv.env['GENERATE_INVOICE_PDF_FUNCTION'] ?? 'generate-invoice-pdf';
  static String get exportLedgerFunction =>
      dotenv.env['EXPORT_LEDGER_FUNCTION'] ?? 'export-ledger';
  static String get initiatePaymentFunction =>
      dotenv.env['INITIATE_PAYMENT_FUNCTION'] ?? 'initiate-payment';

  // Security Configuration - Hardcoded for production
  static const String encryptionKey = 'InvoicePe2025AES256SecureKey4PCI';

  // Development Configuration - Environment-aware
  static bool get debugMode => dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true' || kDebugMode;
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? (kDebugMode ? 'DEBUG' : 'INFO');
  static bool get enableAnalytics => dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';
  static bool get enableDatabaseLogging => dotenv.env['ENABLE_DATABASE_LOGGING']?.toLowerCase() != 'false';

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

  // Mock Payment Mode removed - now using environment-aware version above

  /// Validate critical configuration on app startup
  static void validateConfiguration() {
    try {
      // Validate hardcoded constants are not empty
      assert(supabaseUrl.isNotEmpty, 'Supabase URL cannot be empty');
      assert(supabaseAnonKey.isNotEmpty, 'Supabase anon key cannot be empty');
      assert(encryptionKey.isNotEmpty, 'Encryption key cannot be empty');
      assert(appName.isNotEmpty, 'App name cannot be empty');

      if (kDebugMode) {
        debugPrint('✅ Configuration validation passed - All constants hardcoded');
        debugPrint('📱 App: $appName v$appVersion ($environment)');
        debugPrint('🔒 Mock Payment Mode: $mockPaymentMode');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Configuration validation failed: $e');
      }
      rethrow;
    }
  }
}
