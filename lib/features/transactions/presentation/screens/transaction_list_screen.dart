import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/transaction.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/error/error_boundary.dart';

class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final searchQuery = ref.watch(transactionSearchQueryProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // If not authenticated, show login prompt
    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: AppTheme.primaryAccent,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view transactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/auth'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return ErrorBoundary(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog(context, ref);
              },
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // TODO: Export transactions
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) =>
                    ref.read(transactionSearchQueryProvider.notifier).state =
                        value,
                style: const TextStyle(color: AppTheme.primaryText),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: const TextStyle(color: AppTheme.secondaryText),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.secondaryText,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

            // Status Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StatusChip(
                      label: 'All',
                      isSelected:
                          ref.watch(selectedTransactionStatusProvider) == null,
                      onTap: () =>
                          ref
                                  .read(
                                    selectedTransactionStatusProvider.notifier,
                                  )
                                  .state =
                              null,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Completed',
                      isSelected:
                          ref.watch(selectedTransactionStatusProvider) ==
                          TransactionStatus.success,
                      onTap: () =>
                          ref
                              .read(selectedTransactionStatusProvider.notifier)
                              .state = TransactionStatus
                              .success,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Pending',
                      isSelected:
                          ref.watch(selectedTransactionStatusProvider) ==
                          TransactionStatus.initiated,
                      onTap: () =>
                          ref
                              .read(selectedTransactionStatusProvider.notifier)
                              .state = TransactionStatus
                              .initiated,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Failed',
                      isSelected:
                          ref.watch(selectedTransactionStatusProvider) ==
                          TransactionStatus.failure,
                      onTap: () =>
                          ref
                              .read(selectedTransactionStatusProvider.notifier)
                              .state = TransactionStatus
                              .failure,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 16),

            // Transactions List
            Expanded(
              child: filteredTransactions.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryAccent,
                    ),
                  ),
                ),
                error: (error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading transactions',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.red,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: const TextStyle(color: AppTheme.secondaryText),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.refresh(filteredTransactionsProvider),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (filteredTransactions) => RefreshIndicator(
                  onRefresh: () async {
                    // CRITICAL FIX: Use refresh() to immediately update data
                    // ignore: unused_result
                    ref.refresh(transactionsProvider);
                    // ignore: unused_result
                    ref.refresh(dashboardMetricsProvider);
                    // ignore: unused_result
                    ref.refresh(recentTransactionsProvider);
                  },
                  color: AppTheme.primaryAccent,
                  backgroundColor: AppTheme.cardBackground,
                  child: filteredTransactions.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                            ),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: AppTheme.secondaryText.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'No transactions yet'
                                        : 'No transactions found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppTheme.secondaryText,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    searchQuery.isEmpty
                                        ? 'Your payment history will appear here'
                                        : 'Try a different search term',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.secondaryText
                                              .withValues(
                                                alpha: 0.7,
                                              ),
                                        ),
                                  ),
                                  if (searchQuery.isEmpty) ...[
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () => context.go('/quick-pay'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryAccent,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text(
                                        'Make Your First Payment',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = filteredTransactions[index];
                            return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: _TransactionCard(
                                    transaction: transaction,
                                    onTap: () => context.go(
                                      '/transactions/${transaction.id}',
                                    ),
                                  ),
                                )
                                .animate(
                                  delay: Duration(milliseconds: 100 * index),
                                )
                                .fadeIn()
                                .slideX(begin: 0.3);
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.transaction,
    required this.onTap,
  });
  final Transaction transaction;
  final VoidCallback onTap;

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
            color: AppTheme.primaryAccent.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Indicator
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      transaction.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getStatusIcon(transaction.status),
                      color: _getStatusColor(transaction.status),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Transaction Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.vendorName ?? 'Unknown Vendor',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${transaction.id.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${transaction.amount.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.status.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Date & Payment Method
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      Text(
                        _formatDate(transaction.createdAt ?? DateTime.now()),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Method',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      Text(
                        transaction.paymentMethod ?? 'PhonePe',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.initiated:
        return Colors.orange;
      case TransactionStatus.pending:
        return Colors.blue;
      case TransactionStatus.success:
        return Colors.green;
      case TransactionStatus.failure:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
      case TransactionStatus.expired:
        return Colors.brown;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.initiated:
        return Icons.schedule;
      case TransactionStatus.pending:
        return Icons.hourglass_empty;
      case TransactionStatus.success:
        return Icons.check_circle;
      case TransactionStatus.failure:
        return Icons.error;
      case TransactionStatus.cancelled:
        return Icons.cancel;
      case TransactionStatus.expired:
        return Icons.access_time;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAccent : AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAccent
                : AppTheme.secondaryText.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

void _showFilterDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppTheme.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Filter Transactions',
        style: TextStyle(color: AppTheme.primaryText),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filter by date range and status:',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          SizedBox(height: 16),
          // Date range and other filters would go here
          Text(
            'Advanced filters coming soon...',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
