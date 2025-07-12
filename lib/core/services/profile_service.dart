
import '../../shared/models/user_profile.dart';
import 'base_service.dart';

class ProfileService extends BaseService {
  static const String _tableName = 'profiles';
  
  /// Get the current user's profile
  static Future<UserProfile?> getCurrentProfile() async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select()
          .eq('id', BaseService.currentUserId!)
          .maybeSingle();

      return response != null ? _fromSupabaseJson(response) : null;
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
  
  /// Create a new profile (manual creation, no triggers)
  static Future<UserProfile> createProfile({
    required String phone,
    required String businessName,
    String? gstin,
    String? email,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      final data = {
        'id': BaseService.currentUserId!,
        'phone': phone,
        'business_name': businessName,
        if (gstin != null) 'gstin': gstin,
        if (email != null) 'email': email,
      };

      final response = await BaseService.supabase
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      return _fromSupabaseJson(response);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
  
  /// Update the current user's profile
  static Future<UserProfile> updateProfile({
    String? businessName,
    String? gstin,
    String? email,
    String? address,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      final data = <String, dynamic>{};
      if (businessName != null) data['business_name'] = businessName;
      if (gstin != null) data['gstin'] = gstin;
      if (email != null) data['email'] = email;
      if (address != null) data['address'] = address;

      if (data.isEmpty) {
        throw Exception('No data provided for update');
      }

      final response = await BaseService.supabase
          .from(_tableName)
          .update(data)
          .eq('id', BaseService.currentUserId!)
          .select()
          .single();

      return _fromSupabaseJson(response);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
  
  /// Get dashboard metrics for the current user
  static Future<Map<String, dynamic>> getDashboardMetrics() async {
    try {
      BaseService.ensureAuthenticated();

      // Get total payments and rewards from transactions
      final transactionsResponse = await BaseService.supabase
          .from('transactions')
          .select('amount, fee, rewards_earned, status')
          .eq('user_id', BaseService.currentUserId!);

      double totalPayments = 0.0;
      double totalRewards = 0.0;
      double totalFees = 0.0;
      int successfulTransactions = 0;

      for (final transaction in transactionsResponse) {
        if (transaction['status'] == 'completed') {
          totalPayments += (transaction['amount'] as num).toDouble();
          totalFees += (transaction['fee'] as num).toDouble();
          totalRewards += (transaction['rewards_earned'] as num?)?.toDouble() ?? 0.0;
          successfulTransactions++;
        }
      }

      // Get vendor count
      final vendorCountResponse = await BaseService.supabase
          .from('vendors')
          .select('id')
          .eq('user_id', BaseService.currentUserId!);

      // Get pending invoices count
      final pendingInvoicesResponse = await BaseService.supabase
          .from('invoices')
          .select('id')
          .eq('user_id', BaseService.currentUserId!)
          .eq('status', 'pending');

      return {
        'totalPayments': totalPayments,
        'totalRewards': totalRewards,
        'totalFees': totalFees,
        'totalTransactions': successfulTransactions,
        'vendorCount': vendorCountResponse.length,
        'pendingInvoicesCount': pendingInvoicesResponse.length,
      };
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
  
  /// Convert Supabase JSON to UserProfile model
  static UserProfile _fromSupabaseJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phone: json['phone'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      gstin: json['gstin'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      totalRewards: (json['total_rewards'] as num?)?.toDouble() ?? 0.0,
      totalPayments: (json['total_payments'] as num?)?.toDouble() ?? 0.0,
      totalTransactions: json['total_transactions'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }
}
