import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/logger.dart';
import '../services/smart_logger.dart';  // ELON FIX: Add SmartLogger import

final ComponentLogger _log = Log.component('error');

/// Tesla-grade error handler - consistent error handling across app
class ErrorHandler {
  /// Handle async operations with automatic error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    required BuildContext context,
    String? errorMessage,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } catch (error, stack) {
      // ELON FIX: Enhanced error logging with complete context
      SmartLogger.logError(
        errorMessage ?? 'Async Operation Failed',
        error: error,
        stackTrace: stack,
        context: {
          'error_type': 'async_operation',
          'operation': 'handleAsync',
        },
      );

      // Also log with existing logger for compatibility
      _log.error(
        errorMessage ?? 'Operation failed',
        error: error,
        stackTrace: stack,
      );

      if (showError && context.mounted) {
        _showErrorSnackBar(
          context,
          _sanitizeErrorMessage(error, errorMessage),
        );
      }
      return null;
    }
  }

  /// Show error snackbar with consistent styling
  static void showError(BuildContext context, String message) {
    if (!context.mounted) return;
    _showErrorSnackBar(context, message);
  }

  /// Show success snackbar with consistent styling
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Private helper to show error snackbar
  static void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Sanitize error messages to avoid exposing sensitive info
  static String _sanitizeErrorMessage(dynamic error, String? fallback) {
    final errorStr = error.toString().toLowerCase();

    // Never expose these in error messages
    if (errorStr.contains('key') ||
        errorStr.contains('secret') ||
        errorStr.contains('token') ||
        errorStr.contains('password')) {
      return fallback ?? 'An error occurred. Please try again.';
    }

    // Common error patterns
    if (errorStr.contains('network')) {
      return 'Network error. Please check your connection.';
    }

    if (errorStr.contains('permission')) {
      return 'Permission denied. Please check your access.';
    }

    return fallback ?? 'An error occurred. Please try again.';
  }
}
