import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/types/auth_types.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigationCompleted = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatusSafely();
    });
  }

  /// Tesla-grade auth check with atomic navigation - MAIN THREAD OPTIMIZED
  Future<void> _checkAuthStatusSafely() async {
    if (!mounted || _navigationCompleted) return;

    try {
      // ATOMIC CHECK: Get current user directly (fast, cached)
      final currentUser = AuthService.getCurrentUser();

      if (currentUser != null) {
        // User is authenticated - DEFER profile check to avoid blocking main thread
        await _navigateToDashboard();

        // TESLA FIX: Check profile status in background after navigation
        _checkProfileStatusInBackground();
      } else {
        // No current user - try to restore session (fast, cached)
        final sessionRestored = await AuthService.restoreSession();

        if (!mounted || _navigationCompleted) return;

        if (sessionRestored) {
          // Session restored, go to dashboard immediately
          await _navigateToDashboard();
        } else {
          await _navigateToAuth('No valid session');
        }
      }
    } catch (e) {
      // Fail-safe: any error goes to auth
      await _navigateToAuth('Auth check failed: $e');
    }
  }

  /// Background profile check - doesn't block main thread
  void _checkProfileStatusInBackground() {
    // Run in background without blocking UI
    Future.microtask(() async {
      try {
        final profileStatus = await AuthService.checkProfileStatus();

        if (!mounted || _navigationCompleted) return;

        // Only redirect if profile is incomplete
        if (profileStatus is ProfileIncomplete) {
          if (mounted && context.mounted) {
            context.go('/setup-profile');
          }
        }
      } catch (e) {
        // Profile check failed - user can still use the app
        if (kDebugMode) {
          debugPrint('Background profile check failed: $e');
        }
      }
    });
  }

  // Removed unused _handleAuthLoading method

  /// Atomic navigation to dashboard
  Future<void> _navigateToDashboard() async {
    if (!mounted || _navigationCompleted) return;
    _navigationCompleted = true;
    context.go('/dashboard');
  }

  // Removed unused _navigateToProfileSetup method

  /// Atomic navigation to auth
  Future<void> _navigateToAuth(String reason) async {
    if (!mounted || _navigationCompleted) return;
    _navigationCompleted = true;

    if (kDebugMode) {
      debugPrint('🔐 Navigating to auth: $reason');
    }

    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.receipt_long,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 32),

            // App Name
            const Text(
              'InvoicePe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Smart Invoice Management',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.secondaryText,
              ),
            ),

            const SizedBox(height: 48),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
            ),
          ],
        ),
      ),
    );
  }
}
