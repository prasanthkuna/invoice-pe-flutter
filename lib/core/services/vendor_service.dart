import '../../shared/models/vendor.dart';
import 'base_service.dart';
import 'debug_service.dart';

class VendorService extends BaseService {
  static const String _tableName = 'vendors';
  
  /// Get all vendors for the current user
  static Future<List<Vendor>> getVendors() async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select()
          .eq('user_id', BaseService.currentUserId!)
          .order('created_at', ascending: false);

      return response.map((json) => _fromSupabaseJson(json)).toList();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
  
  /// Get a specific vendor by ID
  static Future<Vendor?> getVendor(String vendorId) async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select()
          .eq('id', vendorId)
          .eq('user_id', BaseService.currentUserId!)
          .maybeSingle();

      return response != null ? _fromSupabaseJson(response) : null;
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
  
  /// Create a new vendor
  static Future<Vendor> createVendor({
    required String name,
    required String accountNumber,
    required String ifscCode,
    String? upiId,
    String? email,
    String? phone,
    String? address,
    String? gstin,
  }) async {
    // Move data declaration outside try block for error logging
    final data = {
      'user_id': BaseService.currentUserId!,
      'name': name,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      if (upiId != null) 'upi_id': upiId,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (gstin != null) 'gstin': gstin,
    };

    try {
      BaseService.ensureAuthenticated();

      DebugService.logDatabase('Creating vendor', table: 'vendors', data: data);

      final response = await BaseService.supabase
          .from(_tableName)
          .insert(data)
          .select()
          .single();

      DebugService.logDatabase('Vendor created successfully', table: 'vendors', data: {'vendor_id': response['id']});
      return _fromSupabaseJson(response);
    } catch (error) {
      DebugService.logDatabase('Failed to create vendor', table: 'vendors', data: data, error: error);
      throw BaseService.handleError(error);
    }
  }
  
  /// Update an existing vendor
  static Future<Vendor> updateVendor({
    required String vendorId,
    String? name,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    String? email,
    String? phone,
    String? address,
    String? gstin,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (accountNumber != null) data['account_number'] = accountNumber;
      if (ifscCode != null) data['ifsc_code'] = ifscCode;
      if (upiId != null) data['upi_id'] = upiId;
      if (email != null) data['email'] = email;
      if (phone != null) data['phone'] = phone;
      if (address != null) data['address'] = address;
      if (gstin != null) data['gstin'] = gstin;

      final response = await BaseService.supabase
          .from(_tableName)
          .update(data)
          .eq('id', vendorId)
          .eq('user_id', BaseService.currentUserId!)
          .select()
          .single();

      return _fromSupabaseJson(response);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
  
  /// Delete a vendor
  static Future<void> deleteVendor(String vendorId) async {
    try {
      BaseService.ensureAuthenticated();

      await BaseService.supabase
          .from(_tableName)
          .delete()
          .eq('id', vendorId)
          .eq('user_id', BaseService.currentUserId!);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
  
  /// Convert Supabase JSON to Vendor model
  static Vendor _fromSupabaseJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      accountNumber: json['account_number'] as String? ?? '',
      ifscCode: json['ifsc_code'] as String? ?? '',
      upiId: json['upi_id'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      gstin: json['gstin'] as String?,
      logoUrl: json['logo_url'] as String?,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      transactionCount: json['transaction_count'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }
}
