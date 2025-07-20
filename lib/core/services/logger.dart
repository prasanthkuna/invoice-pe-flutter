import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tesla-grade logger: Structured, searchable, AI-friendly
/// "Make it work, make it right, make it fast" - in that order
class Log {
  Log._internal();
  static final _instance = Log._internal();
  static Log get instance => _instance;

  // Component loggers cache
  static final Map<String, ComponentLogger> _componentLoggers = {};

  // Configuration
  static bool _initialized = false;
  static LogConfig _config = LogConfig();

  // Performance tracking
  static final Map<String, DateTime> _timers = {};

  // Request tracking
  static String? _currentCorrelationId;
  static final List<String> _breadcrumbs = [];

  /// Initialize logger with zero config
  static void init([LogConfig? config]) {
    if (_initialized) return;

    _config = config ?? LogConfig.autoDetect();
    _initialized = true;

    // Log initialization
    component('logger').info('initialized', {
      'environment': _config.environment,
      'level': _config.level.toString(),
      'output': _config.output.toString(),
    });
  }

  /// Get component-specific logger
  static ComponentLogger component(String name) {
    return _componentLoggers.putIfAbsent(
      name,
      () => ComponentLogger(name),
    );
  }

  /// Start performance timer
  static Timer startTimer(String operation) {
    final id = '${operation}_${DateTime.now().millisecondsSinceEpoch}';
    _timers[id] = DateTime.now();
    return Timer(id, operation);
  }

  /// Add breadcrumb for error context
  static void addBreadcrumb(String breadcrumb) {
    _breadcrumbs.add(breadcrumb);
    if (_breadcrumbs.length > 20) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// Set correlation ID for request tracking
  static void setCorrelationId(String id) {
    _currentCorrelationId = id;
  }

  /// Clear correlation context
  static void clearContext() {
    _currentCorrelationId = null;
    _breadcrumbs.clear();
  }

  /// Get current user ID
  static String? get _userId {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }
}

/// Component-specific logger
class ComponentLogger {
  ComponentLogger(this.component);
  final String component;

  void trace(String operation, [Map<String, dynamic>? data]) {
    _log(LogLevel.trace, operation, data);
  }

  void debug(String operation, [Map<String, dynamic>? data]) {
    _log(LogLevel.debug, operation, data);
  }

  void info(String operation, [Map<String, dynamic>? data]) {
    _log(LogLevel.info, operation, data);
  }

  void warn(
    String operation,
    Map<String, dynamic> data, {
    String? suggestion,
    List<String>? possibleCauses,
  }) {
    _log(LogLevel.warn, operation, {
      ...data,
      if (suggestion != null) 'suggestion': suggestion,
      if (possibleCauses != null) 'possible_causes': possibleCauses,
    });
  }

  void error(
    String operation, {
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
    List<String>? suggestedFixes,
    List<String>? relatedFiles,
  }) {
    _log(LogLevel.error, operation, {
      ...?data,
      'error': _extractError(error),
      if (stackTrace != null) 'stack_trace': _extractStackTrace(stackTrace),
      if (suggestedFixes != null) 'suggested_fixes': suggestedFixes,
      if (relatedFiles != null) 'related_files': relatedFiles,
    });
  }

  void fatal(
    String operation, {
    required dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.fatal, operation, {
      ...?data,
      'error': _extractError(error),
      if (stackTrace != null) 'stack_trace': _extractStackTrace(stackTrace),
      'requires_immediate_attention': true,
    });
  }

  void _log(LogLevel level, String operation, Map<String, dynamic>? data) {
    if (level.index < Log._config.level.index) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      component: component,
      operation: operation,
      correlationId: Log._currentCorrelationId,
      userId: Log._userId,
      data: data ?? {},
      breadcrumbs: List.from(Log._breadcrumbs),
      context: _getContext(),
    );

    _output(entry);
  }

  Map<String, dynamic> _getContext() {
    // Get caller information (would need stack trace parsing in production)
    final trace = StackTrace.current.toString().split('\n');
    String? file;
    int? line;
    String? function;

    // Find the first non-logger frame
    for (final frame in trace) {
      if (!frame.contains('logger.dart') &&
          !frame.contains('component_logger.dart') &&
          frame.contains('.dart')) {
        final match = RegExp(r'(\S+\.dart):(\d+):(\d+)').firstMatch(frame);
        if (match != null) {
          file = match.group(1);
          line = int.tryParse(match.group(2) ?? '');

          // Extract function name
          final funcMatch = RegExp(r'\.(\w+)\s*\(').firstMatch(frame);
          if (funcMatch != null) {
            function = funcMatch.group(1);
          }
          break;
        }
      }
    }

    return {
      if (file != null) 'file': file,
      if (line != null) 'line': line,
      if (function != null) 'function': function,
      'environment': Log._config.environment,
    };
  }

  void _output(LogEntry entry) {
    switch (Log._config.output) {
      case LogOutput.console:
        _outputConsole(entry);
      case LogOutput.json:
        _outputJson(entry);
      case LogOutput.pretty:
        _outputPretty(entry);
    }
  }

  void _outputConsole(LogEntry entry) {
    final message =
        '[${entry.level.name.toUpperCase()}] '
        '${entry.component}.${entry.operation}';

    if (kDebugMode) {
      switch (entry.level) {
        case LogLevel.trace:
        case LogLevel.debug:
          debugPrint(message);
        case LogLevel.info:
          debugPrint('\x1B[32m$message\x1B[0m'); // Green
        case LogLevel.warn:
          debugPrint('\x1B[33m$message\x1B[0m'); // Yellow
        case LogLevel.error:
        case LogLevel.fatal:
          debugPrint('\x1B[31m$message\x1B[0m'); // Red
      }

      if (entry.data.isNotEmpty) {
        debugPrint('  Data: ${json.encode(entry.data)}');
      }
    } else {
      print(json.encode(entry.toJson()));
    }
  }

  void _outputJson(LogEntry entry) {
    print(json.encode(entry.toJson()));
  }

  void _outputPretty(LogEntry entry) {
    final buffer = StringBuffer();

    // Header with color
    final color = switch (entry.level) {
      LogLevel.trace => '\x1B[90m', // Gray
      LogLevel.debug => '\x1B[36m', // Cyan
      LogLevel.info => '\x1B[32m', // Green
      LogLevel.warn => '\x1B[33m', // Yellow
      LogLevel.error => '\x1B[31m', // Red
      LogLevel.fatal => '\x1B[35m', // Magenta
    };

    buffer.writeln(
      '$color━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1B[0m',
    );
    buffer.writeln(
      '$color${entry.level.name.toUpperCase()}\x1B[0m ${entry.component}.${entry.operation}',
    );
    buffer.writeln('Time: ${entry.timestamp.toIso8601String()}');

    if (entry.correlationId != null) {
      buffer.writeln('Correlation: ${entry.correlationId}');
    }

    if (entry.context['file'] != null) {
      buffer.writeln(
        'Location: ${entry.context['file']}:${entry.context['line']} in ${entry.context['function']}()',
      );
    }

    if (entry.data.isNotEmpty) {
      buffer.writeln('Data:');
      _prettyPrintMap(entry.data, buffer, '  ');
    }

    if (entry.breadcrumbs.isNotEmpty) {
      buffer.writeln('Breadcrumbs:');
      for (final crumb in entry.breadcrumbs) {
        buffer.writeln('  → $crumb');
      }
    }

    buffer.writeln(
      '$color━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\x1B[0m',
    );

    print(buffer);
  }

  void _prettyPrintMap(
    Map<String, dynamic> map,
    StringBuffer buffer,
    String indent,
  ) {
    map.forEach((key, value) {
      if (value is Map) {
        buffer.writeln('$indent$key:');
        _prettyPrintMap(value as Map<String, dynamic>, buffer, '$indent  ');
      } else if (value is List) {
        buffer.writeln('$indent$key: [');
        for (final item in value) {
          buffer.writeln('$indent  - $item');
        }
        buffer.writeln('$indent]');
      } else {
        buffer.writeln('$indent$key: $value');
      }
    });
  }

  Map<String, dynamic> _extractError(dynamic error) {
    if (error == null) return {'type': 'null', 'message': 'No error'};

    return {
      'type': error.runtimeType.toString(),
      'message': error.toString(),
      if (error is Exception) 'exception': true,
      if (error is Error) 'error': true,
    };
  }

  Map<String, dynamic> _extractStackTrace(StackTrace stackTrace) {
    final frames = stackTrace.toString().split('\n').take(10).toList();
    return {
      'frames': frames,
      'top_frame': frames.isNotEmpty ? frames.first : null,
    };
  }
}

/// Performance timer
class Timer {
  Timer(this.id, this.operation);
  final String id;
  final String operation;

  void end([Map<String, dynamic>? data]) {
    final start = Log._timers.remove(id);
    if (start == null) return;

    final duration = DateTime.now().difference(start);

    Log.component('performance').info(operation, {
      ...?data,
      'duration_ms': duration.inMilliseconds,
      'duration_human': _formatDuration(duration),
    });
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
  }
}

/// Log entry data structure
class LogEntry {
  LogEntry({
    required this.timestamp,
    required this.level,
    required this.component,
    required this.operation,
    required this.data,
    required this.breadcrumbs,
    required this.context,
    this.correlationId,
    this.userId,
  });
  final DateTime timestamp;
  final LogLevel level;
  final String component;
  final String operation;
  final String? correlationId;
  final String? userId;
  final Map<String, dynamic> data;
  final List<String> breadcrumbs;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'component': component,
    'operation': operation,
    if (correlationId != null) 'correlation_id': correlationId,
    if (userId != null) 'user_id': userId,
    'data': data,
    if (breadcrumbs.isNotEmpty) 'breadcrumbs': breadcrumbs,
    'context': context,
  };
}

/// Log levels
enum LogLevel { trace, debug, info, warn, error, fatal }

/// Log output format
enum LogOutput { console, json, pretty }

/// Logger configuration
class LogConfig {
  LogConfig({
    this.level = LogLevel.info,
    this.output = LogOutput.pretty,
    this.environment = 'development',
  });

  /// Auto-detect configuration based on environment
  factory LogConfig.autoDetect() {
    if (kReleaseMode) {
      return LogConfig(
        level: LogLevel.info,
        output: LogOutput.json,
        environment: 'production',
      );
    } else if (kProfileMode) {
      return LogConfig(
        level: LogLevel.debug,
        output: LogOutput.json,
        environment: 'profile',
      );
    } else {
      return LogConfig(
        level: LogLevel.trace,
        output: LogOutput.pretty,
        environment: 'development',
      );
    }
  }
  final LogLevel level;
  final LogOutput output;
  final String environment;
}
