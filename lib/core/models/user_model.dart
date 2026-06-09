/// Modelo de usuario para el Frontend Flutter.
/// Sin dependencia de Firestore — deserializa JSON del backend.
class UserModel {
  final String id;           // MongoDB _id
  final String firebaseUid;  // UID de Firebase Auth
  final String name;
  final String username;
  final String email;
  final String profileImageUrl;
  final int points;
  final int level;
  final String levelTitle;
  final int postsCount;
  final int foundCount;
  final int confirmationsCount;
  final int chatMessagesCount;
  final double totalImpactValue;
  final List<String> favorites;
  final List<String> redeemedRewards;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final String role;
  // Referral fields
  final String referralCode;
  final String? referredBy;
  final int referralCount;
  final int successfulReferrals;
  final int referralXpEarned;

  UserModel({
    required this.id,
    required this.firebaseUid,
    required this.name,
    this.username = '',
    required this.email,
    this.profileImageUrl = '',
    this.points = 0,
    this.level = 1,
    this.levelTitle = 'Explorador',
    this.postsCount = 0,
    this.foundCount = 0,
    this.confirmationsCount = 0,
    this.chatMessagesCount = 0,
    this.totalImpactValue = 0.0,
    this.favorites = const [],
    this.redeemedRewards = const [],
    this.isOnline = false,
    this.latitude,
    this.longitude,
    this.role = 'user',
    this.referralCode = '',
    this.referredBy,
    this.referralCount = 0,
    this.successfulReferrals = 0,
    this.referralXpEarned = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      firebaseUid: json['firebaseUid'] ?? '',
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'] ?? '',
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      levelTitle: json['levelTitle'] ?? 'Explorador',
      postsCount: json['postsCount'] ?? 0,
      foundCount: json['foundCount'] ?? 0,
      confirmationsCount: json['confirmationsCount'] ?? 0,
      chatMessagesCount: json['chatMessagesCount'] ?? 0,
      totalImpactValue: (json['totalImpactValue'] as num?)?.toDouble() ?? 0.0,
      favorites: List<String>.from(json['favorites'] ?? []),
      redeemedRewards: List<String>.from(json['redeemedRewards'] ?? []),
      isOnline: json['isOnline'] ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      role: json['role'] ?? 'user',
      referralCode: json['referralCode'] ?? '',
      referredBy: json['referredBy'],
      referralCount: json['referralCount'] ?? 0,
      successfulReferrals: json['successfulReferrals'] ?? 0,
      referralXpEarned: json['referralXpEarned'] ?? 0,
    );
  }

  double get levelProgress => (points % 500) / 500.0;

  String get displayName => username.isNotEmpty ? username : 'Cazador Anónimo';
  bool get isAdmin => role == 'admin';

  double get reliability {
    if (postsCount == 0) return 100.0;
    return (confirmationsCount / (postsCount + foundCount + 1)) * 100;
  }
}
