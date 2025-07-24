import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class PaymentFailureScreen extends StatelessWidget {
  const PaymentFailureScreen({
    super.key,
    this.paymentData,
  });
  final Map<String, dynamic>? paymentData;

  @override
  Widget build(BuildContext context) {
    // Extract payment data or use defaults
    final amount = paymentData?['amount'] ?? 0.0;
    final vendorName = paymentData?['vendorName'] ?? 'Unknown Vendor';
    final transactionId = paymentData?['transactionId'] ?? 'Unknown';
    final failureReason =
        paymentData?['failureReason'] ?? 'Payment could not be processed';
    final errorCode = paymentData?['errorCode'] ?? 'UNKNOWN_ERROR';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryBackground,
              AppTheme.cardBackground,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/dashboard'),
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.primaryText,
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Payment Failed',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 44), // Balance the close button
                  ],
                ),

                const Spacer(),

                // Failure Animation - TESLA FIX: Simplified for performance
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Failure Message - TESLA FIX: Removed animation
                Text(
                  'Payment Failed',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                Text(
                  failureReason?.toString() ?? 'Payment failed',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 1000.ms),

                const SizedBox(height: 32),

                // Payment Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Amount',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹${amount.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppTheme.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Vendor
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Vendor',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 16,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              vendorName?.toString() ?? 'Unknown Vendor',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Transaction ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Transaction ID',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 16,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              transactionId?.toString() ?? 'N/A',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.primaryText,
                                    fontFamily: 'monospace',
                                  ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Error Code
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Error Code',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              errorCode?.toString() ?? 'UNKNOWN_ERROR',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.3),

                const Spacer(),

                // Action Buttons
                Column(
                  children: [
                    // Retry Payment Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          // Navigate back to payment screen with same data
                          final vendorId = paymentData?['vendorId'];
                          final invoiceId = paymentData?['invoiceId'];

                          if (invoiceId != null) {
                            context.go('/payment/$invoiceId');
                          } else if (vendorId != null) {
                            context.go(
                              '/payment',
                              extra: {'vendorId': vendorId},
                            );
                          } else {
                            context.go('/dashboard');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Contact Support Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Implement contact support
                          _showSupportDialog(
                            context,
                            transactionId?.toString() ?? 'N/A',
                            errorCode?.toString() ?? 'UNKNOWN',
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryAccent,
                          side: const BorderSide(color: AppTheme.primaryAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Contact Support',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Back to Dashboard
                    TextButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1400.ms).slideY(begin: 0.5),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSupportDialog(
    BuildContext context,
    String transactionId,
    String errorCode,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Contact Support',
          style: TextStyle(color: AppTheme.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please contact our support team with the following details:',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction ID: $transactionId',
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Error Code: $errorCode',
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email: support@invoicepe.com\nPhone: +91 9000 000 000',
              style: TextStyle(
                color: AppTheme.primaryAccent,
                fontWeight: FontWeight.w500,
              ),
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
}
