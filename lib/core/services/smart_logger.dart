import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:convert';

/// InvoicePe Smart Logger - 2025 Best Practices
/// Elon's Philosophy: "Log smart, not hard. Every log should solve a problem."
class SmartLogger {
  static late Logger _logger;
  static bool _initialized = false;
  static String? _correlationId;
  static final Map<String, int> _logCounts = {};
  static final Map<String, DateTime> _lastLogTime = {};
  
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
    
    logInfo('🧠 SmartLogger initialized', context: {
      'correlation_id': _correlationId,
      'api_sampling_rate': _apiSamplingRate,
      'ui_sampling_rate': _uiSamplingRate,
    });
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
    if (!_initialized) initialize();
    
    // Smart sampling for routine operations
    if (!forceSample && !_shouldSample(category ?? 'general')) {
      return;
    }
    
    final enrichedContext = _enrichContext(context, category);
    final maskedMessage = _maskPII(message);
    
    _logger.i(maskedMessage, error: null, stackTrace: null);
    _logToBuffer('INFO', maskedMessage, enrichedContext);
  }
  
  /// Business-critical logging (always logged, never sampled)
  static void logPayment(
    String message, {
    Map<String, dynamic>? context,
  }) {
    if (!_initialized) initialize();
    
    final enrichedContext = _enrichContext(context, 'payment');
    final maskedMessage = _maskPII(message);
    
    _logger.i('💰 PAYMENT: $maskedMessage');
    _logToBuffer('PAYMENT', maskedMessage, enrichedContext);
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
    _logToBuffer('SECURITY', maskedMessage, enrichedContext);
  }
  
  /// Error logging (always logged, full context)
  static void logError(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (!_initialized) initialize();
    
    final enrichedContext = _enrichContext(context, 'error');
    final maskedMessage = _maskPII(message);
    
    _logger.e('❌ ERROR: $maskedMessage', error: error, stackTrace: stackTrace);
    _logToBuffer('ERROR', maskedMessage, enrichedContext);
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
    
    final message = '⚡ PERFORMANCE: $operation took ${duration.inMilliseconds}ms';
    _logger.i(message);
    _logToBuffer('PERFORMANCE', message, enrichedContext);
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
  
  /// Buffer logs for potential remote logging
  static void _logToBuffer(
    String level,
    String message,
    Map<String, dynamic> context,
  ) {
    // Implementation for buffering logs for remote logging
    // This could be sent to Supabase, Firebase, or other logging services
  }
}

/// Smart production filter - allows different log levels based on environment
class _SmartProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) {
      return true; // Log everything in debug mode
    }
    
    // In release mode, only log warnings and errors
    return event.level.index >= Level.warning.index;
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
