import 'package:flutter/material.dart';

enum ActivityType {
  publish,
  collect,
  confirm,
  onMyWay,
  photoUpdate,
  achievement,
  levelUp,
  rankingEntry,
  communityAppreciation,
  objectCollectedByOther,
  pointsRedeemed,
}

class ActivityModel {
  final String id;
  final String title;
  final String description;
  final int points;
  final ActivityType type;
  final DateTime createdAt;
  final String? objectId;
  final Map<String, dynamic> metadata;

  ActivityModel({
    required this.id,
    required this.title,
    required this.description,
    this.points = 0,
    required this.type,
    required this.createdAt,
    this.objectId,
    this.metadata = const {},
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      type: ActivityType.values.byName(json['type'] ?? 'publish'),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      objectId: json['objectId'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  IconData get icon {
    switch (type) {
      case ActivityType.publish:               return Icons.add_a_photo;
      case ActivityType.collect:               return Icons.shopping_bag;
      case ActivityType.confirm:               return Icons.check_circle_outline;
      case ActivityType.onMyWay:               return Icons.directions_car;
      case ActivityType.photoUpdate:           return Icons.refresh;
      case ActivityType.achievement:           return Icons.emoji_events;
      case ActivityType.levelUp:               return Icons.trending_up;
      case ActivityType.rankingEntry:          return Icons.leaderboard;
      case ActivityType.communityAppreciation: return Icons.favorite;
      case ActivityType.objectCollectedByOther:return Icons.volunteer_activism;
      case ActivityType.pointsRedeemed:        return Icons.card_giftcard;
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.publish:               return Colors.orange;
      case ActivityType.collect:               return Colors.green;
      case ActivityType.confirm:               return Colors.blue;
      case ActivityType.onMyWay:               return Colors.indigo;
      case ActivityType.photoUpdate:           return Colors.cyan;
      case ActivityType.achievement:           return Colors.amber;
      case ActivityType.levelUp:               return Colors.purple;
      case ActivityType.rankingEntry:          return Colors.deepPurple;
      case ActivityType.communityAppreciation: return Colors.red;
      case ActivityType.objectCollectedByOther:return Colors.teal;
      case ActivityType.pointsRedeemed:        return Colors.pink;
    }
  }
}
