class RequestModel {
  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;
  final String city;
  final double latitude;
  final double longitude;
  final bool isResolved;

  RequestModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.isResolved = false,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Cazador',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'Otros',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      city: json['city'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      isResolved: json['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'isResolved': isResolved,
    };
  }
}
