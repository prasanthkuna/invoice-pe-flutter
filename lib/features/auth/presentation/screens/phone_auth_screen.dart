import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/types/auth_types.dart' as app_auth;
import '../../../../core/types/result.dart';
import '../../../../core/theme/app_theme.dart';

final phoneControllerProvider = StateProvider<TextEditingController>((ref) {
  return TextEditingController();
});

final otpControllerProvider = StateProvider<TextEditingController>((ref) {
  return TextEditingController();
});

final phoneFocusNodeProvider = StateProvider<FocusNode>((ref) {
  return FocusNode();
});

final isLoadingProvider = StateProvider<bool>((ref) => false);
final showOtpFieldProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-focus phone input when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(phoneFocusNodeProvider).requestFocus();
    });
  }

  @override
  void dispose() {
    ref.read(phoneControllerProvider).dispose();
    ref.read(otpControllerProvider).dispose();
    ref.read(phoneFocusNodeProvider).dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phoneController = ref.watch(phoneControllerProvider);
    final otpController = ref.watch(otpControllerProvider);
    final phoneFocusNode = ref.watch(phoneFocusNodeProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final showOtpField = ref.watch(showOtpFieldProvider);
    final errorMessage = ref.watch(errorMessageProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo and Title - NEW THEME
              Text(
                'InvoicePe',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryAccent,
                ),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),
              const SizedBox(height: 8),
              Text(
                'Smart Business Payments',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.secondaryText,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 80),

              // Welcome Text - FIXED: Remove duplicate welcome message
              Text(
                showOtpField ? 'Verify OTP' : 'Sign In',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: -0.3),
              const SizedBox(height: 8),
              Text(
                showOtpField
                    ? 'Enter the 6-digit code sent to your phone'
                    : 'Enter your phone number to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.secondaryText,
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 40),

              // Phone Number Field - FIXED KEYBOARD + NEW THEME
              if (!showOtpField) ...[
                TextField(
                  controller: phoneController,
                  focusNode: phoneFocusNode,
                  autofocus: true, // KEYBOARD FIX: Auto-focus
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: AppTheme.secondaryText),
                    prefixText: '+91 ',
                    prefixStyle: TextStyle(
                      color: AppTheme.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.primaryAccent,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.secondaryText.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),
              ],

              // OTP Field - NEW THEME + AUTO-FOCUS
              if (showOtpField) ...[
                TextField(
                  controller: otpController,
                  autofocus: true, // KEYBOARD FIX: Auto-focus OTP field
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: 'Enter 6-digit OTP',
                    labelStyle: TextStyle(color: AppTheme.secondaryText),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.primaryAccent,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: AppTheme.secondaryText.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _resendOtp(context, ref),
                  child: Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],

              const SizedBox(height: 24),

              // Error Message - NEW THEME
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().shake(delay: 100.ms),
                const SizedBox(height: 24),
              ],

              // Continue Button - NEW THEME
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => _handleContinue(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    foregroundColor: AppTheme.primaryBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: AppTheme.primaryAccent.withValues(alpha: 0.3),
                  ),
                  child: isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBackground,
                            ),
                          ),
                        )
                      : Text(
                          showOtpField ? 'Verify & Continue' : 'Send OTP',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),

              const Spacer(),

              // Terms and Privacy - NEW THEME
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryText,
                ),
              ).animate().fadeIn(delay: 1400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue(BuildContext context, WidgetRef ref) async {
    final phoneController = ref.read(phoneControllerProvider);
    final otpController = ref.read(otpControllerProvider);
    final showOtpField = ref.read(showOtpFieldProvider);

    ref.read(isLoadingProvider.notifier).state = true;
    ref.read(errorMessageProvider.notifier).state = null;

    try {
      if (!showOtpField) {
        // Send OTP
        final phone = '+91${phoneController.text.trim()}';
        if (phone.length < 13) {
          throw Exception('Please enter a valid phone number');
        }

        final otpResult = await AuthService.sendOtpSmart(phone);

        switch (otpResult) {
          case app_auth.OtpSent(message: final message):
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: const Color(0xFF00D4FF),
                ),
              );
              // Navigate to OTP screen with phone number
              context.push('/otp', extra: phone);
            }
          case app_auth.OtpFailed(error: final error):
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: Colors.red,
                ),
              );
            }
        }
      } else {
        // Verify OTP
        final phone = '+91${phoneController.text.trim()}';
        final otp = otpController.text.trim();

        if (otp.length != 6) {
          throw Exception('Please enter a valid 6-digit OTP');
        }

        final result = await AuthService.verifyOtp(phone: phone, otp: otp);

        switch (result) {
          case Success():
            if (context.mounted) {
              context.go('/dashboard');
            }
          case Failure(error: final error):
            throw Exception(error);
        }
      }
    } catch (error) {
      if (context.mounted) {
        ref.read(errorMessageProvider.notifier).state = error.toString();
      }
    } finally {
      if (context.mounted) {
        ref.read(isLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _resendOtp(BuildContext context, WidgetRef ref) async {
    final phoneController = ref.read(phoneControllerProvider);
    final phone = '+91${phoneController.text.trim()}';

    try {
      await AuthService.sendOtpSmart(phone);
      ref.read(errorMessageProvider.notifier).state = null;
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: Color(0xFF00D4FF),
          ),
        );
      }
    } catch (error) {
      ref.read(errorMessageProvider.notifier).state =
          'Failed to resend OTP: $error';
    }
  }


}
