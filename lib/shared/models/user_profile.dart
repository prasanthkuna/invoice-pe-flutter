import 'package:dart_mappable/dart_mappable.dart';

part 'user_profile.mapper.dart';

@MappableClass()
class UserProfile with UserProfileMappable {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.businessName,
    this.gstin,
    this.email,
    this.address,
    this.totalRewards = 0.0,
    this.totalPayments = 0.0,
    this.totalTransactions = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String phone;
  final String businessName;
  final String? gstin;
  final String? email;
  final String? address;
  final double totalRewards;
  final double totalPayments;
  final int totalTransactions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static UserProfile fromMap(Map<String, dynamic> map) => UserProfileMapper.fromMap(map);
  static UserProfile fromJson(String json) => UserProfileMapper.fromJson(json);
}
