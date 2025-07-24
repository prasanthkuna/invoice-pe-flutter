import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/payment_service.dart';
import '../../../../core/types/payment_types.dart' as payment_types;
import '../../../../shared/models/vendor.dart';

final quickPaymentAmountProvider = StateProvider<double>((ref) => 0.0);
final quickPaymentVendorProvider = StateProvider<Vendor?>((ref) => null);

class QuickPaymentScreen extends ConsumerStatefulWidget {
  const QuickPaymentScreen({super.key});

  @override
  ConsumerState<QuickPaymentScreen> createState() => _QuickPaymentScreenState();
}

class _QuickPaymentScreenState extends ConsumerState<QuickPaymentScreen> {
  final _amountController = TextEditingController();
  final _searchController = TextEditingController();
  bool _showVendorDropdown = false;

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorsProvider);
    final selectedVendor = ref.watch(quickPaymentVendorProvider);
    final amount = ref.watch(quickPaymentAmountProvider);

    final fee = amount * AppConstants.defaultFeePercentage / 100;
    final total = amount + fee;
    final rewards = amount * AppConstants.defaultRewardsPercentage / 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Pay Any Vendor',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

            const SizedBox(height: 8),

            Text(
              'Select vendor and amount to pay instantly',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.secondaryText,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 32),

            // Vendor Selection
            Text(
              'Select Vendor',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 16),

            // Vendor Dropdown
            GestureDetector(
              onTap: () =>
                  setState(() => _showVendorDropdown = !_showVendorDropdown),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedVendor != null
                        ? AppTheme.primaryAccent.withValues(alpha: 0.5)
                        : AppTheme.secondaryText.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (selectedVendor != null) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            selectedVendor.name.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: AppTheme.primaryAccent,
                              fontSize: 18,
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
                              selectedVendor.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              selectedVendor.phone ?? 'No phone',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.secondaryText,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.business,
                        color: AppTheme.secondaryText,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Choose a vendor to pay',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                        ),
                      ),
                    ],
                    Icon(
                      _showVendorDropdown
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppTheme.secondaryText,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),

            // Vendor List Dropdown
            if (_showVendorDropdown) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.secondaryText.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: vendors.when(
                  data: (vendorList) => vendorList.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 48,
                                color: AppTheme.secondaryText,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No vendors yet',
                                style: TextStyle(
                                  color: AppTheme.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => context.go('/vendors/create'),
                                child: const Text('Add Your First Vendor'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: vendorList.length + 1,
                          itemBuilder: (context, index) {
                            if (index == vendorList.length) {
                              return ListTile(
                                leading: const Icon(
                                  Icons.add_circle_outline,
                                  color: AppTheme.primaryAccent,
                                ),
                                title: const Text(
                                  'Add New Vendor',
                                  style: TextStyle(
                                    color: AppTheme.primaryAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                onTap: () {
                                  setState(() => _showVendorDropdown = false);
                                  context.go('/vendors/create');
                                },
                              );
                            }
                            final vendor = vendorList[index];
                            return ListTile(
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    vendor.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.primaryAccent,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                vendor.name,
                                style: const TextStyle(
                                  color: AppTheme.primaryText,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                vendor.phone ?? 'No phone',
                                style: const TextStyle(
                                  color: AppTheme.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () {
                                ref
                                        .read(
                                          quickPaymentVendorProvider.notifier,
                                        )
                                        .state =
                                    vendor;
                                setState(() => _showVendorDropdown = false);
                              },
                            );
                          },
                        ),
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Error loading vendors: $error',
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2),
            ],

            const SizedBox(height: 32),

            // Amount Input
            Text(
              'Enter Amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 1000.ms),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          autofocus: true, // KEYBOARD FIX: Auto-focus amount field
                          onChanged: (value) {
                            final parsedAmount = double.tryParse(value) ?? 0.0;
                            ref
                                    .read(quickPaymentAmountProvider.notifier)
                                    .state =
                                parsedAmount;
                          },
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            hintStyle: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondaryText,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (amount > 0) ...[
                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.secondaryText),
                    const SizedBox(height: 16),

                    // Fee Breakdown
                    _buildFeeRow('Amount', '₹${amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildFeeRow(
                      'Processing Fee (${AppConstants.defaultFeePercentage}%)',
                      '₹${fee.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 8),
                    _buildFeeRow(
                      'Rewards Earned',
                      '+₹${rewards.toStringAsFixed(2)}',
                      isReward: true,
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.secondaryText),
                    const SizedBox(height: 16),
                    _buildFeeRow(
                      'Total',
                      '₹${total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),

            if (selectedVendor != null &&
                amount >= AppConstants.minPaymentAmount) ...[
              const SizedBox(height: 32),

              // Total Debit Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.secondaryText.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '₹${total.toStringAsFixed(2)} will be debited from your payment method',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 1300.ms).slideY(begin: 0.3),

              const SizedBox(height: 16),

              // Pay Button - Shows actual payment to vendor
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _processQuickPayment(
                    context,
                    ref,
                    selectedVendor,
                    amount,
                    total,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Pay ₹${amount.toStringAsFixed(2)} to ${selectedVendor.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.5),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    String value, {
    bool isReward = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isReward ? AppTheme.secondaryAccent : AppTheme.secondaryText,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isReward
                ? AppTheme.secondaryAccent
                : isTotal
                ? AppTheme.primaryText
                : AppTheme.primaryText,
            fontWeight: isReward || isTotal
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _processQuickPayment(
    BuildContext context,
    WidgetRef ref,
    Vendor vendor,
    double amount,
    double total,
  ) async {
    // Validate session before payment
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (!isAuthenticated) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        context.go('/auth');
      }
      return;
    }

    // Show loading dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
        ),
      ),
    );

    try {
      // Process payment using existing service
      final result = await PaymentService.processPayment(
        vendorId: vendor.id,
        amount: amount,
        description: 'Quick payment to ${vendor.name}',
      );

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Handle payment result using proper type checking
      if (result.isSuccess) {
        final paymentData = {
          'amount': amount,
          'vendorName': vendor.name,
          'vendorId': vendor.id,
          'rewards': result.rewards ?? (amount * AppConstants.defaultRewardsPercentage / 100),
          'transactionId': result.transactionId ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
          'paymentMethod': 'Mock Payment',
          'fee': amount * AppConstants.defaultFeePercentage / 100,
          'total': total,
        };

        // CRITICAL FIX: Use refresh() to immediately update data
        ref.refresh(dashboardMetricsProvider);
        ref.refresh(recentTransactionsProvider);
        ref.refresh(transactionsProvider);

        // Reset form
        ref.read(quickPaymentVendorProvider.notifier).state = null;
        ref.read(quickPaymentAmountProvider.notifier).state = 0.0;
        _amountController.clear();

        if (context.mounted) {
          context.go('/payment-success', extra: paymentData);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment failed. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (error) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.of(context).pop();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $error'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
