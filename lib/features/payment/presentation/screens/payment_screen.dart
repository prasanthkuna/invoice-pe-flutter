import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
// Payment providers not needed - using local state
import '../../../../core/services/payment_service.dart';
import '../../../../core/services/smart_logger.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/invoice.dart';
import '../../../../shared/models/vendor.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/utils/navigation_helper.dart';
import '../../../../core/utils/display_helper.dart';

final paymentAmountProvider = StateProvider<double>((ref) => 0.0);
final selectedCardProvider = StateProvider<int>((ref) => 0);

class PaymentScreen extends ConsumerWidget {
  const PaymentScreen({
    super.key,
    this.vendorId,
    this.invoiceId,
  });
  final String? vendorId;
  final String? invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for invoice or vendor data
    final invoiceAsync = invoiceId != null
        ? ref.watch(invoiceProvider(invoiceId!))
        : null;
    final vendorAsync = vendorId != null
        ? ref.watch(vendorProvider(vendorId!))
        : null;

    final amount = ref.watch(paymentAmountProvider);
    final fee = amount * AppConstants.defaultFeePercentage / 100;
    final total = amount + fee;
    final rewards = amount * AppConstants.defaultRewardsPercentage / 100;

    // Handle loading states
    if ((invoiceAsync?.isLoading ?? false) ||
        (vendorAsync?.isLoading ?? false)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Make Payment'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryAccent),
          ),
        ),
      );
    }

    // Extract data from async providers
    final invoice = invoiceAsync?.value;
    final vendor = vendorAsync?.value;

    // Set initial amount from invoice if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (invoice != null && amount == 0.0) {
        ref.read(paymentAmountProvider.notifier).state = invoice.amount;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(invoice != null ? 'Pay Invoice' : 'Make Payment'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationHelper.safePop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getVendorInitial(invoice, vendor),
                        style: const TextStyle(
                          color: AppTheme.primaryAccent,
                          fontSize: 24,
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
                          _getVendorName(invoice, vendor),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getVendorDetails(invoice, vendor),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.3),

            const SizedBox(height: 32),

            // Amount Input
            Text(
              'Enter Amount',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
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
                          autofocus: true, // KEYBOARD FIX: Auto-focus amount field
                          onChanged: (value) {
                            final parsedAmount = double.tryParse(value) ?? 0.0;
                            ref.read(paymentAmountProvider.notifier).state =
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Amount',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                        ),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.primaryText,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Processing Fee (${AppConstants.defaultFeePercentage}%)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                              ),
                        ),
                        Text(
                          '₹${fee.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.primaryText,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rewards Earned',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.secondaryAccent,
                              ),
                        ),
                        Text(
                          '+₹${rewards.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.secondaryAccent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.secondaryText),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3),

            if (amount > 0) ...[
              const SizedBox(height: 32),

              // Payment Method
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 16),

              // Demo Mode Notice
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Demo Mode: Using mock cards. Real payment cards will be available after PhonePe merchant approval.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 900.ms),

              // Credit Card Selection
              SizedBox(
                height: 200,
                child: PageView.builder(
                  itemCount: 2, // Mock cards for UI only
                  onPageChanged: (index) {
                    ref.read(selectedCardProvider.notifier).state = index;
                  },
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: index == 0
                              ? [
                                  AppTheme.primaryAccent,
                                  const Color(0xFF1E3A8A),
                                ]
                              : [
                                  AppTheme.secondaryAccent,
                                  const Color(0xFF92400E),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                index == 0 ? 'HDFC Bank' : 'ICICI Bank',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                index == 0 ? 'VISA' : 'MASTERCARD',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '**** **** **** ${index == 0 ? '1234' : '5678'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'JOHN DOE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '12/26',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 1000.ms).slideX(begin: 0.3),

              const SizedBox(height: 24),

              // Total Debit Information
              if (amount >= AppConstants.minPaymentAmount) ...[
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
                ).animate().fadeIn(delay: 1100.ms).slideY(begin: 0.3),
                const SizedBox(height: 16),
              ],

              // Pay Button - Shows actual payment amount
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: amount >= AppConstants.minPaymentAmount
                      ? () => _processPayment(
                          context,
                          ref,
                          amount,
                          fee,
                          rewards,
                          total,
                        )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amount >= AppConstants.minPaymentAmount
                        ? AppTheme.primaryAccent
                        : AppTheme.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    amount >= AppConstants.minPaymentAmount
                        ? 'Pay ₹${amount.toStringAsFixed(2)}${_getVendorName(invoiceAsync?.value, vendorAsync?.value).isNotEmpty ? ' to ${_getVendorName(invoiceAsync?.value, vendorAsync?.value)}' : ''}'
                        : 'Enter amount to pay',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: amount >= AppConstants.minPaymentAmount
                          ? Colors.white
                          : AppTheme.secondaryText,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.5),
            ],
          ],
        ),
      ),
    );
  }

  void _processPayment(
    BuildContext context,
    WidgetRef ref,
    double amount,
    double fee,
    double rewards,
    double total,
  ) async {
    final invoice = invoiceId != null
        ? ref.read(invoiceProvider(invoiceId!)).value
        : null;
    final vendor = vendorId != null
        ? ref.read(vendorProvider(vendorId!)).value
        : null;

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
      // Use PhonePe SDK 3.0.0 payment service
      final result = await PaymentService.processPaymentV3(
        vendorId: vendorId ?? invoice?.vendorId ?? '',
        vendorName: vendor?.name ?? invoice?.vendorName ?? 'Unknown Vendor',
        amount: amount,
        invoiceId: invoiceId,
      );

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      // Handle PhonePe SDK 3.0.0 payment result
      final paymentData = {
        'amount': amount,
        'vendorName': _getVendorName(invoice, vendor),
        'vendorId': vendorId ?? invoice?.vendorId ?? '',
        'invoiceId': invoiceId,
        'rewards': result.rewards,
        'transactionId': result.transactionId,
        'paymentMethod': 'PhonePe',
        'fee': fee,
        'total': total,
      };

        // ELON FIX: Refresh providers after successful payment
        // This ensures vendors and transactions lists show updated data
        ref.invalidate(vendorsProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(dashboardMetricsProvider);

      if (context.mounted) {
        context.go('/payment-success', extra: paymentData);
      }
    } catch (error, stackTrace) {
      // Close loading dialog if still open
      if (context.mounted) Navigator.of(context).pop();

      // ELON FIX: Enhanced error logging with stack trace
      SmartLogger.logError('Invoice payment failed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'vendor_id': vendorId,
          'invoice_id': invoiceId,
          'amount': amount,
          'operation': 'invoice_payment_error',
        }
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getVendorInitial(Invoice? invoice, Vendor? vendor) {
    return DisplayHelper.getVendorInitial(invoice, vendor);
  }

  String _getVendorName(Invoice? invoice, Vendor? vendor) {
    return DisplayHelper.getVendorName(invoice, vendor);
  }

  String _getVendorDetails(Invoice? invoice, Vendor? vendor) {
    if (vendor != null) {
      return DisplayHelper.formatVendorInfo(vendor);
    }
    if (invoice != null) {
      return 'Invoice #${invoice.invoiceNumber}';
    }
    return 'Payment Details';
  }
}
