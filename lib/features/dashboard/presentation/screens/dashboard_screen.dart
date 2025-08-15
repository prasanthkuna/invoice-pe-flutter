import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/models/transaction.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/error_boundary.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ELON FIX: Refresh data when dashboard screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboardData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ELON FIX: Refresh data when returning to dashboard from other screens
    // This triggers when the route changes and dashboard becomes active again
    _refreshDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // ELON FIX: Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshDashboardData();
    }
  }

  /// ELON FIX: Centralized dashboard data refresh
  void _refreshDashboardData() {
    if (!mounted) return;

    // Use refresh() for immediate data updates
    // ignore: unused_result
    ref.refresh(dashboardMetricsProvider);
    // ignore: unused_result
    ref.refresh(recentTransactionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    // ELON FIX: Event-driven refresh instead of dangerous invalidation
    // Listen for navigation events to refresh data
    ref.listen(authStateProvider, (previous, next) {
      if (next.hasValue && next.value?.session != null) {
        _refreshDashboardData();
      }
    });
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

    return ErrorBoundary(
      child: Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 0, // Hide the app bar completely for cleaner look
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // ELON FIX: Pull-to-refresh functionality for dashboard
              _refreshDashboardData();

              // Wait a bit for the refresh to complete
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics:
                  const AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
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
                          // REMOVED: Duplicate welcome message
                          currentProfile.when(
                            data: (profile) => Text(
                              profile?.businessName ?? 'Business Owner',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            loading: () => Text(
                              'Loading...',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            error: (error, stackTrace) => Text(
                              'Business Owner',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
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

                  // Beta Mode Banner
                  if (AppConstants.mockPaymentMode)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.rocket_launch_rounded,
                            color: Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Beta Mode Active',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Payments are in test mode. Real transactions coming soon!',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.2),

                  // ELON UX: Bento Grid Layout - Modern 2024 Design
                  _BentoDashboard(dashboardMetrics: dashboardMetrics),

                  const SizedBox(height: 24),

                  // ELON UX: Removed old layout - now handled by BentoDashboard

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
                  Consumer(
                    builder: (context, ref, _) {
                      final recentTransactions = ref.watch(
                        recentTransactionsProvider,
                      );
                      return recentTransactions.when(
                        data: (transactions) => transactions.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardBackground,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 48,
                                        color: AppTheme.secondaryText
                                            .withValues(
                                              alpha: 0.5,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No recent activity',
                                        style: TextStyle(
                                          color: AppTheme.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: 1400.ms)
                            : Column(
                                children: transactions.take(3).map((
                                  transaction,
                                ) {
                                  return GestureDetector(
                                    onTap: () => context.push('/transactions/${transaction.id}'),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardBackground,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                      children: [
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryAccent
                                                .withValues(
                                                  alpha: 0.1,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            transaction.status ==
                                                    TransactionStatus.success
                                                ? Icons.check_circle
                                                : transaction.status ==
                                                      TransactionStatus.failure
                                                ? Icons.error
                                                : Icons.schedule,
                                            color:
                                                transaction.status ==
                                                    TransactionStatus.success
                                                ? AppTheme.successColor
                                                : transaction.status ==
                                                      TransactionStatus.failure
                                                ? AppTheme.errorColor
                                                : AppTheme.warningColor,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Payment to ${transaction.vendorName ?? "Unknown"}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      color:
                                                          AppTheme.primaryText,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              Text(
                                                '₹${transaction.amount.toStringAsFixed(0)} • ${_getRelativeTime(transaction.createdAt)}',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: AppTheme
                                                          .secondaryText,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (transaction.rewardsEarned > 0)
                                          Text(
                                            '+₹${transaction.rewardsEarned.toStringAsFixed(0)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color:
                                                      AppTheme.secondaryAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                                }).toList(),
                              ).animate().fadeIn(delay: 1400.ms).slideX(begin: 0.3),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryAccent,
                            ),
                          ),
                        ).animate().fadeIn(delay: 1400.ms),
                        error: (_, __) => Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              'Unable to load recent activity',
                              style: TextStyle(
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 1400.ms),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        // ELON UX FIX: Removed duplicate FAB - Quick Pay available in action cards
      ),
    );
  }

  String _getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
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

// ELON UX: Bento Grid Dashboard - Modern 2024 Design Pattern
class _BentoDashboard extends StatelessWidget {
  const _BentoDashboard({required this.dashboardMetrics});

  final AsyncValue<Map<String, dynamic>> dashboardMetrics;

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width - 48; // Account for padding

    return dashboardMetrics.when(
      data: (metrics) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          // Row 1: Business Metrics (2x compact cards)
          _CompactMetric(
            title: 'Monthly Spend',
            value:
                '₹${(((metrics['totalPayments'] as num?) ?? 0.0) / 1000).toStringAsFixed(0)}K',
            change: '+12%',
            width: (screenWidth - 12) / 2,
            icon: Icons.trending_up,
            color: AppTheme.primaryAccent,
          ),
          _CompactMetric(
            title: 'Active Vendors',
            value: ((metrics['vendorCount'] as int?) ?? 0).toString(),
            change: '+2 this month',
            width: (screenWidth - 12) / 2,
            icon: Icons.business,
            color: AppTheme.successColor,
          ),

          // Row 2: Primary CTA (full width)
          _QuickPayCard(
            width: screenWidth,
            height: 80,
          ),

          // Row 3: Secondary Actions (3x compact cards)
          _CompactActionCard(
            title: 'Transactions',
            icon: Icons.history,
            width: (screenWidth - 24) / 3,
            onTap: () => context.push('/transactions'),
          ),
          _CompactActionCard(
            title: 'Vendors',
            icon: Icons.business,
            width: (screenWidth - 24) / 3,
            onTap: () => context.push('/vendors'),
          ),
          _CompactActionCard(
            title: 'Cards',
            icon: Icons.credit_card,
            width: (screenWidth - 24) / 3,
            onTap: () => context.push('/cards'),
          ),

          // Row 4: Future Feature Preview
          _FeatureCard(
            title: 'Scan Invoice',
            subtitle: 'Coming Soon',
            icon: Icons.camera_alt,
            width: screenWidth,
            height: 60,
          ),
        ],
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _BentoErrorState(screenWidth: screenWidth),
    );
  }
}

// ELON UX: Compact Metric Card - Business KPI focused
class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.title,
    required this.value,
    required this.change,
    required this.width,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String change;
  final double width;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 16),
              Text(
                change,
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ELON UX: Quick Pay Card - Primary CTA
class _QuickPayCard extends StatelessWidget {
  const _QuickPayCard({
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/quick-pay'),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryAccent, AppTheme.secondaryAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flash_on,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Quick Pay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Instant payment to vendors',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ELON UX: Compact Action Card - Secondary actions
class _CompactActionCard extends StatelessWidget {
  const _CompactActionCard({
    required this.title,
    required this.icon,
    required this.width,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 70,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryAccent.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryAccent, size: 18),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w500,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ELON UX: Feature Card - Future features preview
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.width,
    required this.height,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondaryText.withValues(alpha: 0.3),
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.secondaryText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ELON UX: Error State for Bento Grid
class _BentoErrorState extends StatelessWidget {
  const _BentoErrorState({required this.screenWidth});

  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _CompactMetric(
          title: 'Monthly Spend',
          value: '₹0K',
          change: '--',
          width: (screenWidth - 12) / 2,
          icon: Icons.trending_up,
          color: AppTheme.primaryAccent,
        ),
        _CompactMetric(
          title: 'Active Vendors',
          value: '0',
          change: '--',
          width: (screenWidth - 12) / 2,
          icon: Icons.business,
          color: AppTheme.successColor,
        ),
        _QuickPayCard(
          width: screenWidth,
          height: 80,
        ),
      ],
    );
  }
}

// _MetricCard class removed - was unused (unused_element warning)

// _ActionCard class removed - was unused (unused_element warning)
