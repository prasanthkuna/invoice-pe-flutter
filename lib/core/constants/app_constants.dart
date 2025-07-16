import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core application constants
class AppConstants {
  // App Info
  static String get appName => dotenv.env['APP_NAME'] ?? 'InvoicePe Staging';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0-staging';
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'STAGING';

  // Supabase Configuration - Real staging values
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://ixwwtabatwskafyvlwnm.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml4d3d0YWJhdHdza2FmeXZsd25tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2NTY0MDAsImV4cCI6MjA2NzIzMjQwMH0.g7UfD3IVgsXEkUSYL4utfXBClzvvpduZDMwqPD0BNwc';
  // Service role key removed - should only exist on backend

  // PhonePe Configuration - Moved to backend for security
  static String get phonePeEnvironment =>
      dotenv.env['PHONEPE_ENVIRONMENT'] ?? 'UAT';
  // PhonePe credentials removed - handled by backend Edge Functions

  // API Endpoints
  static String get processPaymentFunction =>
      dotenv.env['PROCESS_PAYMENT_FUNCTION'] ?? 'process-payment';
  static String get generateInvoicePdfFunction =>
      dotenv.env['GENERATE_INVOICE_PDF_FUNCTION'] ?? 'generate-invoice-pdf';
  static String get exportLedgerFunction =>
      dotenv.env['EXPORT_LEDGER_FUNCTION'] ?? 'export-ledger';
  static String get initiatePaymentFunction =>
      dotenv.env['INITIATE_PAYMENT_FUNCTION'] ?? 'initiate-payment';

  // Security Configuration
  static String get encryptionKey => 
      dotenv.env['ENCRYPTION_KEY'] ?? 'InvoicePe2025AES256SecureKey4PCI';
  // JWT secret removed - backend only

  // Development Configuration
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true' ?? true;
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'debug';
  static bool get enableAnalytics =>
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true' ?? true;

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
  
  // Mock Payment Mode - Ship fast, test with real users
  static bool get mockPaymentMode =>
      dotenv.env['MOCK_PAYMENT_MODE']?.toLowerCase() == 'true' ?? true;
}
