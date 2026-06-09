import '../config/api_config.dart';
import '../models/reward_model.dart';
import 'api_service.dart';

class RewardsService {
  static final RewardsService _instance = RewardsService._internal();
  factory RewardsService() => _instance;
  RewardsService._internal();

  final _api = ApiService();

  Future<List<RewardItem>> getAvailableRewards() async {
    final response = await _api.get(ApiConfig.rewards);
    final List<dynamic> raw = response.data['rewards'] ?? [];
    return raw.map((e) => RewardItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<XPTransaction>> getXPHistory({int limit = 20}) async {
    final response = await _api.get(ApiConfig.rewardsXpHistory, queryParams: {'limit': limit});
    final List<dynamic> raw = response.data['transactions'] ?? [];
    return raw.map((e) => XPTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> redeemReward(String itemId) async {
    final response = await _api.post('${ApiConfig.rewardsRedeem}/$itemId', data: {});
    return response.data['newPoints'] as int? ?? 0;
  }
}
