class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImage;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImage,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Usuario',
      userProfileImage: json['userProfileImage'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userProfileImage': userProfileImage,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
