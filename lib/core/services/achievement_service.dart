import '../config/api_config.dart';
import '../models/achievement_model.dart';
import 'api_service.dart';

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final _api = ApiService();

  Future<List<AchievementModel>> getUserAchievements() async {
    final response = await _api.get(ApiConfig.achievements);
    final List<dynamic> raw = response.data['achievements'] ?? [];

    final savedMap = <String, Map<String, dynamic>>{};
    for (final item in raw) {
      savedMap[item['id'] as String] = Map<String, dynamic>.from(item as Map);
    }

    return baseAchievements.map((base) {
      final stored = savedMap[base.id];
      if (stored == null) return base;
      return base.copyWith(
        isUnlocked: stored['isUnlocked'] ?? false,
        progress: (stored['progress'] as num?)?.toDouble() ?? 0.0,
        unlockedAt: stored['unlockedAt'] != null ? DateTime.tryParse(stored['unlockedAt']) : null,
      );
    }).toList();
  }

  Future<void> checkAchievements() async {
    await _api.post(ApiConfig.achievementsCheck, data: {});
  }
}
