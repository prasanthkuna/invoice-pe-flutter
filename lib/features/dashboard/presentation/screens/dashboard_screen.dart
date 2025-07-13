import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/auth_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardMetrics = ref.watch(dashboardMetricsProvider);
    final currentProfile = ref.watch(currentProfileProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // If not authenticated, redirect to auth
    if (!isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/auth');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      currentProfile.when(
                        data: (profile) => Text(
                          profile?.businessName ?? 'Business Owner',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => Text(
                          'Loading...',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        error: (error, stackTrace) => Text(
                          'Business Owner',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.notifications_outlined,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showLogoutDialog(context, ref),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.logout,
                            color: AppTheme.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),
              
              const SizedBox(height: 32),
              
              // Rewards Card (Hero Metric)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondaryAccent, Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.secondaryAccent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '✨ Total Rewards Earned',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'This Month',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    dashboardMetrics.when(
                      data: (metrics) => Text(
                        '₹${(metrics['totalRewards'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      loading: () => const Text(
                        '₹0.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      error: (error, stackTrace) => const Text(
                        '₹0.00',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '+₹2,450 from last month',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
              
              const SizedBox(height: 24),
              
              // Metrics Grid
              dashboardMetrics.when(
                data: (metrics) => Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Payments',
                        value: '₹${((metrics['totalPayments'] ?? 0.0) / 1000).toStringAsFixed(0)}K',
                        subtitle: 'This month',
                        icon: Icons.payment,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        title: 'Transactions',
                        value: (metrics['monthlyTransactions'] ?? 0).toString(),
                        subtitle: 'Completed',
                        icon: Icons.receipt_long,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Payments',
                        value: '₹0K',
                        subtitle: 'This month',
                        icon: Icons.payment,
                        color: AppTheme.primaryAccent,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _MetricCard(
                        title: 'Transactions',
                        value: '0',
                        subtitle: 'Completed',
                        icon: Icons.receipt_long,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),
              
              const SizedBox(height: 32),
              
              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 800.ms),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: 'Quick Pay',
                      subtitle: 'Instant payment',
                      icon: Icons.flash_on,
                      onTap: () => context.go('/quick-pay'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      title: 'Transactions',
                      subtitle: 'View history',
                      icon: Icons.history,
                      onTap: () => context.go('/transactions'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.3),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _ActionCard(
                      title: 'Cards',
                      subtitle: 'Manage cards',
                      icon: Icons.credit_card,
                      onTap: () => context.go('/cards'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ActionCard(
                      title: 'Invoice Create',
                      subtitle: 'Create invoice',
                      icon: Icons.receipt_long,
                      onTap: () => context.go('/invoices/create'),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),
              
              const SizedBox(height: 24),
              
              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 1200.ms),
              
              const SizedBox(height: 16),
              
              // Activity List
              ...List.generate(3, (index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment to Vendor ${index + 1}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '₹${(5000 + index * 1000).toStringAsFixed(0)} • 2 hours ago',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+₹${(50 + index * 10)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.secondaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).animate(interval: 200.ms).fadeIn(delay: 1400.ms).slideX(begin: 0.3),
            ],
          ),
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/quick-pay'),
        backgroundColor: AppTheme.primaryAccent,
        icon: const Icon(Icons.flash_on, color: Colors.white),
        label: const Text(
          'Quick Pay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ).animate().scale(delay: 1600.ms),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: const Text(
            'Logout',
            style: TextStyle(color: AppTheme.primaryText),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await AuthService.signOut();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                } catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryAccent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryAccent, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
