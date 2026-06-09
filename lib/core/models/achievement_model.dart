import 'package:flutter/material.dart';

enum AchievementCategory { posting, finding, community, social, special }

class AchievementModel {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final bool isUnlocked;
  final double progress;
  final DateTime? unlockedAt;
  final int targetValue;
  final AchievementCategory category;

  AchievementModel({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedAt,
    this.targetValue = 1,
    this.category = AchievementCategory.special,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final base = _baseForId(id);
    return AchievementModel(
      id: id,
      titleKey: base.titleKey,
      descriptionKey: base.descriptionKey,
      icon: base.icon,
      isUnlocked: json['isUnlocked'] ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt']) : null,
      targetValue: json['targetValue'] ?? base.targetValue,
      category: base.category,
    );
  }

  AchievementModel copyWith({bool? isUnlocked, double? progress, DateTime? unlockedAt}) {
    return AchievementModel(
      id: id,
      titleKey: titleKey,
      descriptionKey: descriptionKey,
      icon: icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      targetValue: targetValue,
      category: category,
    );
  }

  static AchievementModel _baseForId(String id) {
    return baseAchievements.firstWhere((a) => a.id == id, orElse: () => AchievementModel(id: id, titleKey: id, descriptionKey: id, icon: Icons.star));
  }
}

final List<AchievementModel> baseAchievements = [
  // Posting (10)
  AchievementModel(id: 'post_1',    titleKey: 'ach_post_1_t',    descriptionKey: 'ach_post_1_d',    icon: Icons.upload_file,       targetValue: 1,    category: AchievementCategory.posting),
  AchievementModel(id: 'post_5',    titleKey: 'ach_post_5_t',    descriptionKey: 'ach_post_5_d',    icon: Icons.history_edu,       targetValue: 5,    category: AchievementCategory.posting),
  AchievementModel(id: 'post_10',   titleKey: 'ach_post_10_t',   descriptionKey: 'ach_post_10_d',   icon: Icons.explore,           targetValue: 10,   category: AchievementCategory.posting),
  AchievementModel(id: 'post_25',   titleKey: 'ach_post_25_t',   descriptionKey: 'ach_post_25_d',   icon: Icons.map,               targetValue: 25,   category: AchievementCategory.posting),
  AchievementModel(id: 'post_50',   titleKey: 'ach_post_50_t',   descriptionKey: 'ach_post_50_d',   icon: Icons.location_on,       targetValue: 50,   category: AchievementCategory.posting),
  AchievementModel(id: 'post_100',  titleKey: 'ach_post_100_t',  descriptionKey: 'ach_post_100_d',  icon: Icons.architecture,      targetValue: 100,  category: AchievementCategory.posting),
  AchievementModel(id: 'post_200',  titleKey: 'ach_post_200_t',  descriptionKey: 'ach_post_200_d',  icon: Icons.edit_note,         targetValue: 200,  category: AchievementCategory.posting),
  AchievementModel(id: 'post_350',  titleKey: 'ach_post_350_t',  descriptionKey: 'ach_post_350_d',  icon: Icons.auto_stories,      targetValue: 350,  category: AchievementCategory.posting),
  AchievementModel(id: 'post_500',  titleKey: 'ach_post_500_t',  descriptionKey: 'ach_post_500_d',  icon: Icons.castle,            targetValue: 500,  category: AchievementCategory.posting),
  AchievementModel(id: 'post_1000', titleKey: 'ach_post_1000_t', descriptionKey: 'ach_post_1000_d', icon: Icons.fort,              targetValue: 1000, category: AchievementCategory.posting),
  // Finding (10)
  AchievementModel(id: 'find_1',    titleKey: 'ach_find_1_t',    descriptionKey: 'ach_find_1_d',    icon: Icons.shopping_bag,      targetValue: 1,    category: AchievementCategory.finding),
  AchievementModel(id: 'find_5',    titleKey: 'ach_find_5_t',    descriptionKey: 'ach_find_5_d',    icon: Icons.inventory_2,       targetValue: 5,    category: AchievementCategory.finding),
  AchievementModel(id: 'find_15',   titleKey: 'ach_find_15_t',   descriptionKey: 'ach_find_15_d',   icon: Icons.cleaning_services, targetValue: 15,   category: AchievementCategory.finding),
  AchievementModel(id: 'find_30',   titleKey: 'ach_find_30_t',   descriptionKey: 'ach_find_30_d',   icon: Icons.eco,               targetValue: 30,   category: AchievementCategory.finding),
  AchievementModel(id: 'find_60',   titleKey: 'ach_find_60_t',   descriptionKey: 'ach_find_60_d',   icon: Icons.recycling,         targetValue: 60,   category: AchievementCategory.finding),
  AchievementModel(id: 'find_100',  titleKey: 'ach_find_100_t',  descriptionKey: 'ach_find_100_d',  icon: Icons.nature_people,     targetValue: 100,  category: AchievementCategory.finding),
  AchievementModel(id: 'find_200',  titleKey: 'ach_find_200_t',  descriptionKey: 'ach_find_200_d',  icon: Icons.park,              targetValue: 200,  category: AchievementCategory.finding),
  AchievementModel(id: 'find_350',  titleKey: 'ach_find_350_t',  descriptionKey: 'ach_find_350_d',  icon: Icons.public,            targetValue: 350,  category: AchievementCategory.finding),
  AchievementModel(id: 'find_500',  titleKey: 'ach_find_500_t',  descriptionKey: 'ach_find_500_d',  icon: Icons.wb_sunny,          targetValue: 500,  category: AchievementCategory.finding),
  AchievementModel(id: 'find_1000', titleKey: 'ach_find_1000_t', descriptionKey: 'ach_find_1000_d', icon: Icons.language,          targetValue: 1000, category: AchievementCategory.finding),
  // Community (10)
  AchievementModel(id: 'conf_5',    titleKey: 'ach_conf_5_t',    descriptionKey: 'ach_conf_5_d',    icon: Icons.check_circle_outline, targetValue: 5,    category: AchievementCategory.community),
  AchievementModel(id: 'conf_15',   titleKey: 'ach_conf_15_t',   descriptionKey: 'ach_conf_15_d',   icon: Icons.visibility,           targetValue: 15,   category: AchievementCategory.community),
  AchievementModel(id: 'conf_30',   titleKey: 'ach_conf_30_t',   descriptionKey: 'ach_conf_30_d',   icon: Icons.fact_check,           targetValue: 30,   category: AchievementCategory.community),
  AchievementModel(id: 'conf_60',   titleKey: 'ach_conf_60_t',   descriptionKey: 'ach_conf_60_d',   icon: Icons.verified,             targetValue: 60,   category: AchievementCategory.community),
  AchievementModel(id: 'conf_100',  titleKey: 'ach_conf_100_t',  descriptionKey: 'ach_conf_100_d',  icon: Icons.groups,               targetValue: 100,  category: AchievementCategory.community),
  AchievementModel(id: 'conf_200',  titleKey: 'ach_conf_200_t',  descriptionKey: 'ach_conf_200_d',  icon: Icons.psychology,           targetValue: 200,  category: AchievementCategory.community),
  AchievementModel(id: 'conf_350',  titleKey: 'ach_conf_350_t',  descriptionKey: 'ach_conf_350_d',  icon: Icons.auto_awesome,         targetValue: 350,  category: AchievementCategory.community),
  AchievementModel(id: 'conf_500',  titleKey: 'ach_conf_500_t',  descriptionKey: 'ach_conf_500_d',  icon: Icons.all_inclusive,        targetValue: 500,  category: AchievementCategory.community),
  AchievementModel(id: 'conf_750',  titleKey: 'ach_conf_750_t',  descriptionKey: 'ach_conf_750_d',  icon: Icons.brightness_high,      targetValue: 750,  category: AchievementCategory.community),
  AchievementModel(id: 'conf_1000', titleKey: 'ach_conf_1000_t', descriptionKey: 'ach_conf_1000_d', icon: Icons.self_improvement,     targetValue: 1000, category: AchievementCategory.community),
  // Social (10)
  AchievementModel(id: 'msg_10',   titleKey: 'ach_msg_10_t',   descriptionKey: 'ach_msg_10_d',   icon: Icons.chat_bubble_outline,  targetValue: 10,   category: AchievementCategory.social),
  AchievementModel(id: 'msg_50',   titleKey: 'ach_msg_50_t',   descriptionKey: 'ach_msg_50_d',   icon: Icons.forum,                targetValue: 50,   category: AchievementCategory.social),
  AchievementModel(id: 'msg_100',  titleKey: 'ach_msg_100_t',  descriptionKey: 'ach_msg_100_d',  icon: Icons.question_answer,      targetValue: 100,  category: AchievementCategory.social),
  AchievementModel(id: 'msg_250',  titleKey: 'ach_msg_250_t',  descriptionKey: 'ach_msg_250_d',  icon: Icons.connect_without_contact, targetValue: 250, category: AchievementCategory.social),
  AchievementModel(id: 'msg_500',  titleKey: 'ach_msg_500_t',  descriptionKey: 'ach_msg_500_d',  icon: Icons.speaker_notes,        targetValue: 500,  category: AchievementCategory.social),
  AchievementModel(id: 'msg_750',  titleKey: 'ach_msg_750_t',  descriptionKey: 'ach_msg_750_d',  icon: Icons.record_voice_over,    targetValue: 750,  category: AchievementCategory.social),
  AchievementModel(id: 'msg_1000', titleKey: 'ach_msg_1000_t', descriptionKey: 'ach_msg_1000_d', icon: Icons.support_agent,        targetValue: 1000, category: AchievementCategory.social),
  AchievementModel(id: 'msg_2000', titleKey: 'ach_msg_2000_t', descriptionKey: 'ach_msg_2000_d', icon: Icons.hub,                  targetValue: 2000, category: AchievementCategory.social),
  AchievementModel(id: 'msg_3500', titleKey: 'ach_msg_3500_t', descriptionKey: 'ach_msg_3500_d', icon: Icons.campaign,             targetValue: 3500, category: AchievementCategory.social),
  AchievementModel(id: 'msg_5000', titleKey: 'ach_msg_5000_t', descriptionKey: 'ach_msg_5000_d', icon: Icons.announcement,         targetValue: 5000, category: AchievementCategory.social),
  // Special (10)
  AchievementModel(id: 'level_5',      titleKey: 'ach_level_5_t',      descriptionKey: 'ach_level_5_d',      icon: Icons.filter_5,              targetValue: 5,     category: AchievementCategory.special),
  AchievementModel(id: 'level_10',     titleKey: 'ach_level_10_t',     descriptionKey: 'ach_level_10_d',     icon: Icons.stars,                 targetValue: 10,    category: AchievementCategory.special),
  AchievementModel(id: 'level_25',     titleKey: 'ach_level_25_t',     descriptionKey: 'ach_level_25_d',     icon: Icons.military_tech,         targetValue: 25,    category: AchievementCategory.special),
  AchievementModel(id: 'level_50',     titleKey: 'ach_level_50_t',     descriptionKey: 'ach_level_50_d',     icon: Icons.workspace_premium,     targetValue: 50,    category: AchievementCategory.special),
  AchievementModel(id: 'level_100',    titleKey: 'ach_level_100_t',    descriptionKey: 'ach_level_100_d',    icon: Icons.diamond,               targetValue: 100,   category: AchievementCategory.special),
  AchievementModel(id: 'impact_100',   titleKey: 'ach_impact_100_t',   descriptionKey: 'ach_impact_100_d',   icon: Icons.attach_money,          targetValue: 100,   category: AchievementCategory.special),
  AchievementModel(id: 'impact_500',   titleKey: 'ach_impact_500_t',   descriptionKey: 'ach_impact_500_d',   icon: Icons.payments,              targetValue: 500,   category: AchievementCategory.special),
  AchievementModel(id: 'impact_1000',  titleKey: 'ach_impact_1000_t',  descriptionKey: 'ach_impact_1000_d',  icon: Icons.savings,               targetValue: 1000,  category: AchievementCategory.special),
  AchievementModel(id: 'impact_5000',  titleKey: 'ach_impact_5000_t',  descriptionKey: 'ach_impact_5000_d',  icon: Icons.account_balance,       targetValue: 5000,  category: AchievementCategory.special),
  AchievementModel(id: 'impact_10000', titleKey: 'ach_impact_10000_t', descriptionKey: 'ach_impact_10000_d', icon: Icons.account_balance_wallet, targetValue: 10000, category: AchievementCategory.special),
];
