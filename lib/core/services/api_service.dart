import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

/// Servicio HTTP base optimizado para CurbRadar.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  bool _useFallback = false;
  bool _domainWorked = false;

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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: (response, handler) {
          _domainWorked = true; 
          handler.next(response);
        },
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken(false);
        options.headers['Authorization'] = 'Bearer $token';
        print('[ApiService] 🔑 Token inyectado para: ${options.path}');
      } else {
        print('[ApiService] ⚠️ Advertencia: No hay usuario logueado para esta petición.');
      }
      
      if (_useFallback && !_domainWorked) {
        options.baseUrl = ApiConfig.fallbackBaseUrl;
      }
    } catch (e) {
      print('[ApiService] ❌ Error obteniendo token: $e');
    }
    
    print('[ApiService] 📡 Solicitud: ${options.method} ${options.baseUrl}${options.path}');
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('[ApiService] ❌ Error [${err.response?.statusCode}]: ${err.requestOptions.method} ${err.requestOptions.path}');
    
    if (err.response?.data != null) {
      print('[ApiService] 📄 Cuerpo de la respuesta de error:');
      print(err.response?.data);
    } else {
      print('[ApiService] 📄 El servidor no envió cuerpo de respuesta.');
    }
    
    if (err.response?.statusCode == 401) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final newToken = await user.getIdToken(true);
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (e) {}
    }

    final errorStr = err.toString().toLowerCase();
    if ((errorStr.contains('failed host lookup') || errorStr.contains('errno = 7')) && !_domainWorked) {
      print('[ApiService] 🆘 Fallo de DNS. Activando respaldo por IP...');
      _useFallback = true;
      try {
        final options = err.requestOptions;
        options.baseUrl = ApiConfig.fallbackBaseUrl;
        final response = await _dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {}
    }

    handler.next(err);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) => _dio.get(path, queryParameters: queryParams);
  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);
  Future<Response> patch(String path, {dynamic data}) => _dio.patch(path, data: data);
  Future<Response> delete(String path, {dynamic data}) => _dio.delete(path, data: data);

  static String extractErrorMessage(DioException e) {
    if (e.response?.data is Map) {
      return (e.response?.data as Map)['error']?.toString() ?? 'Error del servidor';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Sin conexión al servidor. Verifica que el backend esté activo.';
    }
    
    // Incluye el body real para ayudar a diagnosticar (ej: HTML de Nginx)
    final status = e.response?.statusCode;
    final body = e.response?.data?.toString() ?? '';
    final bodySnippet = body.length > 200 ? body.substring(0, 200) : body;
    if (status != null && bodySnippet.isNotEmpty) {
      return 'HTTP $status — $bodySnippet';
    }
    
    return e.message ?? 'Error de conexión. Verifica tu internet.';
  }
}
