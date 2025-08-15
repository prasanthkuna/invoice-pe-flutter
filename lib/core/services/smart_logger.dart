import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// InvoicePe Smart Logger - 2025 Best Practices
/// Elon's Philosophy: "Log smart, not hard. Every log should solve a problem."
class SmartLogger {
  static late Logger _logger;
  static bool _initialized = false;
  static String? _correlationId;

  // Smart sampling rates (configurable via environment)
  static double _apiSamplingRate = 0.1; // 10% of API calls
  static double _uiSamplingRate = 0.05; // 5% of UI events

  /// Initialize smart logger with correlation tracking
  static void initialize({
    double apiSamplingRate = 0.1,
    double uiSamplingRate = 0.05,
  }) {
    if (_initialized) return;

    _apiSamplingRate = apiSamplingRate;
    _uiSamplingRate = uiSamplingRate;

    _logger = Logger(
      filter: _SmartProductionFilter(),
      printer: _SmartPrettyPrinter(),
      output: ConsoleOutput(),
    );

    _generateCorrelationId();
    _initialized = true;

    logInfo(
      '🧠 SmartLogger initialized',
      context: {
        'correlation_id': _correlationId,
        'api_sampling_rate': _apiSamplingRate,
        'ui_sampling_rate': _uiSamplingRate,
      },
    );
  }

  /// Generate unique correlation ID for request tracking
  static void _generateCorrelationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    _correlationId = 'req_${timestamp}_$random';
  }

  /// Start new request correlation (for API calls, user actions)
  static String startNewCorrelation() {
    _generateCorrelationId();
    return _correlationId!;
  }

  /// Smart logging with automatic PII masking and sampling
  static void logInfo(
    String message, {
    Map<String, dynamic>? context,
    String? category,
    bool forceSample = false,
  }) {
    try {
      if (!_initialized) initialize();

      // Smart sampling for routine operations
      if (!forceSample && !_shouldSample(category ?? 'general')) {
        return;
      }

      final enrichedContext = _enrichContext(context, category);
      final maskedMessage = _maskPII(message);

      _logger.i(maskedMessage, error: null, stackTrace: null);
      _logToBuffer('INFO', maskedMessage, enrichedContext);
    } catch (e) {
      // ELON FIX: Never crash app due to logging
      if (kDebugMode) {
        debugPrint('❌ SmartLogger.logInfo failed: $e');
      }
    }
  }

  /// Business-critical logging (always logged, never sampled)
  static void logPayment(
    String message, {
    Map<String, dynamic>? context,
  }) {
    try {
      if (!_initialized) initialize();

      final enrichedContext = _enrichContext(context, 'payment');
      final maskedMessage = _maskPII(message);

      _logger.i('💰 PAYMENT: $maskedMessage');
      _logToBuffer('INFO', maskedMessage, enrichedContext);
    } catch (e) {
      // ELON FIX: Never crash app due to payment logging
      if (kDebugMode) {
        debugPrint('❌ SmartLogger.logPayment failed: $e');
      }
    }
  }

  /// Security logging (always logged, high priority)
  static void logSecurity(
    String message, {
    Map<String, dynamic>? context,
  }) {
    if (!_initialized) initialize();

    final enrichedContext = _enrichContext(context, 'security');
    final maskedMessage = _maskPII(message);

    _logger.w('🔒 SECURITY: $maskedMessage');
    _logToBuffer('WARN', maskedMessage, enrichedContext);
  }

  /// Error logging (always logged, full context)
  static void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    try {
      if (!_initialized) initialize();

      final enrichedContext = _enrichContext(context, 'error');
      final maskedMessage = _maskPII(message);

      _logger.e(
        '❌ ERROR: $maskedMessage',
        error: error,
        stackTrace: stackTrace,
      );
      _logToBuffer(
        'ERROR',
        maskedMessage,
        enrichedContext,
        error: error,
        stackTrace: stackTrace,
      ); // ELON FIX: Pass error parameters
    } catch (e) {
      // ELON FIX: Never crash app due to error logging (ironic but necessary)
      if (kDebugMode) {
        debugPrint('❌ SmartLogger.logError failed: $e');
      }
    }
  }

  /// Performance logging with timing
  static void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? context,
  }) {
    if (!_initialized) initialize();

    final enrichedContext = _enrichContext(context, 'performance');
    enrichedContext['duration_ms'] = duration.inMilliseconds;
    enrichedContext['operation'] = operation;

    final message =
        '⚡ PERFORMANCE: $operation took ${duration.inMilliseconds}ms';
    _logger.i(message);
    _logToBuffer('INFO', message, enrichedContext);
  }

  /// Smart sampling logic
  static bool _shouldSample(String category) {
    switch (category) {
      case 'api':
        return Random().nextDouble() < _apiSamplingRate;
      case 'ui':
        return Random().nextDouble() < _uiSamplingRate;
      case 'payment':
      case 'security':
      case 'error':
      case 'auth':
        return true; // Always log business-critical events
      default:
        return Random().nextDouble() < 0.1; // 10% default sampling
    }
  }

  /// Enrich context with correlation ID and metadata
  static Map<String, dynamic> _enrichContext(
    Map<String, dynamic>? context,
    String? category,
  ) {
    final enriched = <String, dynamic>{
      'correlation_id': _correlationId,
      'timestamp': DateTime.now().toIso8601String(),
      'category': category ?? 'general',
      'environment': kDebugMode ? 'debug' : 'release',
      'platform': defaultTargetPlatform.name,
    };

    if (context != null) {
      enriched.addAll(context);
    }

    return enriched;
  }

  /// PII masking for fintech compliance
  static String _maskPII(String message) {
    // Email masking
    message = message.replaceAllMapped(
      RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b'),
      (match) => '[EMAIL_MASKED]',
    );

    // Phone number masking
    message = message.replaceAllMapped(
      RegExp(r'\+?[\d\s\-\(\)]{10,}'),
      (match) => '[PHONE_MASKED]',
    );

    // Credit card masking
    message = message.replaceAllMapped(
      RegExp(r'\b\d{4}[- ]?\d{4}[- ]?\d{4}[- ]?\d{4}\b'),
      (match) => '[CARD_MASKED]',
    );

    return message;
  }

  /// Buffer logs for database logging
  static void _logToBuffer(
    String level,
    String message,
    Map<String, dynamic> context, {
    dynamic error,
    StackTrace? stackTrace, // ELON FIX: Add error parameters
  }) {
    // ELON FIX: Always enable database logging for debugging payment issues
    // Only skip during tests to avoid test database pollution
    if (const bool.fromEnvironment('flutter.test', defaultValue: false)) {
      return;
    }

    // ELON FIX: Completely non-blocking logging - never crash the app
    Future.microtask(() async {
      try {
        // ELON FIX: Allow anonymous logging for auth failures and critical errors
        final currentUser = Supabase.instance.client.auth.currentUser;
        final isAuthError = (context['category'] == 'auth') || level == 'ERROR';

        if (currentUser == null && !isAuthError) {
          // Skip logging for non-auth events when not authenticated
          if (kDebugMode) {
            debugPrint(
              '⚠️ No authenticated user, skipping non-auth database log',
            );
          }
          return;
        }

        // ELON FIX: Match exact database schema from migration + error_details
        await Supabase.instance.client.from('logs').insert({
          'user_id':
              currentUser?.id, // Allow null for anonymous auth error logging
          'level': level,
          'category': context['category'] ?? 'general',
          'message': message,
          'operation': context['operation'] ?? 'unknown',
          'context': context,
          'session_id': _correlationId,
          'created_at': DateTime.now().toIso8601String(),
          'error_details': error != null || stackTrace != null
              ? {
                  'error': error?.toString(),
                  'stack_trace': stackTrace?.toString(),
                  'error_type': error?.runtimeType.toString(),
                  'timestamp': DateTime.now().toIso8601String(),
                }
              : null,
        });

        if (kDebugMode) {
          debugPrint('✅ Log written to database: $level - $message');
        }
      } catch (e) {
        // NEVER crash the app due to logging failures
        if (kDebugMode) {
          debugPrint('❌ Failed to log to database: $e');
          debugPrint('📊 Attempted log data: level=$level, message=$message');
        }
        // Silently continue - logging is optional
      }
    }).catchError((e) {
      // Extra safety net - catch any Future errors
      if (kDebugMode) {
        debugPrint('❌ Logging Future error: $e');
      }
    });
  }
}

/// Smart production filter - allows different log levels based on environment
class _SmartProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // ELON FIX: Enable all logs for PhonePe demo debugging
    return true; // Log everything in all modes for demo

    // TODO: Restore production filtering after PhonePe submission:
    // if (kDebugMode) {
    //   return true; // Log everything in debug mode
    // }
    // return event.level.index >= Level.warning.index;
  }
}

/// Smart pretty printer with structured output
class _SmartPrettyPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.defaultLevelColors[event.level];
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    final message = event.message;

    return [color!('$emoji $message')];
  }
}
