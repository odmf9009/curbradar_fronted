import '../config/api_config.dart';
import '../models/activity_model.dart';
import 'api_service.dart';

class ActivityService {
  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  final _api = ApiService();

  Future<List<ActivityModel>> getMyActivities({int limit = 50}) async {
    final response = await _api.get(ApiConfig.activity, queryParams: {'limit': limit});
    final List<dynamic> raw = response.data['activities'] ?? [];
    return raw.map((e) => ActivityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ActivityModel> logActivity({
    required String title,
    required String type,
    String description = '',
    int points = 0,
    String? objectId,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _api.post(ApiConfig.activity, data: {
      'title': title,
      'type': type,
      'description': description,
      'points': points,
      if (objectId != null) 'objectId': objectId,
      if (metadata != null) 'metadata': metadata,
    });
    return ActivityModel.fromJson(response.data['activity'] as Map<String, dynamic>);
  }
}
