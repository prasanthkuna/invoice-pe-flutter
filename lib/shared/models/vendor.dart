import 'package:dart_mappable/dart_mappable.dart';

part 'vendor.mapper.dart';

@MappableClass()
class Vendor with VendorMappable {
  const Vendor({
    required this.id,
    required this.userId,
    required this.name,
    required this.accountNumber,
    required this.ifscCode,
    this.upiId,
    this.email,
    this.phone,
    this.address,
    this.gstin,
    this.logoUrl,
    this.totalPaid = 0.0,
    this.transactionCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String accountNumber;
  final String ifscCode;
  final String? upiId;
  final String? email;
  final String? phone;
  final String? address;
  final String? gstin;
  final String? logoUrl;
  final double totalPaid;
  final int transactionCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static Vendor fromMap(Map<String, dynamic> map) => VendorMapper.fromMap(map);
  static Vendor fromJson(String json) => VendorMapper.fromJson(json);
}
