import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/transaction.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/error/error_boundary.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({
    required this.transactionId,
    super.key,
  });
  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionAsync = ref.watch(transactionProvider(transactionId));

    return ErrorBoundary(
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: transactionAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
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
                'Error loading transaction',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                    ref.refresh(transactionProvider(transactionId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (transaction) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Status Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          transaction.status,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
                        child: Icon(
                          _getStatusIcon(transaction.status),
                          color: _getStatusColor(transaction.status),
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getStatusMessage(transaction.status),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${transaction.amount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: AppTheme.primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(transaction.status),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        transaction.status.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),

              const SizedBox(height: 20),

              // Transaction Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Transaction Details',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      label: 'Transaction ID',
                      value: transaction.id,
                      isSelectable: true,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Date & Time',
                      value: transaction.createdAt != null
                          ? _formatDateTime(transaction.createdAt!)
                          : 'Not available',
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Payment Method',
                      value: transaction.paymentMethod ?? 'PhonePe',
                    ),
                    if (transaction.phonepeTransactionId != null) ...[
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'PhonePe Transaction ID',
                        value: transaction.phonepeTransactionId!,
                        isSelectable: true,
                      ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

              const SizedBox(height: 20),

              // Vendor Information
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vendor Information',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryAccent.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              (transaction.vendorName?.isNotEmpty == true)
                                  ? transaction.vendorName!
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : 'V',
                              style: const TextStyle(
                                color: AppTheme.primaryAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.vendorName ?? 'Unknown Vendor',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppTheme.primaryText,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Vendor ID: ${transaction.vendorId}',
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

              if (transaction.invoiceId != null) ...[
                const SizedBox(height: 20),

                // Invoice Information
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Related Invoice',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.receipt,
                            color: AppTheme.primaryAccent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Invoice ID: ${transaction.invoiceId}',
                              style: const TextStyle(
                                color: AppTheme.primaryText,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/invoices/${transaction.invoiceId}');
                            },
                            child: const Text('View Invoice'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
              ],

              const SizedBox(height: 32),

              // Action Buttons
              if (transaction.status == TransactionStatus.failure) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Retry payment
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Retry Payment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else if (transaction.status == TransactionStatus.success) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Download receipt
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Download Receipt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
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

  String _getStatusMessage(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.initiated:
        return 'Payment Initiated';
      case TransactionStatus.pending:
        return 'Payment Pending';
      case TransactionStatus.success:
        return 'Payment Successful';
      case TransactionStatus.failure:
        return 'Payment Failed';
      case TransactionStatus.cancelled:
        return 'Payment Cancelled';
      case TransactionStatus.expired:
        return 'Payment Expired';
    }
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isSelectable = false,
  });
  final String label;
  final String value;
  final bool isSelectable;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: isSelectable
              ? SelectableText(
                  value,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ],
    );
  }
}
