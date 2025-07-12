import 'package:dart_mappable/dart_mappable.dart';

part 'user_card.mapper.dart';

@MappableEnum()
enum CardType { visa, mastercard, rupay, amex, discover, other }

@MappableClass()
class UserCard with UserCardMappable {
  const UserCard({
    required this.id,
    required this.userId,
    required this.cardToken,
    required this.cardLastFour,
    required this.cardType,
    this.cardNetwork,
    required this.isDefault,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String cardToken; // PhonePe masked card token
  final String cardLastFour; // Last 4 digits for display
  final CardType cardType;
  final String? cardNetwork;
  final bool isDefault;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static const fromMap = UserCardMapper.fromMap;
  static const fromJson = UserCardMapper.fromJson;
}
