import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import '../../shared/models/invoice.dart';
import '../../shared/models/transaction.dart';
import '../constants/app_constants.dart';
import '../types/payment_types.dart' as payment_types;
import 'base_service.dart';
import 'logger.dart';

final ComponentLogger _log = Log.component('payment');

class PaymentService extends BaseService {
  /// Track if PhonePe SDK is initialized
  static bool _phonePeInitialized = false;

  /// Check if running in local testing mode
  static bool get isLocalTesting =>
      const String.fromEnvironment('LOCAL_TESTING', defaultValue: 'false') ==
          'true' ||
      const String.fromEnvironment('FLUTTER_TEST', defaultValue: 'false') ==
          'true';

  /// Initialize PhonePe SDK (lazy - only when needed)
  static Future<void> initializePhonePe() async {
    if (_phonePeInitialized) return; // Already initialized
    try {
      _log.info('💀 Initializing PhonePe SDK');

      // Use string-based environment configuration (PhonePe SDK 2.0.3 pattern)
      final environment =
          AppConstants.phonePeEnvironment; // 'PRODUCTION' or 'UAT'
      final merchantId = AppConstants.phonePeMerchantId; // From environment

      _log.info(
        '📱 PhonePe Config: Environment=$environment, MerchantId=$merchantId',
      );

      // PhonePe SDK 2.0.3 initialization pattern
      await PhonePePaymentSdk.init(
        environment,
        merchantId,
        '', // App ID (required but can be empty)
        AppConstants.debugMode, // Enable logging based on environment
      );

      _log.info('✅ PhonePe SDK initialized successfully');
      _phonePeInitialized = true;
    } catch (error) {
      _log.error('PhonePe SDK initialization failed', error: error);
      rethrow;
    }
  }

  /// Process payment using real PhonePe SDK (modern Result pattern)
  static Future<payment_types.PaymentResult> processPayment({
    required String vendorId,
    required double amount,
    String? invoiceId,
    String? description,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      _log.info('💳 Starting PhonePe payment process');

      // Create invoice if not provided
      final finalInvoiceId =
          invoiceId ??
          await _createInvoiceForPayment(vendorId, amount, description);

      // Mock payment mode - skip PhonePe integration
      if (AppConstants.mockPaymentMode || isLocalTesting) {
        _log.info('🚀 Mock payment mode - simulating payment');

        // Simulate realistic payment delay
        await Future.delayed(const Duration(seconds: 2));

        // CRITICAL FIX: Create transaction directly in database for mock mode
        _log.info('🚀 Creating mock transaction directly in database', {
          'invoice_id': finalInvoiceId,
          'amount': amount,
          'vendor_id': vendorId,
        });

        final actualTransactionId = await _createMockTransaction(
          invoiceId: finalInvoiceId,
          vendorId: vendorId,
          amount: amount,
        );

        // Log mock payment for transparency
        _log.info('✅ Mock payment completed', {
          'transaction_id': actualTransactionId,
          'invoice_id': finalInvoiceId,
          'amount': amount,
          'method': 'direct_database',
        });

        return payment_types.PaymentSuccess(
          transactionId: actualTransactionId,
          invoiceId: finalInvoiceId,
          amount: amount,
          rewards: payment_types.PaymentFeeCalculator.calculateRewards(amount),
          message: 'Payment completed (Beta Mode)',
        );
      }

      // Call initiate-payment Edge Function
      final response = await BaseService.supabase.functions.invoke(
        'initiate-payment',
        body: {
          'invoice_id': finalInvoiceId,
          'amount': amount,
        },
      );

      if (response.data == null || response.data['success'] != true) {
        throw Exception(
          'Failed to initiate payment: ${response.data?['error'] ?? 'Unknown error'}',
        );
      }

      final paymentData = response.data as Map<String, dynamic>;

      // Initialize PhonePe SDK if not already done (lazy loading)
      if (!_phonePeInitialized) {
        await initializePhonePe();
      }

      // Start PhonePe transaction (PhonePe SDK 3.0.0 API)
      final result = await PhonePePaymentSdk.startTransaction(
        paymentData['body'] as String,
        paymentData['checksum'] as String,
      );

      _log.info('PhonePe transaction result: $result');

      // Handle PhonePe response with modern pattern matching
      if (result != null) {
        final phonePeResponse = payment_types.PhonePeResponse.fromMap(
          Map<String, dynamic>.from(result),
        );

        if (phonePeResponse.isSuccess) {
          // Call process-payment Edge Function
          await BaseService.supabase.functions.invoke(
            'process-payment',
            body: {
              'payment_gateway_ref':
                  paymentData['merchantTransactionId'] as String,
              'phonepe_response': result as Map<String, dynamic>,
            },
          );

          _log.info('Ã¢Å“â€¦ Payment successful');
          return payment_types.PaymentSuccess(
            transactionId: paymentData['merchantTransactionId'] as String,
            invoiceId: finalInvoiceId,
            amount: amount,
            rewards: payment_types.PaymentFeeCalculator.calculateRewards(
              amount,
            ),
            message: 'Payment completed successfully',
          );
        } else if (phonePeResponse.isCancelled) {
          _log.info('❡ ️ Payment cancelled by user');
          return payment_types.PaymentCancelled(
            transactionId: paymentData['merchantTransactionId'] as String,
            reason: phonePeResponse.message ?? 'Payment cancelled by user',
          );
        } else {
          _log.info('Ã¢ÂÅ’ Payment failed');
          return payment_types.PaymentFailure(
            error: phonePeResponse.message ?? 'Payment failed',
            transactionId: paymentData['merchantTransactionId'] as String,
            invoiceId: finalInvoiceId,
          );
        }
      } else {
        _log.info('Ã¢ÂÅ’ Payment failed - null response');
        return const payment_types.PaymentFailure(
          error: 'Payment failed - no response received',
        );
      }
    } catch (error) {
      _log.error('Payment processing error', error: error);

      // Ensure we always return a proper PaymentFailure
      return payment_types.PaymentFailure(
        error: 'Payment processing failed: ${error.toString()}',
        transactionId: null,
      );
    }
  }

  /// Create invoice for direct payment (when paying vendor without existing invoice)
  static Future<String> _createInvoiceForPayment(
    String vendorId,
    double amount,
    String? description,
  ) async {
    final data = {
      'user_id': BaseService.currentUserId!,
      'vendor_id': vendorId,
      'amount': amount,
      'due_date': DateTime.now().toIso8601String().split('T')[0],
      'status': 'pending',
      'description': description ?? 'Direct payment',
      'invoice_number': 'INV-${DateTime.now().millisecondsSinceEpoch}',
    };

    final response = await BaseService.supabase
        .from('invoices')
        .insert(data)
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Create mock transaction directly in database
  static Future<String> _createMockTransaction({
    required String invoiceId,
    required String vendorId,
    required double amount,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      // Get vendor information for vendor_name
      final vendorResponse = await BaseService.supabase
          .from('vendors')
          .select('name')
          .eq('id', vendorId)
          .eq('user_id', BaseService.currentUserId!)
          .single();

      final vendorName = vendorResponse['name'] as String;

      // Calculate fees and rewards
      final fee = amount * 0.02; // 2% fee
      final rewards = amount * 0.015; // 1.5% rewards
      final mockTransactionId = 'MOCK_TXN_${DateTime.now().millisecondsSinceEpoch}';

      _log.info('💰 Creating transaction with calculated values', {
        'vendor_name': vendorName,
        'fee': fee,
        'rewards': rewards,
        'mock_transaction_id': mockTransactionId,
      });

      // Create transaction record
      final transactionData = {
        'user_id': BaseService.currentUserId!,
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'invoice_id': invoiceId,
        'amount': amount,
        'fee': fee,
        'rewards_earned': rewards,
        'status': 'success', // Set to success immediately for mock
        'payment_method': 'Mock Payment',
        'phonepe_transaction_id': mockTransactionId,
        'completed_at': DateTime.now().toIso8601String(),
      };

      final transactionResponse = await BaseService.supabase
          .from('transactions')
          .insert(transactionData)
          .select('id')
          .single();

      final transactionId = transactionResponse['id'] as String;

      _log.info('✅ Transaction created successfully', {
        'transaction_id': transactionId,
        'amount': amount,
        'vendor_name': vendorName,
      });

      // Update invoice status to paid
      await BaseService.supabase
          .from('invoices')
          .update({
            'status': 'paid',
            'paid_at': DateTime.now().toIso8601String(),
            'transaction_id': transactionId,
          })
          .eq('id', invoiceId)
          .eq('user_id', BaseService.currentUserId!);

      _log.info('✅ Invoice updated to paid', {
        'invoice_id': invoiceId,
        'transaction_id': transactionId,
      });

      _log.info('🎉 Mock transaction creation completed successfully', {
        'transaction_id': mockTransactionId,
        'invoice_id': invoiceId,
        'vendor_id': vendorId,
        'amount': amount,
      });

      return mockTransactionId;
    } catch (error) {
      _log.error('❌ Failed to create mock transaction', error: error);

      // Re-throw with more context
      throw Exception('Mock transaction creation failed: ${error.toString()}');
    }
  }

  /// Update transaction status (Future use - PCC compliance)
  // ignore: unused_element
  static Future<void> _updateTransactionStatus(
    String transactionId,
    TransactionStatus status,
  ) async {
    final updateData = {
      'status': status.name,
      if (status == TransactionStatus.success)
        'completed_at': DateTime.now().toIso8601String(),
      if (status == TransactionStatus.failure)
        'failure_reason': 'Mock payment failure for demo',
    };

    await BaseService.supabase
        .from('transactions')
        .update(updateData)
        .eq('id', transactionId);
  }

  /// Update invoice status (Future use - PCC compliance)
  // ignore: unused_element
  static Future<void> _updateInvoiceStatus(
    String invoiceId,
    InvoiceStatus status,
  ) async {
    final updateData = {
      'status': status.name,
      if (status == InvoiceStatus.paid)
        'paid_at': DateTime.now().toIso8601String(),
    };

    await BaseService.supabase
        .from('invoices')
        .update(updateData)
        .eq('id', invoiceId);
  }

  /// Get payment fee for amount
  static double calculateFee(double amount) {
    return amount * 0.02; // 2% fee
  }

  /// Get rewards for amount
  static double calculateRewards(double amount) {
    return amount * 0.015; // 1.5% rewards
  }
}
