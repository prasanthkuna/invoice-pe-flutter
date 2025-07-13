import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

/// Elon Physics Way Debug Service: Minimal but Comprehensive Logging
/// First Principles: What's the minimum data needed to solve maximum problems?
class DebugService {
  static late Logger _logger;
  static bool _initialized = false;
  static String? _sessionId;
  static final List<Map<String, dynamic>> _logBuffer = [];
  static bool _dbLoggingEnabled = true;

  /// Initialize the debug service with session tracking
  static void initialize() {
    if (_initialized) return;

    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: ConsoleOutput(),
    );

    // Generate unique session ID for correlation
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    _initialized = true;
    logInfo('🚀 DebugService initialized', context: {'session_id': _sessionId});
  }

  /// Log info messages
  static void logInfo(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context}) {
    if (!_initialized) initialize();
    _logger.i(message, error: error, stackTrace: stackTrace);
    // Info logs stay local only for performance
  }

  /// Log debug messages (only in debug mode)
  static void logDebug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning messages (also logs to database)
  static void logWarning(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context, String? operation}) {
    if (!_initialized) initialize();
    _logger.w(message, error: error, stackTrace: stackTrace);

    // Log warnings to database for monitoring
    _logToDatabase(
      level: 'WARN',
      category: 'GENERAL',
      operation: operation ?? 'unknown',
      message: message,
      context: context,
      error: error,
    );
  }

  /// Log error messages (also logs to database)
  static void logError(String message, {dynamic error, StackTrace? stackTrace, Map<String, dynamic>? context, String? operation}) {
    if (!_initialized) initialize();
    _logger.e(message, error: error, stackTrace: stackTrace);

    // Log errors to database for immediate attention
    _logToDatabase(
      level: 'ERROR',
      category: 'GENERAL',
      operation: operation ?? 'unknown',
      message: message,
      context: context,
      error: error,
    );
  }

  /// Log Supabase authentication events with detailed error analysis
  static void logAuth(String event, {Map<String, dynamic>? data, dynamic error, int? performanceMs}) {
    if (!_initialized) initialize();
    final message = '🔐 AUTH: $event';

    if (error != null) {
      final errorDetails = _extractDetailedError(error);
      _logger.e(message, error: errorDetails);

      // Log auth errors to database
      _logToDatabase(
        level: 'ERROR',
        category: 'AUTH',
        operation: event,
        message: message,
        context: data,
        error: error,
        performanceMs: performanceMs,
      );
    } else {
      _logger.i('$message ${data != null ? '- Data: $data' : ''}');

      // Log successful auth events to database for monitoring
      _logToDatabase(
        level: 'INFO',
        category: 'AUTH',
        operation: event,
        message: message,
        context: data,
        performanceMs: performanceMs,
      );
    }
  }

  /// Log Supabase database operations with database logging for errors
  static void logDatabase(String operation, {String? table, Map<String, dynamic>? data, dynamic error, int? performanceMs}) {
    if (!_initialized) initialize();
    final message = '🗄️ DB: $operation${table != null ? ' on $table' : ''}';

    if (error != null) {
      _logger.e(message, error: error);

      // Log database errors to database
      _logToDatabase(
        level: 'ERROR',
        category: 'DB',
        operation: operation,
        message: message,
        context: {'table': table, ...?data},
        error: error,
        performanceMs: performanceMs,
      );
    } else {
      _logger.i('$message ${data != null ? '- Data: $data' : ''}');

      // Log slow database operations (>1 second)
      if (performanceMs != null && performanceMs > 1000) {
        _logToDatabase(
          level: 'WARN',
          category: 'DB',
          operation: operation,
          message: 'Slow DB operation: $message',
          context: {'table': table, ...?data},
          performanceMs: performanceMs,
        );
      }
    }
  }

  /// Log API calls with database logging for errors
  static void logApi(String method, String endpoint, {Map<String, dynamic>? data, dynamic error, int? statusCode}) {
    if (!_initialized) initialize();
    final message = '🌐 API: $method $endpoint${statusCode != null ? ' ($statusCode)' : ''}';

    if (error != null) {
      _logger.e(message, error: error);

      // Log API errors to database
      _logToDatabase(
        level: 'ERROR',
        category: 'API',
        operation: '$method $endpoint',
        message: message,
        context: data,
        error: error,
        performanceMs: data?['duration_ms'] as int?,
      );
    } else {
      _logger.i('$message ${data != null ? '- Data: $data' : ''}');

      // Log slow API calls to database (>2 seconds)
      final duration = data?['duration_ms'] as int?;
      if (duration != null && duration > 2000) {
        _logToDatabase(
          level: 'WARN',
          category: 'API',
          operation: '$method $endpoint',
          message: 'Slow API call: $message',
          context: data,
          performanceMs: duration,
        );
      }
    }
  }

  /// Log navigation events (critical routes logged to database)
  static void logNavigation(String route, {Map<String, dynamic>? params}) {
    if (!_initialized) initialize();
    _logger.i('🧭 NAVIGATION: $route ${params != null ? '- Params: $params' : ''}');

    // Log critical navigation events to database
    final criticalRoutes = ['/login', '/dashboard', '/payment', '/payment-success'];
    if (criticalRoutes.any((r) => route.contains(r))) {
      _logToDatabase(
        level: 'INFO',
        category: 'NAVIGATION',
        operation: 'route_change',
        message: 'Navigation to $route',
        context: params,
      );
    }
  }

  /// Log user actions (important actions logged to database)
  static void logUserAction(String action, {Map<String, dynamic>? context}) {
    if (!_initialized) initialize();
    _logger.i('👤 USER: $action ${context != null ? '- Context: $context' : ''}');

    // Log important user actions to database
    final importantActions = ['payment_initiated', 'vendor_selected', 'logout', 'profile_updated'];
    if (importantActions.contains(action)) {
      _logToDatabase(
        level: 'INFO',
        category: 'USER_ACTION',
        operation: action,
        message: 'User action: $action',
        context: context,
      );
    }
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration, {Map<String, dynamic>? metrics}) {
    if (!_initialized) initialize();
    _logger.i('⚡ PERFORMANCE: $operation took ${duration.inMilliseconds}ms ${metrics != null ? '- Metrics: $metrics' : ''}');
  }

  /// Log network connectivity
  static void logNetwork(String status, {Map<String, dynamic>? details}) {
    if (!_initialized) initialize();
    _logger.i('📶 NETWORK: $status ${details != null ? '- Details: $details' : ''}');
  }

  /// Log session events
  static void logSession(String event, {String? userId, Map<String, dynamic>? sessionData}) {
    if (!_initialized) initialize();
    _logger.i('🎫 SESSION: $event${userId != null ? ' for user $userId' : ''} ${sessionData != null ? '- Data: $sessionData' : ''}');
  }

  /// Log security events (PCC compliance - all security events logged to database)
  static void logSecurity(String event, {Map<String, dynamic>? data, String? userId}) {
    if (!_initialized) initialize();
    _logger.i('🔐 SECURITY: $event${userId != null ? ' for user $userId' : ''} ${data != null ? '- Data: $data' : ''}');

    // All security events are logged to database for PCC compliance
    _logToDatabase(
      level: 'INFO',
      category: 'SECURITY',
      operation: event,
      message: 'Security event: $event',
      context: {
        if (userId != null) 'user_id': userId,
        if (data != null) ...data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log security violations (critical - always logged to database)
  static void logSecurityViolation(String violation, {Map<String, dynamic>? context, String? userId}) {
    if (!_initialized) initialize();
    _logger.e('🚨 SECURITY VIOLATION: $violation${userId != null ? ' by user $userId' : ''} ${context != null ? '- Context: $context' : ''}');

    // Critical security violations always logged to database
    _logToDatabase(
      level: 'ERROR',
      category: 'SECURITY_VIOLATION',
      operation: violation,
      message: 'Security violation: $violation',
      context: {
        if (userId != null) 'user_id': userId,
        if (context != null) ...context,
        'timestamp': DateTime.now().toIso8601String(),
        'severity': 'CRITICAL',
      },
    );
  }

  /// Log audit trail for PCC compliance
  static void logAuditTrail(String action, {required String userId, Map<String, dynamic>? details}) {
    if (!_initialized) initialize();
    _logger.i('📋 AUDIT: $action by user $userId ${details != null ? '- Details: $details' : ''}');

    // All audit events logged to database for compliance
    _logToDatabase(
      level: 'INFO',
      category: 'AUDIT',
      operation: action,
      message: 'Audit trail: $action',
      context: {
        'user_id': userId,
        if (details != null) ...details,
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': _sessionId,
      },
    );
  }

  /// Log payment events (all payment events logged to database)
  static void logPayment(String event, {String? transactionId, double? amount, dynamic error, int? performanceMs}) {
    if (!_initialized) initialize();
    final message = '💳 PAYMENT: $event${transactionId != null ? ' ($transactionId)' : ''}${amount != null ? ' - ₹$amount' : ''}';

    if (error != null) {
      _logger.e(message, error: error);

      // Log payment errors to database (critical)
      _logToDatabase(
        level: 'ERROR',
        category: 'PAYMENT',
        operation: event,
        message: message,
        context: {
          'transaction_id': transactionId,
          'amount': amount,
        },
        error: error,
        performanceMs: performanceMs,
      );
    } else {
      _logger.i(message);

      // Log all payment events to database for audit trail
      _logToDatabase(
        level: 'INFO',
        category: 'PAYMENT',
        operation: event,
        message: message,
        context: {
          'transaction_id': transactionId,
          'amount': amount,
        },
        performanceMs: performanceMs,
      );
    }
  }

  /// Log file operations
  static void logFile(String operation, String path, {int? size, dynamic error}) {
    if (!_initialized) initialize();
    final message = '📁 FILE: $operation $path${size != null ? ' (${size}B)' : ''}';
    if (error != null) {
      _logger.e(message, error: error);
    } else {
      _logger.i(message);
    }
  }

  /// Log critical errors that need immediate attention with detailed analysis
  static void logCritical(String message, dynamic error, [StackTrace? stackTrace]) {
    if (!_initialized) initialize();
    final errorDetails = _extractDetailedError(error);
    _logger.f('🚨 CRITICAL: $message', error: errorDetails, stackTrace: stackTrace);
  }

  /// Get formatted timestamp
  static String get timestamp => DateTime.now().toIso8601String();

  /// Check if debug mode is enabled
  static bool get isDebugMode => kDebugMode;

  /// Extract ONLY the critical error details - minimal but precise
  static String _extractDetailedError(dynamic error) {
    if (error == null) return 'NULL_ERROR';

    final errorStr = error.toString();

    // For database errors, extract the core issue
    if (errorStr.contains('Database error saving new user')) {
      // This is the key error - let's see if we can get more from the error object
      if (error.runtimeType.toString().contains('AuthRetryableFetchException')) {
        return 'DB_SAVE_FAILED: AuthRetryableFetchException - Check trigger function permissions';
      }
    }

    // Extract just the essential parts
    if (errorStr.contains('message:')) {
      final start = errorStr.indexOf('message:') + 8;
      final end = errorStr.indexOf(',', start);
      if (end > start) {
        return errorStr.substring(start, end).trim().replaceAll('"', '');
      }
    }

    return errorStr.length > 100 ? '${errorStr.substring(0, 100)}...' : errorStr;
  }

  /// Log to database for critical events (ERROR, WARN)
  static Future<void> _logToDatabase({
    required String level,
    required String category,
    required String operation,
    required String message,
    Map<String, dynamic>? context,
    dynamic error,
    int? performanceMs,
  }) async {
    if (!_dbLoggingEnabled || !_initialized) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      final logData = {
        'user_id': userId,
        'session_id': _sessionId,
        'level': level,
        'category': category,
        'operation': operation,
        'message': message,
        'context': context ?? {},
        'error_details': error != null ? {
          'error': _extractDetailedError(error),
          'type': error.runtimeType.toString(),
        } : <String, dynamic>{},
        'performance_ms': performanceMs,
        'device_info': {
          'platform': kIsWeb ? 'web' : Platform.operatingSystem,
          'debug_mode': kDebugMode,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      // Add to buffer for batch processing
      _logBuffer.add(logData);

      // Flush buffer if it gets too large or for critical errors
      if (_logBuffer.length >= 10 || level == 'ERROR') {
        await _flushLogBuffer();
      }
    } catch (e) {
      // Don't let logging errors crash the app
      _logger.e('Failed to log to database: $e');
    }
  }

  /// Flush log buffer to database
  static Future<void> _flushLogBuffer() async {
    if (_logBuffer.isEmpty) return;

    try {
      final logsToFlush = List<Map<String, dynamic>>.from(_logBuffer);
      _logBuffer.clear();

      await Supabase.instance.client
          .from('logs')
          .insert(logsToFlush);
    } catch (e) {
      // Don't let logging errors crash the app
      _logger.e('Failed to flush log buffer: $e');
    }
  }

  /// Enable/disable database logging
  static void setDatabaseLogging(bool enabled) {
    _dbLoggingEnabled = enabled;
  }

  /// Get current session ID
  static String? get sessionId => _sessionId;
}
