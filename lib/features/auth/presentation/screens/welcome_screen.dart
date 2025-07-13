import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBackground,
              AppTheme.cardBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo and Title
                Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryAccent,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryAccent.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.payment,
                        size: 60,
                        color: Colors.white,
                      ),
                    ).animate().scale(delay: 300.ms, duration: 600.ms),

                    const SizedBox(height: 32),

                    Text(
                      'InvoicePe',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

                    const SizedBox(height: 16),

                    Text(
                      'Pay ANY vendor with your credit card\nEarn rewards while they get instant transfers',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.secondaryText,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),
                  ],
                ),

                const Spacer(flex: 3),

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.5),

                const SizedBox(height: 24),

                // Terms and Privacy
                Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText.withValues(alpha: 0.7),
                  ),
                ).animate().fadeIn(delay: 1500.ms),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
