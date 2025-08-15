import 'dart:convert';

import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import '../../shared/models/invoice.dart';
import '../../shared/models/transaction.dart';
import '../constants/app_constants.dart';
import '../types/payment_types.dart' as payment_types;
import 'base_service.dart';
import 'logger.dart';
import 'smart_logger.dart';

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

  /// Initialize PhonePe SDK 3.0.0 (NEW PATTERN)
  static Future<void> initializePhonePe() async {
    if (_phonePeInitialized) return; // Already initialized
    try {
      _log.info('🚀 Initializing PhonePe SDK 3.0.0');

      // NEW: SDK 3.0.0 initialization pattern
      final environment =
          AppConstants.phonePeEnvironment; // "SANDBOX" or "PRODUCTION"
      final merchantId = AppConstants.phonePeMerchantId; // Merchant ID
      final flowId =
          'INVOICE_PE_FLOW_${DateTime.now().millisecondsSinceEpoch}'; // Unique flow ID
      final enableLogging = AppConstants.debugMode; // Enable logging

      _log.info(
        '📱 PhonePe SDK 3.0.0 Config: Environment=$environment, MerchantId=$merchantId, FlowId=$flowId',
      );

      // PhonePe SDK 3.0.0 initialization (NEW API)
      await PhonePePaymentSdk.init(
        environment, // Environment string
        merchantId, // Merchant ID
        flowId, // Flow ID (user-specific)
        enableLogging, // Enable logging
      );

      _log.info('✅ PhonePe SDK 3.0.0 initialized successfully');
      _phonePeInitialized = true;
    } catch (error) {
      _log.error('PhonePe SDK 3.0.0 initialization failed', error: error);
      rethrow;
    }
  }

  /// Process payment with PhonePe SDK 3.0.0 (NEW METHOD)
  static Future<payment_types.PaymentSuccess> processPaymentV3({
    required String vendorId,
    required String vendorName,
    required double amount,
    String? invoiceId,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      _log.info('💳 Starting PhonePe 3.0.0 payment process', {
        'amount': amount,
        'vendor': vendorName,
        'invoice_id': invoiceId,
      });

      // Create invoice if not provided - ELON FIX: Generate proper UUID for database
      final finalInvoiceId =
          invoiceId ??
          await _createInvoiceForPayment(
            vendorId,
            amount,
            'PhonePe 3.0.0 Payment',
          );

      // MOCK MODE: Skip PhonePe integration for development
      if (AppConstants.mockPaymentMode || isLocalTesting) {
        return await _processMockPaymentV3(
          vendorId,
          vendorName,
          amount,
          finalInvoiceId,
        );
      }

      // STEP 1: Create Order via Edge Function
      final orderResponse = await BaseService.supabase.functions.invoke(
        'create-phonepe-order',
        body: {
          'amount': (amount * 100).round(), // Convert to paise
          'vendor_id': vendorId,
          'vendor_name': vendorName,
          'invoice_id': finalInvoiceId,
        },
      );

      if (orderResponse.data?['success'] != true) {
        throw Exception(
          'Order creation failed: ${orderResponse.data?['error']}',
        );
      }

      final orderData = orderResponse.data as Map<String, dynamic>;
      final orderId = orderData['orderId'] as String;
      final orderToken = orderData['token'] as String;
      final transactionId = orderData['transactionId'] as String;

      _log.info('📋 PhonePe order created', {
        'orderId': orderId,
        'transactionId': transactionId,
      });

      // STEP 2: Initialize PhonePe SDK 3.0.0
      await initializePhonePe();

      // STEP 3: Create Transaction Request (NEW FORMAT)
      final request = {
        "orderId": orderId,
        "merchantId": AppConstants.phonePeMerchantId,
        "token": orderToken,
        "paymentMode": {
          "type": "PAY_PAGE",
          "savedCards": true, // Enable saved cards
          "allowNewCard": true, // Allow new cards
          "preferredMethods": ["CARD", "UPI"], // Prioritize cards and UPI
        },
      };

      _log.info('📱 Starting PhonePe SDK 3.0.0 transaction', {
        'orderId': orderId,
      });

      // STEP 4: Start Transaction with PhonePe SDK 3.0.0
      final result = await PhonePePaymentSdk.startTransaction(
        jsonEncode(request),
        '', // App schema (empty string for Android)
      );

      _log.info('📱 PhonePe transaction result', {'result': result});

      // STEP 5: Handle Response and Verify Payment
      return await _handlePaymentResponseV3(
        result,
        orderId,
        transactionId,
        amount,
        finalInvoiceId,
      );
    } catch (error, stackTrace) {
      _log.error('PhonePe 3.0.0 payment processing failed', error: error);

      // ELON FIX: Enhanced error logging with stack trace
      SmartLogger.logError(
        'PhonePe 3.0.0 payment processing failed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'vendor_id': vendorId,
          'vendor_name': vendorName,
          'amount': amount,
          'invoice_id': invoiceId,
          'operation': 'payment_processing_error',
        },
      );

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

        // ELON FIX: Add smart logging for payment debugging
        SmartLogger.logPayment(
          'Mock payment initiated',
          context: {
            'invoice_id': finalInvoiceId,
            'amount': amount,
            'vendor_id': vendorId,
            'operation': 'mock_payment_start',
          },
        );

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

        // ELON FIX: Smart log payment success
        SmartLogger.logPayment(
          'Mock payment completed successfully',
          context: {
            'transaction_id': actualTransactionId,
            'invoice_id': finalInvoiceId,
            'amount': amount,
            'operation': 'mock_payment_success',
          },
        );

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
    } catch (error, stackTrace) {
      _log.error('Payment processing error', error: error);

      // ELON FIX: Enhanced error logging with stack trace
      SmartLogger.logError(
        'Payment processing failed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'vendor_id': vendorId,
          'amount': amount,
          'invoice_id': invoiceId,
          'operation': 'payment_processing_error',
        },
      );

      // Ensure we always return a proper PaymentFailure
      return payment_types.PaymentFailure(
        error: 'Payment processing failed: $error',
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
      final mockTransactionId =
          'MOCK_TXN_${DateTime.now().millisecondsSinceEpoch}';

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

      // ELON FIX: Smart log transaction creation failures
      SmartLogger.logError(
        'Mock transaction creation failed',
        error: error,
        context: {
          'invoice_id': invoiceId,
          'vendor_id': vendorId,
          'amount': amount,
          'operation': 'mock_transaction_creation_error',
        },
      );

      // Re-throw with more context
      throw Exception('Mock transaction creation failed: $error');
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

  /// Process mock payment for PhonePe SDK 3.0.0 testing
  static Future<payment_types.PaymentSuccess> _processMockPaymentV3(
    String vendorId,
    String vendorName,
    double amount,
    String invoiceId,
  ) async {
    _log.info(
      '🎭 Mock payment mode enabled - simulating PhonePe 3.0.0 payment',
    );

    // Simulate realistic payment delay
    await Future.delayed(const Duration(seconds: 2));

    // Create mock transaction record with PhonePe 3.0.0 fields
    final mockOrderId = 'OMO_MOCK_${DateTime.now().millisecondsSinceEpoch}';
    final mockTransactionId =
        'MOCK_TXN_${DateTime.now().millisecondsSinceEpoch}';
    final fee = payment_types.PaymentFeeCalculator.calculateFee(amount);
    final rewards = payment_types.PaymentFeeCalculator.calculateRewards(amount);

    final transactionData = {
      'user_id': BaseService.currentUserId!,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'invoice_id': invoiceId,
      'amount': amount,
      'fee': fee,
      'rewards_earned': rewards,
      'status': 'success',
      'payment_method': 'Mock Payment (PhonePe 3.0.0)',
      'phonepe_transaction_id': mockTransactionId,
      'phonepe_order_id': mockOrderId,
      'phonepe_order_status': 'SUCCESS',
      'phonepe_merchant_order_id':
          'MOCK_MERCHANT_${DateTime.now().millisecondsSinceEpoch}',
      'phonepe_response_data': {
        'success': true,
        'code': 'PAYMENT_SUCCESS',
        'message': 'Mock payment completed successfully',
        'data': {
          'merchantId': AppConstants.phonePeMerchantId,
          'orderId': mockOrderId,
          'transactionId': mockTransactionId,
          'amount': (amount * 100).round(),
          'state': 'COMPLETED',
          'responseCode': 'SUCCESS',
        },
      },
      'completed_at': DateTime.now().toIso8601String(),
    };

    final transactionResponse = await BaseService.supabase
        .from('transactions')
        .insert(transactionData)
        .select('id')
        .single();

    final dbTransactionId = transactionResponse['id'] as String;

    _log.info('✅ Mock PhonePe 3.0.0 transaction created', {
      'transaction_id': dbTransactionId,
      'phonepe_order_id': mockOrderId,
      'amount': amount,
      'vendor_name': vendorName,
    });

    return payment_types.PaymentSuccess(
      transactionId: mockTransactionId,
      invoiceId: invoiceId,
      amount: amount,
      rewards: rewards,
      message: 'Payment completed (PhonePe 3.0.0 Mock Mode)',
    );
  }

  /// Handle PhonePe SDK 3.0.0 payment response
  static Future<payment_types.PaymentSuccess> _handlePaymentResponseV3(
    dynamic result,
    String orderId,
    String transactionId,
    double amount,
    String invoiceId,
  ) async {
    try {
      // Parse PhonePe SDK 3.0.0 response
      final response = result as Map<String, dynamic>;
      final success = response['success'] == true;

      _log.info('📱 Processing PhonePe 3.0.0 response', {
        'success': success,
        'orderId': orderId,
      });

      if (success) {
        // STEP 1: Verify payment status via Edge Function
        final statusResponse = await BaseService.supabase.functions.invoke(
          'verify-phonepe-payment',
          body: {'orderId': orderId},
        );

        if (statusResponse.data?['verified'] == true) {
          final verifiedTransactionId =
              statusResponse.data['transactionId'] as String;

          _log.info('✅ PhonePe 3.0.0 payment verified successfully', {
            'orderId': orderId,
            'transactionId': verifiedTransactionId,
          });

          return payment_types.PaymentSuccess(
            transactionId: verifiedTransactionId,
            invoiceId: invoiceId,
            amount: amount,
            rewards: payment_types.PaymentFeeCalculator.calculateRewards(
              amount,
            ),
            message: 'Payment completed successfully via PhonePe 3.0.0',
          );
        } else {
          throw Exception('Payment verification failed');
        }
      } else {
        final errorMessage = response['error']?.toString() ?? 'Payment failed';
        _log.error('❌ PhonePe 3.0.0 payment failed', error: errorMessage);
        throw Exception('Payment failed: $errorMessage');
      }
    } catch (error) {
      _log.error('PhonePe 3.0.0 response handling failed', error: error);
      rethrow;
    }
  }
}
