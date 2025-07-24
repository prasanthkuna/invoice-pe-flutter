import 'dart:async' as async;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/logger.dart';
import '../../../../core/types/auth_types.dart' as app_auth;
import '../../../../core/types/result.dart';

final ComponentLogger _log = Log.component('auth');

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
  final List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  async.Timer? _timer;

  Future<void> _verifyOtp(
    BuildContext context,
    WidgetRef ref,
    String otp,
  ) async {
    try {
      ref.read(isVerifyingProvider.notifier).state = true;

      final result = await AuthService.verifyOtp(
        phone: widget.phone,
        otp: otp,
      );

      switch (result) {
        case Success():
          // Check profile completion status
          final profileStatus = await AuthService.checkProfileStatus();

          switch (profileStatus) {
            case app_auth.ProfileComplete():
              if (context.mounted) {
                context.go('/dashboard');
              }
            case app_auth.ProfileIncomplete():
              if (context.mounted) {
                context.go('/setup-profile');
              }
          }

        case Failure(error: final error):
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
              ),
            );
          }
      }
    } catch (error) {
      _log.error('OTP verification error', error: error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(isVerifyingProvider.notifier).state = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = async.Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTimer = ref.read(timerProvider);
      if (currentTimer > 0) {
        ref.read(timerProvider.notifier).state = currentTimer - 1;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in controllers) {
      controller.dispose();
    }
    for (final focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged() {
    final otp = controllers.map((c) => c.text).join();
    ref.read(otpProvider.notifier).state = otp;

    if (otp.length == 6) {
      // Auto-verify when OTP is complete
      _verifyOtp(context, ref, otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otp = ref.watch(otpProvider);
    final timer = ref.watch(timerProvider);
    final isVerifying = ref.watch(isVerifyingProvider);

    return Scaffold(
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

            Text(
              'We sent a 6-digit code to your phone',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.secondaryText,
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),

            const SizedBox(height: 48),

            // OTP Input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: controllers[index].text.isNotEmpty
                          ? AppTheme.primaryAccent
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: controllers[index],
                    focusNode: focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1),
                    ],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        focusNodes[index - 1].requestFocus();
                      }
                      _onOtpChanged();
                    },
                  ),
                );
              }).animate(interval: 100.ms).fadeIn(delay: 600.ms).scale(),
            ),

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
                          ref.read(timerProvider.notifier).state = 60;
                          _startTimer();
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

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (otp.length == 6 && !isVerifying)
                    ? () => _verifyOtp(context, ref, otp)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: otp.length == 6
                      ? AppTheme.primaryAccent
                      : AppTheme.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isVerifying
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: otp.length == 6
                              ? Colors.white
                              : AppTheme.secondaryText,
                        ),
                      ),
              ),
            ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.5),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
