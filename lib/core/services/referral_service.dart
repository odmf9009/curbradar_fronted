import '../config/api_config.dart';
import 'api_service.dart';

class ReferralService {
  static final ReferralService _instance = ReferralService._internal();
  factory ReferralService() => _instance;
  ReferralService._internal();

  final _api = ApiService();

  Future<String> getMyCode() async {
    final response = await _api.get(ApiConfig.referralsCode);
    return response.data['referralCode'] as String;
  }

  Future<bool> validateCode(String code) async {
    try {
      final response = await _api.post(ApiConfig.referralsValidate, data: {'code': code});
      return response.data['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> processReferral(String referralCode) async {
    await _api.post(ApiConfig.referralsProcess, data: {'referralCode': referralCode});
  }

  Future<void> trackFirstPost() async {
    await _api.post(ApiConfig.referralsTrackFirstPost, data: {});
  }

  Future<void> trackCollection() async {
    await _api.post(ApiConfig.referralsTrackCollection, data: {});
  }

  Future<List<Map<String, dynamic>>> getReferralHistory() async {
    final response = await _api.get(ApiConfig.referralsHistory);
    final List<dynamic> raw = response.data['referrals'] ?? [];
    return raw.cast<Map<String, dynamic>>();
  }
}
