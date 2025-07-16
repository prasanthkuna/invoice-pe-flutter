import '../../shared/models/invoice.dart';
import 'base_service.dart';

class InvoiceService extends BaseService {
  static const String _tableName = 'invoices';

  /// Get all invoices for the current user
  static Future<List<Invoice>> getInvoices() async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select('''
            *,
            vendors!inner(name)
          ''')
          .eq('user_id', BaseService.currentUserId!)
          .order('created_at', ascending: false);

      final responseList = response as List<dynamic>;
      return responseList
          .map((item) => _fromSupabaseJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Get a specific invoice by ID
  /// Returns non-nullable Invoice or throws exception if not found
  static Future<Invoice> getInvoice(String invoiceId) async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select('''
            *,
            vendors!inner(name)
          ''')
          .eq('id', invoiceId)
          .eq('user_id', BaseService.currentUserId!)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invoice not found: $invoiceId');
      }

      return _fromSupabaseJson(response);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Create a new invoice with smart defaults
  static Future<Invoice> createInvoice({
    required String vendorId,
    required double amount,
    DateTime? dueDate,
    String? description,
    String? invoiceNumber,
    InvoiceStatus? status,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      // Get vendor name for smart defaults
      final vendorResponse = await BaseService.supabase
          .from('vendors')
          .select('name')
          .eq('id', vendorId)
          .single();

      final vendorName = vendorResponse['name'] as String;

      // Create invoice with smart defaults using factory constructor
      final invoice = Invoice.formal(
        vendorId: vendorId,
        vendorName: vendorName,
        amount: amount,
        dueDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
        description: description,
        invoiceNumber: invoiceNumber,
        status: status ?? InvoiceStatus.draft,
        userId: BaseService.currentUserId,
      );

      final data = {
        'user_id': BaseService.currentUserId!,
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'amount': amount,
        'due_date': invoice.dueDate.toIso8601String().split(
          'T',
        )[0], // Date only
        'status': invoice.status.name,
        'description': invoice.description,
        'invoice_number': invoice.invoiceNumber,
      };

      final response = await BaseService.supabase
          .from(_tableName)
          .insert(data)
          .select('*')
          .single();

      return _fromSupabaseJson(response);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Create invoice for quick payment (primary use case)
  static Future<Invoice> createPaymentInvoice({
    required String vendorId,
    required double amount,
    String? description,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      // Get vendor name for smart defaults
      final vendorResponse = await BaseService.supabase
          .from('vendors')
          .select('name')
          .eq('id', vendorId)
          .single();

      final vendorName = vendorResponse['name'] as String;

      // Create invoice with smart defaults using factory constructor
      final invoice = Invoice.forPayment(
        vendorId: vendorId,
        vendorName: vendorName,
        amount: amount,
        description: description,
        userId: BaseService.currentUserId,
      );

      final data = {
        'user_id': BaseService.currentUserId!,
        'vendor_id': vendorId,
        'vendor_name': vendorName,
        'amount': amount,
        'due_date': invoice.dueDate.toIso8601String().split(
          'T',
        )[0], // Date only
        'status': invoice.status.name,
        'description': invoice.description,
        'invoice_number': invoice.invoiceNumber,
      };

      final response = await BaseService.supabase
          .from(_tableName)
          .insert(data)
          .select('*')
          .single();

      return _fromSupabaseJson(response);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Update an existing invoice
  static Future<Invoice> updateInvoice({
    required String invoiceId,
    String? vendorId,
    double? amount,
    DateTime? dueDate,
    InvoiceStatus? status,
    String? description,
    String? invoiceNumber,
    String? pdfUrl,
  }) async {
    try {
      BaseService.ensureAuthenticated();

      final data = <String, dynamic>{};
      if (vendorId != null) data['vendor_id'] = vendorId;
      if (amount != null) data['amount'] = amount;
      if (dueDate != null) {
        data['due_date'] = dueDate.toIso8601String().split('T')[0];
      }
      if (status != null) data['status'] = status.name;
      if (description != null) data['description'] = description;
      if (invoiceNumber != null) data['invoice_number'] = invoiceNumber;
      if (pdfUrl != null) data['invoice_pdf_url'] = pdfUrl;

      final response = await BaseService.supabase
          .from(_tableName)
          .update(data)
          .eq('id', invoiceId)
          .eq('user_id', BaseService.currentUserId!)
          .select('''
            *,
            vendors!inner(name)
          ''')
          .single();

      return _fromSupabaseJson(response);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Delete an invoice
  static Future<void> deleteInvoice(String invoiceId) async {
    try {
      BaseService.ensureAuthenticated();

      await BaseService.supabase
          .from(_tableName)
          .delete()
          .eq('id', invoiceId)
          .eq('user_id', BaseService.currentUserId!);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Get invoices by status
  static Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    try {
      BaseService.ensureAuthenticated();

      final response = await BaseService.supabase
          .from(_tableName)
          .select('''
            *,
            vendors!inner(name)
          ''')
          .eq('user_id', BaseService.currentUserId!)
          .eq('status', status.name)
          .order('created_at', ascending: false);

      final responseList = response as List<dynamic>;
      return responseList
          .map((item) => _fromSupabaseJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }

  /// Convert Supabase JSON to Invoice model with smart defaults
  static Invoice _fromSupabaseJson(Map<String, dynamic> json) {
    // Extract vendor name from nested vendor object or direct field
    final vendorName =
        json['vendor_name'] as String? ??
        (json['vendors'] != null ? json['vendors']['name'] as String? : null) ??
        'Unknown Vendor';

    return Invoice(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vendorId: json['vendor_id'] as String? ?? 'unknown-vendor',
      vendorName: vendorName,
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: InvoiceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => InvoiceStatus.pending,
      ),
      description: json['description'] as String? ?? 'Payment to $vendorName',
      invoiceNumber:
          json['invoice_number'] as String? ??
          'INV-${json['id']?.toString().substring(0, 8) ?? 'UNKNOWN'}',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      pdfUrl: json['pdf_url'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      transactionId: json['transaction_id'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Update invoice status
  static Future<void> updateInvoiceStatus(
    String invoiceId,
    InvoiceStatus status,
  ) async {
    try {
      BaseService.ensureAuthenticated();

      await BaseService.supabase
          .from(_tableName)
          .update({
            'status': status.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId)
          .eq('user_id', BaseService.currentUserId!);
    } catch (error) {
      throw BaseService.handleError(error);
    }
  }
}
