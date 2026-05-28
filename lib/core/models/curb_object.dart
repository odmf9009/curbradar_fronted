/// Modelo de objeto en la calle para el Frontend Flutter.
///
/// ⚠️ DIFERENCIAS con el modelo del backup (Firestore):
/// - NO usa Timestamp de Firestore — usa DateTime con ISO8601 strings
/// - El ID viene como '_id' (MongoDB ObjectId string) o 'id'
/// - latitude/longitude son campos directos (el backend los descompone del location GeoJSON)
///
/// Ver CLAUDE.md sección 3.1 para reglas de negocio.

enum CurbObjectStatus { available, onMyWay, pickedUp }

class CurbObject {
  final String id;
  final String title;
  final String description;
  final String category;
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final String address;
  final String? locality;
  final CurbObjectStatus status;
  final String postedByUserId;
  final String postedByUserName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastConfirmedAt;
  final String? claimedByUserId;
  final String? claimedByUserName;
  final DateTime? claimedAt;
  final String? claimedUserEta;
  final int views;
  final int confirmations;
  final double estimatedValue;
  final bool isChatEnabled;
  final DateTime? lastMessageAt;
  final String? lastMessageBy;

  CurbObject({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrls,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.locality,
    required this.status,
    required this.postedByUserId,
    required this.postedByUserName,
    required this.createdAt,
    required this.updatedAt,
    required this.lastConfirmedAt,
    this.claimedByUserId,
    this.claimedByUserName,
    this.claimedAt,
    this.claimedUserEta,
    this.views = 0,
    this.confirmations = 0,
    this.estimatedValue = 0.0,
    this.isChatEnabled = true,
    this.lastMessageAt,
    this.lastMessageBy,
  });

  factory CurbObject.fromJson(Map<String, dynamic> json) {
    return CurbObject(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? 'Sin título',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Otros',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? 'Ubicación desconocida',
      locality: json['locality'],
      status: CurbObjectStatus.values.byName(json['status'] ?? 'available'),
      postedByUserId: json['postedByUserId'] ?? '',
      postedByUserName: json['postedByUserName'] ?? 'Usuario',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      lastConfirmedAt: _parseDate(json['lastConfirmedAt']),
      claimedByUserId: json['claimedByUserId'],
      claimedByUserName: json['claimedByUserName'],
      claimedAt: json['claimedAt'] != null ? _parseDate(json['claimedAt']) : null,
      claimedUserEta: json['claimedUserEta'],
      views: json['views'] ?? 0,
      confirmations: json['confirmations'] ?? 0,
      estimatedValue: (json['estimatedValue'] as num?)?.toDouble() ?? 0.0,
      isChatEnabled: json['isChatEnabled'] ?? true,
      lastMessageAt: json['lastMessageAt'] != null ? _parseDate(json['lastMessageAt']) : null,
      lastMessageBy: json['lastMessageBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'locality': locality,
      'estimatedValue': estimatedValue,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  bool get isExpired {
    final expiryLimit = DateTime.now().subtract(const Duration(hours: 48));
    return lastConfirmedAt.isBefore(expiryLimit) && status != CurbObjectStatus.pickedUp;
  }

  bool get isClaimExpired {
    if (status != CurbObjectStatus.onMyWay || claimedAt == null) return false;
    return DateTime.now().difference(claimedAt!).inHours >= 2;
  }

  String get remainingTimeText {
    final expiryTime = lastConfirmedAt.add(const Duration(hours: 48));
    final remaining = expiryTime.difference(DateTime.now());
    if (remaining.isNegative) return 'Expirado';
    if (remaining.inHours >= 1) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    }
    return '${remaining.inMinutes}m';
  }

  String get remainingClaimTimeText {
    if (status != CurbObjectStatus.onMyWay || claimedAt == null) return '';
    final expiryTime = claimedAt!.add(const Duration(hours: 2));
    final remaining = expiryTime.difference(DateTime.now());
    if (remaining.isNegative) return 'Expirado';
    final int h = remaining.inHours;
    final int m = remaining.inMinutes % 60;
    final int s = remaining.inSeconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  CurbObject copyWith({
    String? title,
    String? status,
    String? claimedByUserId,
    String? claimedByUserName,
    DateTime? claimedAt,
    String? claimedUserEta,
    DateTime? lastConfirmedAt,
    int? confirmations,
    // clearClaim=true pone todos los campos de claim a null (cuando status → available)
    bool clearClaim = false,
  }) {
    return CurbObject(
      id: id,
      title: title ?? this.title,
      description: description,
      category: category,
      imageUrls: imageUrls,
      latitude: latitude,
      longitude: longitude,
      address: address,
      locality: locality,
      status: status != null ? CurbObjectStatus.values.byName(status) : this.status,
      postedByUserId: postedByUserId,
      postedByUserName: postedByUserName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastConfirmedAt: lastConfirmedAt ?? this.lastConfirmedAt,
      claimedByUserId: clearClaim ? null : (claimedByUserId ?? this.claimedByUserId),
      claimedByUserName: clearClaim ? null : (claimedByUserName ?? this.claimedByUserName),
      claimedAt: clearClaim ? null : (claimedAt ?? this.claimedAt),
      claimedUserEta: clearClaim ? null : (claimedUserEta ?? this.claimedUserEta),
      views: views,
      confirmations: confirmations ?? this.confirmations,
      estimatedValue: estimatedValue,
      isChatEnabled: isChatEnabled,
      lastMessageAt: lastMessageAt,
      lastMessageBy: lastMessageBy,
    );
  }
}
