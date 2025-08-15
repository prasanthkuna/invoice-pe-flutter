import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ELON-GRADE navigation utility - impossible to crash navigation
class NavigationHelper {
  /// ELON PATTERN: Intelligent back navigation with context-aware fallbacks
  static void safePop(BuildContext context, [dynamic result]) {
    if (!context.mounted) return;

    final router = GoRouter.of(context);

    if (router.canPop()) {
      context.pop(result);
    } else {
      // ELON FIX: Smart fallback based on current route context
      final currentLocation = router.routerDelegate.currentConfiguration.fullPath;
      
      if (currentLocation.contains('/transactions/')) {
        context.go('/transactions');
      } else if (currentLocation.contains('/invoices/')) {
        context.go('/invoices');
      } else if (currentLocation.contains('/vendors/')) {
        context.go('/vendors');
      } else if (currentLocation != '/dashboard') {
        context.go('/dashboard');
      }
    }
  }

  /// Safe push with mounted check
  static Future<T?> safePush<T>(
    BuildContext context,
    String path, {
    Object? extra,
  }) async {
    if (!context.mounted) return null;
    return context.push<T>(path, extra: extra);
  }

  /// Safe go with mounted check
  static void safeGo(BuildContext context, String path, {Object? extra}) {
    if (!context.mounted) return;
    context.go(path, extra: extra);
  }

  /// Check if can pop before showing back button
  static bool canPop(BuildContext context) {
    if (!context.mounted) return false;
    return GoRouter.of(context).canPop();
  }

  /// ELON PATTERN: Smart navigation - automatically chooses push vs go
  static void navigateSmart(BuildContext context, String toRoute, {Object? extra}) {
    if (!context.mounted) return;
    
    // Detail routes should use push to maintain navigation stack
    if (_isDetailRoute(toRoute)) {
      safePush(context, toRoute, extra: extra);
    } else {
      // Flow routes use go to replace navigation stack
      safeGo(context, toRoute, extra: extra);
    }
  }

  /// Detect if route is a detail screen that should maintain stack
  static bool _isDetailRoute(String route) {
    return route.contains(RegExp(r'/(transactions|invoices|vendors|cards)/[^/]+$'));
  }
}
