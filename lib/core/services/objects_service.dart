import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/curb_object.dart';

/// Servicio para operaciones CRUD de objetos en la calle.
/// Reemplaza las llamadas directas a Firestore por llamadas al backend REST.
class ObjectsService {
  final ApiService _api = ApiService();

  /// Obtiene objetos activos cercanos a [lat, lng] dentro de [radiusMeters].
  Future<List<CurbObject>> getNearbyObjects({
    required double lat,
    required double lng,
    double radiusMeters = 5000,
    String? category,
    String? status,
    String? timeRange,
    String? searchQuery,
  }) async {
    try {
      final response = await _api.get(
        ApiConfig.objects,
        queryParams: {
          'lat': lat,
          'lng': lng,
          'radius': radiusMeters,
          if (category != null && category != 'Todos') 'category': category,
          if (status != null && status != 'all') 'status': status,
          if (timeRange != null && timeRange != 'all') 'timeRange': timeRange,
          if (searchQuery != null && searchQuery.isNotEmpty) 'searchQuery': searchQuery,
        },
      );

      final List<dynamic> data = response.data['objects'] ?? [];
      return data.map((json) => CurbObject.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Obtiene un objeto por ID.
  Future<CurbObject?> getObjectById(String id) async {
    try {
      final response = await _api.get('${ApiConfig.objects}/$id');
      return CurbObject.fromJson(response.data['object']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Crea un nuevo objeto en la calle.
  Future<CurbObject> createObject(Map<String, dynamic> objectData) async {
    try {
      final response = await _api.post(ApiConfig.objects, data: objectData);
      return CurbObject.fromJson(response.data['object']);
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Cambia el estado del objeto (available / onMyWay / pickedUp).
  Future<void> updateStatus(String objectId, String status) async {
    try {
      await _api.patch(
        '${ApiConfig.objects}/$objectId/status',
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Confirma que el objeto sigue ahí (resetea el timer de 48h).
  /// Retorna true si es la primera confirmación del usuario, false si ya había confirmado.
  Future<bool> confirmStillThere(String objectId) async {
    try {
      final response = await _api.post('${ApiConfig.objects}/$objectId/confirm');
      return response.data['firstTime'] == true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) return false; // Ya confirmó
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Actualiza el ETA del usuario que va en camino.
  Future<void> updateEta(String objectId, String eta) async {
    try {
      await _api.patch(
        '${ApiConfig.objects}/$objectId/eta',
        data: {'eta': eta},
      );
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Reporta un objeto por contenido inapropiado.
  Future<void> reportObject(
    String objectId,
    String reason, {
    String? description,
  }) async {
    try {
      await _api.post(
        '${ApiConfig.objects}/$objectId/report',
        data: {'reason': reason, 'description': description ?? ''},
      );
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }
}
