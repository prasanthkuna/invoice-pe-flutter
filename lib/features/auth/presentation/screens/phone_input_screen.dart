import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/logger.dart';
import '../../../../core/types/auth_types.dart' as app_auth;

final ComponentLogger _log = Log.component('auth');

final phoneNumberProvider = StateProvider<String>((ref) => '');
final isLoadingProvider = StateProvider<bool>((ref) => false);

class PhoneInputScreen extends ConsumerWidget {
  const PhoneInputScreen({super.key});

  Future<void> _sendOtp(
    BuildContext context,
    WidgetRef ref,
    String phoneNumber,
  ) async {
    try {
      ref.read(isLoadingProvider.notifier).state = true;

      _log.info('Ã°Å¸Å¡â‚¬ Sending OTP to +91$phoneNumber');

      final result = await AuthService.sendOtpSmart('+91$phoneNumber');

      switch (result) {
        case app_auth.OtpSent(phone: final phone):
          _log.info('Ã¢Å“â€¦ OTP sent successfully to $phone');
          if (context.mounted) {
            context.push('/otp', extra: phone);
          }
        case app_auth.OtpFailed(error: final error):
          _log.error('❌ OTP sending failed', error: error);
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
      _log.error('OTP sending error', error: error);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phoneNumber = ref.watch(phoneNumberProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final isValid = phoneNumber.length == AppConstants.phoneNumberLength &&
      RegExp(AppConstants.phoneNumberPattern).hasMatch(phoneNumber);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/welcome');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator - TESLA FIX: Disabled animation to prevent main thread blocking
            const LinearProgressIndicator(
              value: 0.25,
              backgroundColor: AppTheme.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
            ),

            const SizedBox(height: 40),

            // Title - TESLA FIX: Disabled animations
            Text(
              'Enter your phone number',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "We'll send you a verification code",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.secondaryText,
              ),
            ),

            const SizedBox(height: 48),

            // Phone Input
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isValid ? AppTheme.primaryAccent : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppTheme.secondaryText.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (value) =>
                          ref.read(phoneNumberProvider.notifier).state = value,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(AppConstants.phoneNumberLength),
                      ],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryText,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Phone number',
                        hintStyle: TextStyle(color: AppTheme.secondaryText),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (isValid && !isLoading)
                    ? () => _sendOtp(context, ref, phoneNumber)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid
                      ? AppTheme.primaryAccent
                      : AppTheme.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
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
                        'Continue',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isValid
                              ? Colors.white
                              : AppTheme.secondaryText,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
