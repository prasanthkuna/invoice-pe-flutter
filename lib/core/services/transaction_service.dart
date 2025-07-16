import '../../shared/models/transaction.dart';
import 'base_service.dart';

class TransactionService extends BaseService {
  static const String _tableName = 'transactions';

  /// Get all transactions for the current user
  static Future<List<Transaction>> getTransactions() async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select('*')
          .eq('user_id', BaseService.currentUserId!)
          .order('created_at', ascending: false);

      return response.map(_fromSupabaseJson).toList();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Get a specific transaction by ID
  static Future<Transaction?> getTransaction(String transactionId) async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select('*')
          .eq('id', transactionId)
          .eq('user_id', BaseService.currentUserId!)
          .maybeSingle();

      return response != null ? _fromSupabaseJson(response) : null;
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Get transactions by status
  static Future<List<Transaction>> getTransactionsByStatus(
    TransactionStatus status,
  ) async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select('*')
          .eq('user_id', BaseService.currentUserId!)
          .eq('status', _mapStatusToBackend(status))
          .order('created_at', ascending: false);

      return response.map(_fromSupabaseJson).toList();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Get transactions for a specific invoice
  static Future<List<Transaction>> getTransactionsForInvoice(
    String invoiceId,
  ) async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select('*')
          .eq('invoice_id', invoiceId)
          .eq('user_id', BaseService.currentUserId!)
          .order('created_at', ascending: false);

      return response.map(_fromSupabaseJson).toList();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Get recent transactions (last 10)
  static Future<List<Transaction>> getRecentTransactions({
    int limit = 10,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select('*')
          .eq('user_id', BaseService.currentUserId!)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map(_fromSupabaseJson).toList();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Map frontend TransactionStatus to backend status
  static String _mapStatusToBackend(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.initiated:
        return 'initiated';
      case TransactionStatus.success:
        return 'success';
      case TransactionStatus.failure:
        return 'failure';
    }
  }

  /// Convert Supabase JSON to Transaction model
  static Transaction _fromSupabaseJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vendorId: json['vendor_id'] as String?,
      vendorName: json['vendor_name'] as String?,
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
      rewardsEarned: (json['rewards_earned'] as num?)?.toDouble() ?? 0.0,
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TransactionStatus.initiated,
      ),
      invoiceId: json['invoice_id'] as String?,
      paymentMethod: json['payment_method'] as String?,
      phonepeTransactionId: json['phonepe_transaction_id'] as String?,
      failureReason: json['failure_reason'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }
}
