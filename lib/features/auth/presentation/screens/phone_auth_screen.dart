import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/types/auth_types.dart' as app_auth;
import '../../../../core/types/result.dart';

final phoneControllerProvider = StateProvider<TextEditingController>((ref) {
  return TextEditingController();
});

final otpControllerProvider = StateProvider<TextEditingController>((ref) {
  return TextEditingController();
});

final isLoadingProvider = StateProvider<bool>((ref) => false);
final showOtpFieldProvider = StateProvider<bool>((ref) => false);
final errorMessageProvider = StateProvider<String?>((ref) => null);

class PhoneAuthScreen extends ConsumerWidget {
  const PhoneAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneController = ref.watch(phoneControllerProvider);
    final otpController = ref.watch(otpControllerProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final showOtpField = ref.watch(showOtpFieldProvider);
    final errorMessage = ref.watch(errorMessageProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // Logo and Title
              const Text(
                'InvoicePe',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D4FF),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Smart Invoice Management',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF888888),
                ),
              ),

              const SizedBox(height: 80),

              // Welcome Text
              Text(
                showOtpField ? 'Verify OTP' : 'Welcome Back',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                showOtpField
                    ? 'Enter the 6-digit code sent to your phone'
                    : 'Enter your phone number to continue',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF888888),
                ),
              ),

              const SizedBox(height: 40),

              // Phone Number Field
              if (!showOtpField) ...[
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Color(0xFF888888)),
                    prefixText: '+91 ',
                    prefixStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                    ),
                  ),
                ),
              ],

              // OTP Field
              if (showOtpField) ...[
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'OTP Code',
                    labelStyle: const TextStyle(color: Color(0xFF888888)),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00D4FF)),
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _resendOtp(context, ref),
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(color: Color(0xFF00D4FF)),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Error Message
              if (errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => _handleContinue(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D4FF),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.black,
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
              ),

              const Spacer(),

              // Terms and Privacy
              const Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
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
            ref.read(showOtpFieldProvider.notifier).state = true;
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: const Color(0xFF00D4FF),
                ),
              );
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
      ref.read(errorMessageProvider.notifier).state = error.toString();
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
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
