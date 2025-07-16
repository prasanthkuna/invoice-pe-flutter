import 'logger.dart';

/// Adapter for gradual migration from DebugService to new Logger
/// This allows existing code to work while we migrate
class DebugService {
  static bool _initialized = false;
  
  static void initialize() {
    if (_initialized) return;
    _initialized = true;
    Log.init();
  }
  
  static void logInfo(String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    Log.component('legacy').info(_extractOperation(message), {
      'message': message,
      ...?context,
      if (error != null) 'error': error.toString(),
    });
  }
  
  static void logDebug(String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    Log.component('legacy').debug(_extractOperation(message), {
      'message': message,
      if (error != null) 'error': error.toString(),
    });
  }
  
  static void logWarning(String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? operation,
  }) {
    Log.component('legacy').warn(
      operation ?? _extractOperation(message),
      {
        'message': message,
        ...?context,
      },
      suggestion: 'Check the warning context for potential issues',
    );
  }
  
  static void logError(String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
    String? operation,
  }) {
    Log.component('legacy').error(
      operation ?? _extractOperation(message),
      error: error ?? message,
      stackTrace: stackTrace,
      data: {
        'message': message,
        ...?context,
      },
    );
  }
  
  static void logAuth(String event, {
    Map<String, dynamic>? data,
    dynamic error,
    int? performanceMs,
  }) {
    final logger = Log.component('auth');
    
    if (error != null) {
      logger.error(event, 
        error: error,
        data: {
          ...?data,
          if (performanceMs != null) 'performance_ms': performanceMs,
        },
        suggestedFixes: [
          'Check network connectivity',
          'Verify auth credentials',
          'Check Supabase configuration',
        ],
      );
    } else {
      logger.info(event, {
        ...?data,
        if (performanceMs != null) 'performance_ms': performanceMs,
      });
    }
  }
  
  static void logDatabase(String operation, {
    String? table,
    Map<String, dynamic>? data,
    dynamic error,
    int? performanceMs,
  }) {
    final logger = Log.component('database');
    
    if (error != null) {
      logger.error(operation,
        error: error,
        data: {
          if (table != null) 'table': table,
          ...?data,
          if (performanceMs != null) 'performance_ms': performanceMs,
        },
        suggestedFixes: [
          'Check database connection',
          'Verify table exists: $table',
          'Check query syntax',
        ],
        relatedFiles: [
          'lib/core/services/base_service.dart',
          'supabase/migrations/',
        ],
      );
    } else {
      logger.info(operation, {
        if (table != null) 'table': table,
        ...?data,
        if (performanceMs != null) 'performance_ms': performanceMs,
      });
      
      // Log slow queries
      if (performanceMs != null && performanceMs > 1000) {
        logger.warn(operation, {
          'table': table,
          'performance_ms': performanceMs,
          'threshold_ms': 1000,
        }, suggestion: 'Consider adding indexes or optimizing query');
      }
    }
  }
  
  static void logApi(String method, String endpoint, {
    Map<String, dynamic>? data,
    dynamic error,
    int? statusCode,
  }) {
    final logger = Log.component('api');
    final operation = '${method.toLowerCase()}_${endpoint.replaceAll('/', '_')}';
    
    if (error != null) {
      logger.error(operation,
        error: error,
        data: {
          'method': method,
          'endpoint': endpoint,
          if (statusCode != null) 'status_code': statusCode,
          ...?data,
        },
        suggestedFixes: [
          'Check network connectivity',
          'Verify API endpoint: $endpoint',
          'Check authentication headers',
          if (statusCode == 401) 'Token may be expired - refresh auth',
          if (statusCode == 429) 'Rate limit exceeded - implement backoff',
        ],
      );
    } else {
      logger.info(operation, {
        'method': method,
        'endpoint': endpoint,
        if (statusCode != null) 'status_code': statusCode,
        ...?data,
      });
    }
  }
  
  static void logPayment(String event, {
    String? transactionId,
    double? amount,
    dynamic error,
    int? performanceMs,
  }) {
    final logger = Log.component('payment');
    
    if (error != null) {
      logger.error(event,
        error: error,
        data: {
          if (transactionId != null) 'transaction_id': transactionId,
          if (amount != null) 'amount': amount,
          if (performanceMs != null) 'performance_ms': performanceMs,
        },
        suggestedFixes: [
          'Check PhonePe SDK initialization',
          'Verify payment gateway configuration',
          'Check network connectivity',
          'Verify transaction amount is valid',
        ],
        relatedFiles: [
          'lib/core/services/payment_service.dart',
          'lib/core/types/payment_types.dart',
        ],
      );
    } else {
      logger.info(event, {
        if (transactionId != null) 'transaction_id': transactionId,
        if (amount != null) 'amount': amount,
        if (performanceMs != null) 'performance_ms': performanceMs,
      });
    }
  }
  
  static void logNavigation(String route, {Map<String, dynamic>? params}) {
    Log.component('navigation').info('route_change', {
      'route': route,
      ...?params,
    });
    
    // Add to breadcrumbs for error context
    Log.addBreadcrumb('nav:$route');
  }
  
  static void logUserAction(String action, {Map<String, dynamic>? context}) {
    Log.component('user').info(action, context ?? {});
    
    // Add to breadcrumbs
    Log.addBreadcrumb('user:$action');
  }
  
  static void logPerformance(String operation, Duration duration, {
    Map<String, dynamic>? metrics,
  }) {
    Log.component('performance').info(operation, {
      'duration_ms': duration.inMilliseconds,
      ...?metrics,
    });
  }
  
  static void logSecurity(String event, {
    Map<String, dynamic>? data,
    String? userId,
  }) {
    Log.component('security').info(event, {
      if (userId != null) 'user_id': userId,
      ...?data,
    });
  }
  
  static void logSecurityViolation(String violation, {
    Map<String, dynamic>? context,
    String? userId,
  }) {
    Log.component('security').error(
      violation,
      error: 'Security violation detected',
      data: {
        if (userId != null) 'user_id': userId,
        ...?context,
        'severity': 'CRITICAL',
      },
      suggestedFixes: [
        'Review security logs immediately',
        'Check for unauthorized access attempts',
        'Verify user permissions',
        'Consider blocking the user/IP',
      ],
    );
  }
  
  // Utility methods
  static String _extractOperation(String message) {
    // Try to extract operation from emoji messages
    if (message.contains('🚀')) return 'startup';
    if (message.contains('🔐')) return 'auth';
    if (message.contains('💳')) return 'payment';
    if (message.contains('🗄️')) return 'database';
    if (message.contains('🌐')) return 'api';
    if (message.contains('📱')) return 'mobile';
    if (message.contains('✅')) return 'success';
    if (message.contains('❌')) return 'failure';
    if (message.contains('⚠️')) return 'warning';
    
    // Extract first few words as operation
    final words = message.split(' ').take(3).join('_').toLowerCase();
    return words.replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }
  
  // Legacy compatibility
  static void setDatabaseLogging(bool enabled) {
    // No-op for compatibility
  }
  
  static String? get sessionId => null; // Deprecated
  
  static void logAuditTrail(String event, {
    String? userId,
    String? action,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
  }) {
    final logger = Log.component('audit');
    logger.info(event, {
      if (userId != null) 'user_id': userId,
      if (action != null) 'action': action,
      if (metadata != null) ...metadata,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (userAgent != null) 'user_agent': userAgent,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
