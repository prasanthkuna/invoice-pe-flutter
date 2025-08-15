import 'dart:async' as async;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/types/auth_types.dart' as app_auth;
import '../../../../core/types/result.dart';
import '../../../../core/error/error_boundary.dart';

// final ComponentLogger _log = Log.component('auth'); // Unused for now

final otpProvider = StateProvider<String>((ref) => '');
final timerProvider = StateProvider<int>((ref) => 60);
final isVerifyingProvider = StateProvider<bool>((ref) => false);

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({
    required this.phone,
    super.key,
  });
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController pinController = TextEditingController();
  final FocusNode pinFocusNode = FocusNode();
  async.Timer? _timer;

  Future<void> _verifyOtp(BuildContext context, WidgetRef ref, String otp) async {
    if (otp.length != 6) return;

    try {
      ref.read(isVerifyingProvider.notifier).state = true;

      final result = await AuthService.verifyOtp(phone: widget.phone, otp: otp);

      switch (result) {
        case Success():
          _timer?.cancel();
          _timer = null;

          final profileStatus = await AuthService.checkProfileStatus();
          if (context.mounted) {
            switch (profileStatus) {
              case app_auth.ProfileComplete():
                context.go('/dashboard');
              case app_auth.ProfileIncomplete():
                context.go('/setup-profile');
            }
          }

        case Failure(error: final error):
          if (context.mounted) {
            // Clear OTP for re-entry on error
            pinController.clear();
            ref.read(otpProvider.notifier).state = '';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
              ),
            );
          }
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        ref.read(isVerifyingProvider.notifier).state = false;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // Cancel any existing timer first
    _timer?.cancel();
    _timer = null;

    final timerNotifier = ref.read(timerProvider.notifier);
    timerNotifier.state = 60;

    _timer = async.Timer.periodic(const Duration(seconds: 1), (timer) {
      // Safety check: widget still mounted
      if (!mounted || _timer == null || _timer != timer) {
        timer.cancel();
        return;
      }

      // Use stored notifier - NO ref.read() calls in timer callback
      final currentTimer = timerNotifier.state;
      if (currentTimer > 0) {
        timerNotifier.state = currentTimer - 1;
      } else {
        timer.cancel();
        _timer = null;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }



  void _onOtpChanged(String otp) {
    if (mounted) {
      ref.read(otpProvider.notifier).state = otp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(timerProvider);
    final isVerifying = ref.watch(isVerifyingProvider);

    return ErrorBoundary(
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator - TESLA FIX: Removed animation
            const LinearProgressIndicator(
              value: 0.5,
              backgroundColor: AppTheme.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
            ),

            const SizedBox(height: 40),

            // Title - TESLA FIX: Removed animation
            Text(
              'Enter verification code',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We sent a 6-digit code to your phone',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: AppTheme.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Paste OTP from messages or enter manually',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms),
              ],
            ),

            const SizedBox(height: 48),

            // OTP Input with Pinput (Best paste support)
            Pinput(
              controller: pinController,
              focusNode: pinFocusNode,
              length: 6,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              hapticFeedbackType: HapticFeedbackType.lightImpact,
              onChanged: _onOtpChanged,
              onCompleted: (pin) => _verifyOtp(context, ref, pin),
              defaultPinTheme: PinTheme(
                width: 48,
                height: 56,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 48,
                height: 56,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryAccent,
                    width: 2,
                  ),
                ),
              ),
              submittedPinTheme: PinTheme(
                width: 48,
                height: 56,
                textStyle: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryAccent,
                    width: 2,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms).scale(),

            const SizedBox(height: 32),

            // Timer and Resend
            Center(
              child: timer > 0
                  ? Text(
                      'Resend code in ${timer}s',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                    )
                  : TextButton(
                      onPressed: () async {
                        try {
                          await AuthService.sendOtpSmart(widget.phone);

                          // ELON FIX: Safe provider access with mounted check
                          if (mounted) {
                            ref.read(timerProvider.notifier).state = 60;
                            _startTimer();
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('OTP sent successfully'),
                                backgroundColor: AppTheme.primaryAccent,
                              ),
                            );
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to resend OTP: $error'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Resend Code'),
                    ),
            ).animate().fadeIn(delay: 800.ms),

            const Spacer(),

            // Auto-verification indicator
            if (isVerifying)
              const Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryAccent,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Verifying...',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    );
  }
}
