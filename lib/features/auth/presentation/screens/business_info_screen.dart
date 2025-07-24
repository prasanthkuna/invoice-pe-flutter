import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/profile_service.dart';

final businessNameProvider = StateProvider<String>((ref) => '');
final gstinProvider = StateProvider<String>((ref) => '');

class BusinessInfoScreen extends ConsumerWidget {
  const BusinessInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessName = ref.watch(businessNameProvider);
    final isValid = businessName.trim().isNotEmpty;

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
              context.go('/otp');
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Indicator
            const LinearProgressIndicator(
              value: 0.75,
              backgroundColor: AppTheme.cardBackground,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
            ).animate().scaleX(duration: 800.ms),

            const SizedBox(height: 40),

            // Title
            Text(
              'Tell us about your business',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

            const SizedBox(height: 16),

            Text(
              'This helps us personalize your experience',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.secondaryText,
              ),
            ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.3),

            const SizedBox(height: 48),

            // Business Name Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Business Name *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  autofocus: true, // KEYBOARD FIX: Auto-focus business name field
                  onChanged: (value) =>
                      ref.read(businessNameProvider.notifier).state = value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your business name',
                    hintStyle: const TextStyle(color: AppTheme.secondaryText),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

            const SizedBox(height: 24),

            // GSTIN Input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GSTIN (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  onChanged: (value) =>
                      ref.read(gstinProvider.notifier).state = value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter GSTIN (can be added later)',
                    hintStyle: const TextStyle(color: AppTheme.secondaryText),
                    filled: true,
                    fillColor: AppTheme.cardBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can add this later in settings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),

            const Spacer(),

            // Complete Setup Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isValid ? () => _completeSetup(context, ref) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isValid
                      ? AppTheme.primaryAccent
                      : AppTheme.cardBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Complete Setup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isValid ? Colors.white : AppTheme.secondaryText,
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

  Future<void> _completeSetup(BuildContext context, WidgetRef ref) async {
    final businessName = ref.read(businessNameProvider);
    final gstin = ref.read(gstinProvider);

    try {
      await ProfileService.updateProfile(
        businessName: businessName.trim(),
        gstin: gstin.trim().isEmpty ? null : gstin.trim(),
      );

      if (context.mounted) {
        context.go('/dashboard');
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
