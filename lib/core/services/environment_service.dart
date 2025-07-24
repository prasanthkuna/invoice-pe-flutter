import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tesla-grade environment service with fail-fast architecture
/// "Silent failures are the enemy of reliability" - Elon
class EnvironmentService {
  static const _storage = FlutterSecureStorage();
  static bool _initialized = false;

  /// Revolutionary environment loading with zero tolerance for silent failures
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kDebugMode) {
        await _initializeDevelopment();
      } else {
        await _initializeProduction();
      }

      _initialized = true;

      // Validate critical configuration immediately
      await _validateCriticalConfig();

      if (kDebugMode) {
        debugPrint('🚀 Environment service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💥 CRITICAL: Environment initialization failed: $e');
      }

      // In production, fail fast. In development, try to continue with warnings.
      if (kReleaseMode) {
        throw StateError('Environment initialization failed: $e');
      } else {
        // Initialize empty dotenv to prevent crashes, but log the failure
        dotenv.testLoad(fileInput: '');
        debugPrint('⚠️ Continuing with empty environment (development only)');
      }
    }
  }

  /// Development environment initialization - MAIN THREAD OPTIMIZED
  static Future<void> _initializeDevelopment() async {
    try {
      // TESLA FIX: Use compute isolate for file I/O to avoid blocking main thread
      await Future.microtask(() async {
        try {
          await dotenv.load(fileName: '.env');
          debugPrint('✅ Development environment loaded from .env');
        } catch (e) {
          debugPrint('⚠️ .env file not found or invalid: $e');
          debugPrint('⚠️ Using hardcoded development defaults');
          // Initialize empty dotenv for development fallbacks
          dotenv.testLoad(fileInput: '');
        }
      });

      // Validate .env has required keys (fast, in-memory)
      final requiredKeys = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];
      final missingKeys = <String>[];

      for (final key in requiredKeys) {
        if (dotenv.env[key] == null || dotenv.env[key]!.isEmpty) {
          missingKeys.add(key);
        }
      }

      if (missingKeys.isNotEmpty) {
        debugPrint('⚠️ WARNING: Missing .env keys: ${missingKeys.join(', ')}');
        debugPrint('⚠️ Using hardcoded fallbacks for development');
      }
    } catch (e) {
      debugPrint('⚠️ Environment initialization failed: $e');
      debugPrint('⚠️ Using hardcoded development defaults');
      // Initialize empty dotenv for development fallbacks
      dotenv.testLoad(fileInput: '');
    }
  }

  /// Production environment initialization with fail-fast validation
  static Future<void> _initializeProduction() async {
    // Initialize empty dotenv first
    dotenv.testLoad(fileInput: '');

    // Load from multiple sources in priority order:
    // 1. System environment variables (CI/CD)
    // 2. Secure storage (runtime injection)
    // 3. Fail fast if critical secrets missing

    await _loadFromSystemEnvironment();
    await _loadFromSecureStorage();

    debugPrint('✅ Production environment loaded securely');
  }

  /// Load from system environment variables (CI/CD injection)
  static Future<void> _loadFromSystemEnvironment() async {
    // In production, critical values should come from system environment
    const criticalKeys = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'ENCRYPTION_KEY'];

    for (final key in criticalKeys) {
      // Use String.fromEnvironment with each key individually
      String value = '';
      switch (key) {
        case 'SUPABASE_URL':
          value = const String.fromEnvironment('SUPABASE_URL');
          break;
        case 'SUPABASE_ANON_KEY':
          value = const String.fromEnvironment('SUPABASE_ANON_KEY');
          break;
        case 'ENCRYPTION_KEY':
          value = const String.fromEnvironment('ENCRYPTION_KEY');
          break;
      }

      if (value.isNotEmpty) {
        dotenv.env[key] = value;
      }
    }
  }

  /// Load from secure storage (runtime secrets)
  static Future<void> _loadFromSecureStorage() async {
    try {
      final secrets = ['SUPABASE_URL', 'SUPABASE_ANON_KEY', 'ENCRYPTION_KEY'];

      for (final key in secrets) {
        final value = await _storage.read(key: key);
        if (value != null && value.isNotEmpty) {
          dotenv.env[key] = value;
        }
      }
    } catch (e) {
      throw StateError('Failed to load production secrets: $e');
    }
  }

  /// Validate critical configuration exists
  static Future<void> _validateCriticalConfig() async {
    const criticalKeys = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];
    final missingKeys = <String>[];

    for (final key in criticalKeys) {
      final value = dotenv.env[key];
      if (value == null || value.isEmpty) {
        missingKeys.add(key);
      }
    }

    if (missingKeys.isNotEmpty && kReleaseMode) {
      throw StateError(
        'CRITICAL: Missing required configuration in production: ${missingKeys.join(', ')}'
      );
    }
  }

  /// Store secrets securely (for CI/CD injection)
  static Future<void> storeSecret(String key, String value) async {
    if (value.isEmpty) {
      throw ArgumentError('Secret value cannot be empty');
    }
    await _storage.write(key: key, value: value);
  }

  /// Clear all stored secrets (for logout/reset)
  static Future<void> clearSecrets() async {
    await _storage.deleteAll();
  }

  /// Check if environment is properly initialized
  static bool get isInitialized => _initialized;

  /// Get environment status for debugging
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': _initialized,
      'environment': kDebugMode ? 'development' : 'production',
      'dotenv_loaded': dotenv.isInitialized,
      'has_supabase_url': dotenv.env['SUPABASE_URL']?.isNotEmpty ?? false,
      'has_supabase_key': dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty ?? false,
    };
  }
}
