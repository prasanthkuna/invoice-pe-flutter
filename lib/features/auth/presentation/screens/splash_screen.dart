import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Enhanced session restoration with proper timing
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      try {
        // Try to restore session first
        final sessionRestored = await AuthService.restoreSession();

        // Wait a bit more for auth state to propagate
        await Future<void>.delayed(const Duration(milliseconds: 1000));

        if (mounted) {
          final isAuthenticated = ref.read(isAuthenticatedProvider);
          if (isAuthenticated || sessionRestored) {
            context.go('/dashboard');
          } else {
            context.go('/auth');
          }
        }
      } catch (e) {
        // If session restoration fails, go to auth
        if (mounted) {
          context.go('/auth');
        }
      }
    }
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
