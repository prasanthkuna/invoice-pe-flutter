import 'package:dart_mappable/dart_mappable.dart';

part 'invoice.mapper.dart';

@MappableEnum()
enum InvoiceStatus { draft, pending, paid, overdue, cancelled }

@MappableClass()
class Invoice with InvoiceMappable {
  const Invoice({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.vendorName, // ✅ BUSINESS CRITICAL
    required this.amount, // ✅ BUSINESS CRITICAL
    required this.status, // ✅ BUSINESS CRITICAL
    required this.createdAt, // ✅ AUTO-GENERATED
    required this.description, // ✅ SMART DEFAULT
    required this.invoiceNumber, // ✅ SMART DEFAULT
    required this.dueDate, // ✅ SMART DEFAULT
    this.pdfUrl, // Optional - generated later
    this.paidAt, // Optional - set when paid
    this.transactionId, // Optional - set when paid
    this.updatedAt, // Optional - set on updates
  }); // Optional - set on updates

  /// Factory constructor for quick payments (primary use case)
  /// Only requires business-critical fields, auto-generates the rest
  factory Invoice.forPayment({
    required String vendorId,
    required String vendorName,
    required double amount,
    String? description,
    String? invoiceNumber,
    DateTime? dueDate,
    InvoiceStatus? status,
    String? userId,
  }) {
    final now = DateTime.now();
    final generatedInvoiceNumber =
        invoiceNumber ?? 'INV-${now.millisecondsSinceEpoch}';
    final defaultDescription = description ?? 'Payment to $vendorName';
    final defaultDueDate = dueDate ?? now;

    return Invoice(
      id: '', // Will be set by database
      userId: userId ?? '', // Will be set by service layer
      vendorId: vendorId,
      vendorName: vendorName,
      amount: amount,
      status: status ?? InvoiceStatus.pending,
      createdAt: now,
      description: defaultDescription,
      invoiceNumber: generatedInvoiceNumber,
      dueDate: defaultDueDate,
    );
  }

  /// Factory constructor for formal invoices (secondary use case)
  /// Allows full customization while still providing smart defaults
  factory Invoice.formal({
    required String vendorId,
    required String vendorName,
    required double amount,
    required DateTime dueDate,
    String? description,
    String? invoiceNumber,
    InvoiceStatus? status,
    String? userId,
  }) {
    final now = DateTime.now();
    final generatedInvoiceNumber =
        invoiceNumber ?? 'INV-${now.millisecondsSinceEpoch}';
    final defaultDescription = description ?? 'Invoice for $vendorName';

    return Invoice(
      id: '', // Will be set by database
      userId: userId ?? '', // Will be set by service layer
      vendorId: vendorId,
      vendorName: vendorName,
      amount: amount,
      status: status ?? InvoiceStatus.draft,
      createdAt: now,
      description: defaultDescription,
      invoiceNumber: generatedInvoiceNumber,
      dueDate: dueDate,
    );
  }

  // Business critical fields (always required)
  final String id;
  final String userId;
  final String vendorId;
  final String vendorName; // Required: Can't pay without knowing who
  final double amount; // Required: Can't pay without knowing how much
  final InvoiceStatus status; // Required: Must track payment state
  final DateTime createdAt; // Required: Audit trail

  // Smart defaults (non-nullable but auto-generated if not provided)
  final String description; // Default: "Payment to [vendorName]"
  final String invoiceNumber; // Default: "INV-[timestamp]"
  final DateTime dueDate; // Default: DateTime.now() or +30 days

  // Truly optional fields (nullable - set later in workflow)
  final String? pdfUrl; // Optional - generated after payment
  final DateTime? paidAt; // Optional - set when payment completes
  final String? transactionId; // Optional - set when payment processes
  final DateTime? updatedAt;

  static Invoice fromMap(Map<String, dynamic> map) =>
      InvoiceMapper.fromMap(map);
  static Invoice fromJson(String json) => InvoiceMapper.fromJson(json);
}
