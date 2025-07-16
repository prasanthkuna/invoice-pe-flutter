import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tesla-grade navigation utility - prevents all navigation crashes
class NavigationHelper {
  /// Safe pop with navigation stack check
  static void safePop(BuildContext context, [dynamic result]) {
    if (!context.mounted) return;

    final router = GoRouter.of(context);

    if (router.canPop()) {
      context.pop(result);
    } else {
      // Get current location
      final currentLocation =
          router.routerDelegate.currentConfiguration.fullPath;

      // Only go to dashboard if not already there
      if (currentLocation != '/dashboard') {
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
}
