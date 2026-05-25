import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

/// Servicio HTTP base que maneja:
/// - Inyección automática del Bearer Token de Firebase en cada request
/// - Refresh del token si expira (401)
/// - Manejo centralizado de errores
///
/// ⭐ TODOS los servicios deben usar este cliente, nunca crear Dio directamente.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor: agrega el token en cada request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  /// Agrega el Firebase ID Token al header Authorization automáticamente.
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // forceRefresh: false usa el token cacheado si sigue válido
        final token = await user.getIdToken(false);
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      // Si no hay usuario logueado, continúa sin token
    }
    handler.next(options);
  }

  /// Si el server responde 401, refresca el token y reintenta 1 vez.
  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final newToken = await user.getIdToken(true); // forceRefresh
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (e) {
        // Si el refresh falla, propagar el error
      }
    }
    handler.next(err);
  }

  // ─── Métodos HTTP ──────────────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) {
    return _dio.delete(path, data: data);
  }

  /// Sube un archivo multipart (imagen) al backend.
  Future<Response> uploadFile(String path, String filePath, {Map<String, dynamic>? fields}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      ...?fields,
    });
    return _dio.post(path, data: formData);
  }

  /// Extrae el mensaje de error de una DioException de forma legible.
  static String extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      return (e.response?.data as Map)['error']?.toString() ??
          'Error del servidor';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sin conexión al servidor. Verifica que el backend esté activo.';
    }
    return e.message ?? 'Error desconocido';
  }
}
