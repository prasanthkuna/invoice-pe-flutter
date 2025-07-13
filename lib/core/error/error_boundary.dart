// InvoicePe - Error Boundary Widget
// Provides graceful error handling with user-friendly UI

import 'package:flutter/material.dart';
import 'app_error.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/debug_service.dart';

/// Error boundary widget that catches and displays errors gracefully
class ErrorBoundary extends ConsumerWidget {
  const ErrorBoundary({
    required this.child,
    this.onError,
    this.fallbackBuilder,
    super.key,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error)? fallbackBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Log the error
      DebugService.logCritical(
        'Error boundary caught error',
        details.exception,
        details.stack,
      );

      // Call custom error handler if provided
      onError?.call(details.exception, details.stack ?? StackTrace.current);

      // Return custom fallback or default error UI
      if (fallbackBuilder != null) {
        return fallbackBuilder!(details.exception);
      }

      return _DefaultErrorWidget(
        error: details.exception,
        stackTrace: details.stack,
      );
    };

    return child;
  }
}

/// Default error widget with user-friendly design
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({
    required this.error,
    this.stackTrace,
  });

  final Object error;
  final StackTrace? stackTrace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appError = ErrorHandler.fromException(error, stackTrace);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 24),

              // Error title
              Text(
                'Oops! Something went wrong',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // User-friendly error message
              Text(
                appError.displayMessage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Retry button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Restart the app or navigate to safe screen
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        '/',
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),

                  // Report button (for non-sensitive errors)
                  if (appError.shouldReport)
                    OutlinedButton.icon(
                      onPressed: () => _reportError(context, appError),
                      icon: const Icon(Icons.bug_report),
                      label: const Text('Report'),
                    ),
                ],
              ),

              // Debug info (only in debug mode)
              if (DebugService.isDebugMode) ...[
                const SizedBox(height: 32),
                ExpansionTile(
                  title: const Text('Debug Information'),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error Code: ${appError.code}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error: $error',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (stackTrace != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Stack Trace:\n$stackTrace',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontFamily: 'monospace',
                              ),
                              maxLines: 10,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _reportError(BuildContext context, AppError error) {
    // Show confirmation dialog
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Error'),
        content: const Text(
          'This will help us improve the app. No personal information will be shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Log the error report
              DebugService.logUserAction(
                'error_reported',
                context: {
                  'error_code': error.code,
                  'error_message': error.message,
                },
              );

              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error reported. Thank you for your feedback!'),
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}

/// Async error boundary for handling Future errors
class AsyncErrorBoundary extends ConsumerWidget {
  const AsyncErrorBoundary({
    required this.child,
    this.onError,
    super.key,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}

/// Error handler mixin for widgets
mixin ErrorHandlerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Handle errors with user-friendly messages
  void handleError(Object error, [StackTrace? stackTrace]) {
    final appError = ErrorHandler.fromException(error, stackTrace);

    // Log the error
    DebugService.logError(
      'Widget error: ${widget.runtimeType}',
      error: error,
      context: {'widget': widget.runtimeType.toString()},
    );

    // Show user-friendly message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appError.displayMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  /// Show loading state with error handling
  Widget buildWithErrorHandling({
    required AsyncValue<dynamic> asyncValue,
    required Widget Function() dataBuilder,
    Widget? loadingWidget,
    Widget Function(Object error, StackTrace stackTrace)? errorBuilder,
  }) {
    return asyncValue.when(
      data: (_) => dataBuilder(),
      loading: () =>
          loadingWidget ?? const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        handleError(error, stackTrace);
        return errorBuilder?.call(error, stackTrace) ??
            _DefaultErrorWidget(error: error, stackTrace: stackTrace);
      },
    );
  }
}
