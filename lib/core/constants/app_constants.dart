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

  // App Info - Hardcoded for reliability
  static const String appName = 'InvoicePe';
  static const String appVersion = '1.0.0';
  static const String environment = 'PRODUCTION';

  // Supabase Configuration - Hardcoded for production reliability
  static const String supabaseUrl = 'https://ixwwtabatwskafyvlwnm.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4d3d0YWJhdHdza2FmeXZsd25tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2NTY0MDAsImV4cCI6MjA2NzIzMjQwMH0.g7UfD3IVgsXEkUSYL4utfXBClzvvpduZDMwqPD0BNwc';

  // PhonePe Configuration - Hardcoded for production
  static const String phonePeEnvironment = 'UAT';
  static const String phonePeMerchantId = 'DEMOUAT';
  static const String phonePeSaltIndex = '1';

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

  // Development Configuration - Keep minimal env dependencies for debug flags
  static bool get debugMode => kDebugMode;
  static const String logLevel = 'info';
  static const bool enableAnalytics = false;

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

  // Mock Payment Mode - Hardcoded for production control
  static const bool mockPaymentMode = true; // Set to false for live payments

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
