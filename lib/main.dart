import 'dart:async';
import 'dart:ui';  // ELON FIX: Add for PlatformDispatcher
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/app_providers.dart';
import 'core/services/logger.dart';
import 'core/services/environment_service.dart';
import 'core/services/smart_logger.dart';  // ELON FIX: Add SmartLogger import

/// Tesla-grade main function with fail-fast initialization
void main() async {
  // Wrap everything in error boundary for production safety
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ELON FIX: Add missing platform error handler for async/platform errors
    PlatformDispatcher.instance.onError = (error, stack) {
      SmartLogger.logError(
        'Platform/Async Error',
        error: error,
        stackTrace: stack,
        context: {
          'error_type': 'platform_async',
          'runtime_type': error.runtimeType.toString(),
        },
      );
      return true; // Error handled, don't crash
    };

    // Initialize logging first for error tracking
    Log.init();

    try {
      // PHASE 1: Critical environment setup with validation - MAIN THREAD OPTIMIZED
      await EnvironmentService.initialize();

      // Validate configuration immediately after environment load (fast, in-memory)
      AppConstants.validateConfiguration();

      // PHASE 2: Initialize Supabase with timeout to prevent hanging
      Log.component('app').info('Starting Supabase initialization...');

      // TESLA FIX: Use microtask to prevent blocking main thread during Supabase init
      await Future.microtask(() async {
        await Future.any([
          Supabase.initialize(
            url: AppConstants.supabaseUrl,
            anonKey: AppConstants.supabaseAnonKey,
            debug: AppConstants.debugMode,
          ),
          Future.delayed(
            const Duration(seconds: 10),
            () => throw TimeoutException('Supabase initialization timeout'),
          ),
        ]);
      });

      Log.component('app').info('Supabase initialization completed');

      // PHASE 3: Launch UI with error boundary - BACK TO FULL APP
      runApp(
        ProviderScope(
          child: _AppErrorBoundary(
            child: const InvoicePeApp(),
          ),
        ),
      );

      // DEFERRED: Non-critical initialization after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _deferredInitialization();
      });

    } catch (error, stackTrace) {
      // Critical startup failure - show error screen
      Log.component('app').error('Critical startup failure',
        error: error,
        stackTrace: stackTrace
      );

      runApp(
        MaterialApp(
          home: _StartupErrorScreen(error: error.toString()),
          debugShowCheckedModeBanner: false,
        ),
      );
    }
  }, (error, stackTrace) {
    // ELON FIX: Enhanced uncaught exception handler with SmartLogger
    SmartLogger.logError(
      'Uncaught Exception',
      error: error,
      stackTrace: stackTrace,
      context: {
        'error_type': 'uncaught_exception',
        'runtime_type': error.runtimeType.toString(),
      },
    );

    // Also log with existing logger for compatibility
    Log.component('app').error('Uncaught exception',
      error: error,
      stackTrace: stackTrace
    );

    // In debug mode, crash. In release mode, log and continue.
    if (kDebugMode) {
      throw error;
    }
  });
}



/// Deferred initialization for non-critical services
Future<void> _deferredInitialization() async {
  try {
    // Log successful startup
    Log.component('app').info('startup_complete', {
      'environment': AppConstants.environment,
      'debug_mode': AppConstants.debugMode,
      'version': 'v1.0.0',
      'env_status': EnvironmentService.getStatus(),
    });

    // Add breadcrumb for tracking
    Log.addBreadcrumb('app.main.deferred_init_complete');

    // PhonePe initialization is deferred to first payment
    // This saves ~500ms on startup and improves perceived performance
  } catch (error) {
    Log.component('app').error('Deferred initialization failed', error: error);
    // Don't crash app for non-critical failures
  }
}

/// Main app widget with Tesla-grade error handling
class InvoicePeApp extends ConsumerWidget {
  const InvoicePeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final isDarkMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme Configuration (UX Requirements)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // Router Configuration (TRD Requirements)
      routerConfig: router,
    );
  }
}

/// Error boundary widget to catch and handle widget errors
class _AppErrorBoundary extends StatefulWidget {
  const _AppErrorBoundary({required this.child});

  final Widget child;

  @override
  State<_AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<_AppErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        home: _ErrorScreen(
          error: _error.toString(),
          stackTrace: _stackTrace.toString(),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    return widget.child;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ELON FIX: Enhanced widget error handler with complete logging
    FlutterError.onError = (FlutterErrorDetails details) {
      SmartLogger.logError(
        'Widget Error (App Boundary)',
        error: details.exception,
        stackTrace: details.stack,
        context: {
          'library': details.library,
          'context': details.context?.toString(),
          'silent': details.silent,
          'error_type': 'widget_app_boundary',
        },
      );

      // Also log with existing logger for compatibility
      Log.component('app').error('Widget error caught by boundary',
        error: details.exception,
        stackTrace: details.stack,
      );

      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
    };
  }
}

/// Startup error screen for critical initialization failures
class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101213),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFFF453A),
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Startup Failed',
                style: TextStyle(
                  color: Color(0xFFF1F1F1),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The app failed to initialize properly. Please check your configuration.',
                style: TextStyle(
                  color: const Color(0xFFA8A8A8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: Color(0xFFFF453A),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: main,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF338DFF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Runtime error screen for widget errors
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({
    required this.error,
    required this.stackTrace,
  });

  final String error;
  final String stackTrace;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101213),
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: const Color(0xFF1A1D1E),
        foregroundColor: const Color(0xFFF1F1F1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An error occurred:',
              style: TextStyle(
                color: Color(0xFFF1F1F1),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1D1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        error,
                        style: const TextStyle(
                          color: Color(0xFFFF453A),
                          fontSize: 14,
                        ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Stack Trace:',
                          style: TextStyle(
                            color: Color(0xFFF1F1F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stackTrace,
                          style: const TextStyle(
                            color: Color(0xFFA8A8A8),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Removed unused _ElonMinimalApp class
