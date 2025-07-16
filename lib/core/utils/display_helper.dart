import '../../shared/models/vendor.dart';
import '../../shared/models/invoice.dart';

/// Tesla-grade display utility - consistent null-safe formatting
class DisplayHelper {
  /// Format vendor info with null safety
  static String formatVendorInfo(Vendor vendor) {
    final parts = <String>[];

    if (vendor.phone != null && vendor.phone!.isNotEmpty) {
      parts.add('Phone: ${vendor.phone}');
    }

    if (vendor.email != null && vendor.email!.isNotEmpty) {
      parts.add(vendor.email!);
    }

    return parts.isNotEmpty ? parts.join(' • ') : 'No contact info';
  }

  /// Format nullable string with default
  static String formatNullable(String? value, String defaultText) {
    return (value?.isNotEmpty ?? false) ? value! : defaultText;
  }

  /// Format phone number with fallback
  static String formatPhone(String? phone) {
    return formatNullable(phone, 'No phone');
  }

  /// Format email with fallback
  static String formatEmail(String? email) {
    return formatNullable(email, 'No email');
  }

  /// Get vendor display name from invoice or vendor
  static String getVendorName(Invoice? invoice, Vendor? vendor) {
    return invoice?.vendorName ?? vendor?.name ?? 'Unknown Vendor';
  }

  /// Get vendor initial for avatar
  static String getVendorInitial(Invoice? invoice, Vendor? vendor) {
    final name = getVendorName(invoice, vendor);
    return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
  }
}
