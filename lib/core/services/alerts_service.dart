import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class AlertModel {
  final String id;
  final String objectId;
  final String objectTitle;
  final String objectImageUrl;
  final String address;
  final double distance;
  final DateTime createdAt;
  bool isRead;

  AlertModel({
    required this.id,
    required this.objectId,
    required this.objectTitle,
    required this.objectImageUrl,
    required this.address,
    required this.distance,
    required this.createdAt,
    this.isRead = false,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      objectId: json['objectId']?.toString() ?? '',
      objectTitle: json['objectTitle'] ?? 'Objeto detectado',
      objectImageUrl: json['objectImageUrl'] ?? '',
      address: json['address'] ?? '',
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
    );
  }
}

/// Servicio para gestionar alertas de proximidad del usuario.
class AlertsService {
  final ApiService _api = ApiService();

  /// Obtiene todas las alertas del usuario autenticado.
  Future<List<AlertModel>> getMyAlerts() async {
    try {
      final response = await _api.get(ApiConfig.alerts);
      final List<dynamic> data = response.data['alerts'] ?? [];
      return data.map((json) => AlertModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Marca una alerta como leída.
  Future<void> markAsRead(String alertId) async {
    try {
      await _api.patch('${ApiConfig.alerts}/$alertId/read');
    } on DioException catch (_) {
      // Silencioso — no bloquear la UI si falla
    }
  }

  /// Marca todas las alertas como leídas.
  Future<void> markAllAsRead() async {
    try {
      await _api.patch('${ApiConfig.alerts}/read-all');
    } on DioException catch (_) {
      // Silencioso
    }
  }
}
