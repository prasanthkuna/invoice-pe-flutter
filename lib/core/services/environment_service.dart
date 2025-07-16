import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure environment service for production-safe secret management
class EnvironmentService {
  static const _storage = FlutterSecureStorage();

  /// Load environment configuration securely
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        // Development: Try to load from .env file
        try {
          await dotenv.load(fileName: '.env');
          print('✅ Dev environment loaded from .env');
        } catch (e) {
          // .env file doesn't exist, use defaults from AppConstants
          print('⚠️ .env file not found, using AppConstants defaults');
          // Initialize dotenv with empty content to prevent NotInitializedError
          // This is documented in flutter_dotenv's "Using in tests" section
          dotenv.testLoad(fileInput: '');
        }
      } else {
        // Production: Load from secure storage or environment variables
        await _loadProductionSecrets();
        print('✅ Production environment loaded securely');
      }
    } catch (e) {
      // Don't use DebugService here - it's not initialized yet
      print('⚠️ Environment load failed, using AppConstants defaults: $e');
      // Ensure dotenv is initialized even if everything else fails
      dotenv.testLoad(fileInput: '');
    }
  }

  /// Load production secrets from secure storage
  static Future<void> _loadProductionSecrets() async {
    // In production, secrets should be:
    // 1. Injected via CI/CD environment variables
    // 2. Stored in secure storage after first launch
    // 3. Retrieved from secure backend endpoints

    // Initialize dotenv with empty content first to prevent NotInitializedError
    dotenv.testLoad(fileInput: '');

    // Example: Load from secure storage
    final supabaseUrl = await _storage.read(key: 'SUPABASE_URL');
    if (supabaseUrl != null) {
      dotenv.env['SUPABASE_URL'] = supabaseUrl;
    }

    final supabaseAnonKey = await _storage.read(key: 'SUPABASE_ANON_KEY');
    if (supabaseAnonKey != null) {
      dotenv.env['SUPABASE_ANON_KEY'] = supabaseAnonKey;
    }
  }

  /// Store secrets securely (for CI/CD injection)
  static Future<void> storeSecret(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Clear all stored secrets (for logout)
  static Future<void> clearSecrets() async {
    await _storage.deleteAll();
  }
}
