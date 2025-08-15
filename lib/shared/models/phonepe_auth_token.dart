import 'package:dart_mappable/dart_mappable.dart';

part 'phonepe_auth_token.mapper.dart';

@MappableClass()
class PhonePeAuthToken with PhonePeAuthTokenMappable {
  const PhonePeAuthToken({
    required this.id,
    required this.accessToken,
    required this.expiresAt,
    this.tokenType = 'Bearer',
    this.isActive = true,
    this.createdAt,
  });

  final String id;
  final String accessToken;
  final String tokenType;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime? createdAt;

  /// Check if token is expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Check if token is valid (active and not expired)
  bool get isValid => isActive && !isExpired;

  /// Get authorization header value
  String get authorizationHeader => '$tokenType $accessToken';

  /// Time until token expires (in minutes)
  int get minutesUntilExpiry {
    if (isExpired) return 0;
    return expiresAt.difference(DateTime.now()).inMinutes;
  }

  /// Check if token needs refresh (expires in less than 5 minutes)
  bool get needsRefresh => minutesUntilExpiry < 5;

  static const PhonePeAuthToken Function(Map<String, dynamic> map) fromMap =
      PhonePeAuthTokenMapper.fromMap;
  static const PhonePeAuthToken Function(String json) fromJson =
      PhonePeAuthTokenMapper.fromJson;
}
