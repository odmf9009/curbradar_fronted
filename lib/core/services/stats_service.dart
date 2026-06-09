import '../config/api_config.dart';
import '../models/community_stats_model.dart';
import 'api_service.dart';

class StatsService {
  static final StatsService _instance = StatsService._internal();
  factory StatsService() => _instance;
  StatsService._internal();

  final _api = ApiService();

  Future<CommunityStats> getCommunityStats() async {
    final response = await _api.get(ApiConfig.stats);
    return CommunityStats.fromJson(response.data as Map<String, dynamic>);
  }
}
