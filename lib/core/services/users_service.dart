import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/curb_object.dart';

/// Servicio para operaciones de perfil de usuario, ranking y favoritos.
class UsersService {
  final ApiService _api = ApiService();

  /// Obtiene el perfil propio del usuario autenticado.
  Future<UserModel?> getMyProfile() async {
    try {
      final response = await _api.get('${ApiConfig.users}/me');
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Actualiza el alias (username) o foto de perfil.
  Future<UserModel?> updateProfile({String? username, String? profileImageUrl}) async {
    try {
      final response = await _api.patch(
        '${ApiConfig.users}/me',
        data: {
          if (username != null) 'username': username,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        },
      );
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Actualiza la ubicación del usuario en tiempo real.
  Future<void> updateLocation(double latitude, double longitude, {bool isOnline = true}) async {
    try {
      await _api.patch(
        '${ApiConfig.users}/me/location',
        data: {'latitude': latitude, 'longitude': longitude, 'isOnline': isOnline},
      );
    } on DioException catch (_) {
      // Silencioso — no bloquear el flujo si falla la actualización de ubicación
    }
  }

  /// Obtiene el ranking global de usuarios.
  Future<List<UserModel>> getRanking({int limit = 50}) async {
    try {
      final response = await _api.get(
        '${ApiConfig.users}/ranking',
        queryParams: {'limit': limit},
      );
      final List<dynamic> data = response.data['users'] ?? [];
      return data.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Obtiene el perfil público de otro usuario.
  Future<UserModel?> getPublicProfile(String firebaseUid) async {
    try {
      final response = await _api.get('${ApiConfig.users}/$firebaseUid');
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Toggle de favorito (guardar/quitar objeto).
  Future<void> toggleFavorite(String objectId, {required bool isFavorite}) async {
    try {
      await _api.patch(
        '${ApiConfig.users}/me/favorites/$objectId',
        data: {'isFavorite': isFavorite},
      );
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Obtiene los objetos guardados como favoritos.
  Future<List<CurbObject>> getFavoriteObjects() async {
    try {
      final response = await _api.get('${ApiConfig.users}/me/favorites');
      final List<dynamic> data = response.data['objects'] ?? [];
      return data.map((json) => CurbObject.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Obtiene las publicaciones propias del usuario.
  Future<List<CurbObject>> getMyObjects() async {
    try {
      final response = await _api.get('${ApiConfig.users}/me/objects');
      final List<dynamic> data = response.data['objects'] ?? [];
      return data.map((json) => CurbObject.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Obtiene los cazadores activos (online) con sus ubicaciones.
  Future<List<UserModel>> getActiveHunters() async {
    try {
      final response = await _api.get('${ApiConfig.users}/active-hunters');
      final List<dynamic> data = response.data['hunters'] ?? [];
      return data.map((json) => UserModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }
}
