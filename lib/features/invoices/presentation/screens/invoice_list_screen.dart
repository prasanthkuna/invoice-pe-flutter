import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/invoice.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/error/error_boundary.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ELON FIX: Refresh data when invoice list screen is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshInvoiceData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ELON FIX: Refresh data when returning to invoice list from other screens
    _refreshInvoiceData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // ELON FIX: Refresh data when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _refreshInvoiceData();
    }
  }

  /// ELON FIX: Centralized invoice data refresh
  void _refreshInvoiceData() {
    if (!mounted) return;

    // Use refresh() for immediate data updates
    // ignore: unused_result
    ref.refresh(invoicesProvider);
    // ignore: unused_result
    ref.refresh(filteredInvoicesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final filteredInvoices = ref.watch(filteredInvoicesProvider);
    final searchQuery = ref.watch(invoiceSearchQueryProvider);
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
                'Please log in to view invoices',
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
          title: const Text('Invoices'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                _showFilterDialog(context, ref);
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            // ELON FIX: Pull-to-refresh for invoice list
            // ignore: unused_result
            ref.refresh(invoicesProvider);
            // ignore: unused_result
            ref.refresh(filteredInvoicesProvider);

            // Wait a bit for the refresh to complete
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onChanged: (value) =>
                      ref.read(invoiceSearchQueryProvider.notifier).state =
                          value,
                  style: const TextStyle(color: AppTheme.primaryText),
                  decoration: InputDecoration(
                    hintText: 'Search invoices...',
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
                child: Row(
                  children: [
                    _StatusChip(
                      label: 'All',
                      isSelected:
                          ref.watch(selectedInvoiceStatusProvider) == null,
                      onTap: () =>
                          ref
                                  .read(selectedInvoiceStatusProvider.notifier)
                                  .state =
                              null,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Pending',
                      isSelected:
                          ref.watch(selectedInvoiceStatusProvider) ==
                          InvoiceStatus.pending,
                      onTap: () =>
                          ref
                                  .read(selectedInvoiceStatusProvider.notifier)
                                  .state =
                              InvoiceStatus.pending,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Paid',
                      isSelected:
                          ref.watch(selectedInvoiceStatusProvider) ==
                          InvoiceStatus.paid,
                      onTap: () =>
                          ref
                                  .read(selectedInvoiceStatusProvider.notifier)
                                  .state =
                              InvoiceStatus.paid,
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: 'Overdue',
                      isSelected:
                          ref.watch(selectedInvoiceStatusProvider) ==
                          InvoiceStatus.overdue,
                      onTap: () =>
                          ref
                                  .read(selectedInvoiceStatusProvider.notifier)
                                  .state =
                              InvoiceStatus.overdue,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Invoices List
              Expanded(
                child: filteredInvoices.when(
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
                          'Error loading invoices',
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
                              ref.refresh(filteredInvoicesProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryAccent,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (filteredInvoices) => filteredInvoices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_outlined,
                                size: 64,
                                color: AppTheme.secondaryText.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                searchQuery.isEmpty
                                    ? 'No invoices yet'
                                    : 'No invoices found',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppTheme.secondaryText,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                searchQuery.isEmpty
                                    ? 'Create your first invoice to get started'
                                    : 'Try a different search term',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.secondaryText.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = filteredInvoices[index];
                            return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: _InvoiceCard(
                                    invoice: invoice,
                                    onTap: () =>
                                        context.go('/invoices/${invoice.id}'),
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
            ],
          ),
        ),

        // Add Invoice FAB
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.go('/invoices/create');
          },
          backgroundColor: AppTheme.primaryAccent,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Create Invoice',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate().scale(delay: 600.ms),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.onTap,
  });
  final Invoice invoice;
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
                      invoice.status,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _getStatusIcon(invoice.status),
                      color: _getStatusColor(invoice.status),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Invoice Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invoice #${invoice.invoiceNumber}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.vendorName,
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
                      '₹${invoice.amount.toStringAsFixed(0)}',
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
                        color: _getStatusColor(invoice.status),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        invoice.status.name.toUpperCase(),
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

            // Date & Due Date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      Text(
                        _formatDate(invoice.createdAt),
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
                        'Due Date',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      Text(
                        _formatDate(invoice.dueDate),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: invoice.status == InvoiceStatus.overdue
                              ? Colors.red
                              : AppTheme.primaryText,
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

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Colors.blue;
      case InvoiceStatus.pending:
        return Colors.orange;
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.draft:
        return Icons.edit;
      case InvoiceStatus.pending:
        return Icons.schedule;
      case InvoiceStatus.paid:
        return Icons.check_circle;
      case InvoiceStatus.overdue:
        return Icons.warning;
      case InvoiceStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
        'Filter Invoices',
        style: TextStyle(color: AppTheme.primaryText),
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filter by status:',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          SizedBox(height: 16),
          // Status filter options would go here
          Text(
            'More filters coming soon...',
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
