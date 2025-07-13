import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core application constants
class AppConstants {
  // App Info
  static String get appName => dotenv.env['APP_NAME'] ?? 'InvoicePe';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'UAT';

  // Supabase Configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project-id.supabase.co';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-anon-key-here';
  static String get supabaseServiceRoleKey =>
      dotenv.env['SUPABASE_SERVICE_ROLE_KEY'] ?? 'your-service-role-key-here';

  // PhonePe Configuration
  static String get phonePeMerchantId =>
      dotenv.env['PHONEPE_MERCHANT_ID'] ?? 'YOUR_MERCHANT_ID';
  static String get phonePeSaltKey =>
      dotenv.env['PHONEPE_SALT_KEY'] ?? 'your-salt-key-here';
  static String get phonePeSaltIndex => dotenv.env['PHONEPE_SALT_INDEX'] ?? '1';
  static String get phonePeEnvironment =>
      dotenv.env['PHONEPE_ENVIRONMENT'] ?? 'UAT';

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
      dotenv.env['ENCRYPTION_KEY'] ?? 'your-encryption-key-here';
  static String get jwtSecret =>
      dotenv.env['JWT_SECRET'] ?? 'your-jwt-secret-here';

  // Development Configuration
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  static String get logLevel => dotenv.env['LOG_LEVEL'] ?? 'info';
  static bool get enableAnalytics =>
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';

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
}
