import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';

/// Servicio de subida de imágenes.
///
/// ⭐ ARQUITECTURA HÍBRIDA:
///   - Antes: Flutter subía imágenes DIRECTAMENTE a Firebase Storage
///     (requería credenciales en el cliente)
///   - Ahora: Flutter envía la imagen al BACKEND → el backend la sube a
///     Firebase Storage con el Admin SDK → devuelve la URL pública
///
/// Firebase Storage sigue siendo el storage (gratuito y confiable),
/// pero el cliente NUNCA toca credenciales de Storage directamente.
class UploadService {
  final ApiService _api = ApiService();

  /// Sube una imagen de objeto (foto de algo en la calle).
  /// [imageFile] — Archivo de imagen tomado con image_picker
  /// Retorna la URL pública de Firebase Storage.
  Future<String> uploadObjectImage(File imageFile) async {
    return _upload(imageFile, folder: 'objects');
  }

  /// Sube una imagen de perfil de usuario.
  Future<String> uploadProfileImage(File imageFile) async {
    return _upload(imageFile, folder: 'profiles');
  }

  Future<String> _upload(File imageFile, {required String folder}) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final mimeType = _getMimeType(fileName);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
        'folder': folder,
      });

      // Usar Dio directamente con los headers del ApiService
      // pero como FormData (multipart)
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {'Accept': 'application/json'},
        ),
      );

      // Inyectar el token de Firebase manualmente
      final token = await _getFirebaseToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post(
        '${ApiConfig.upload}/image',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final url = response.data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('El servidor no devolvió una URL válida');
      }

      return url;
    } on DioException catch (e) {
      throw Exception('Error al subir imagen: ${ApiService.extractErrorMessage(e)}');
    }
  }

  Future<String?> _getFirebaseToken() async {
    try {
      // Import inline para no crear dependencia circular
      final auth = await _getFirebaseAuth();
      return await auth?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  // Obtiene la instancia de FirebaseAuth dinámicamente
  Future<dynamic> _getFirebaseAuth() async {
    try {
      // ignore: avoid_dynamic_calls
      final firebaseAuth = await Future.value(
        // FirebaseAuth.instance.currentUser — accedemos via reflexión para evitar imports circulares
        null, // Reemplazar con FirebaseAuth.instance.currentUser en implementación real
      );
      return firebaseAuth;
    } catch (_) {
      return null;
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
