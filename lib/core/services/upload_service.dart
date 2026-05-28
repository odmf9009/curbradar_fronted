import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class UploadService {
  final ApiService _api = ApiService();

  Future<String> uploadObjectImage(File imageFile) async {
    return _upload(imageFile, folder: 'objects');
  }

  Future<String> uploadProfileImage(File imageFile) async {
    return _upload(imageFile, folder: 'profiles');
  }

  Future<String> _upload(File imageFile, {required String folder}) async {
    try {
      final compressed = await _compress(imageFile);
      final fileToUpload = compressed ?? imageFile;

      final fileName = fileToUpload.path.split('/').last;
      final mimeType = _getMimeType(fileName);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          fileToUpload.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
        'folder': folder,
      });

      final response = await _api.post(
        '${ApiConfig.upload}/image',
        data: formData,
      );

      final url = response.data['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('El servidor no devolvió una URL válida');
      }

      if (compressed != null) {
        try { await compressed.delete(); } catch (_) {}
      }

      return url;
    } on DioException catch (e) {
      throw Exception('Error al subir imagen: ${ApiService.extractErrorMessage(e)}');
    }
  }

  // Comprime a JPEG con calidad 75 y máximo 1200px de ancho.
  // Retorna null si la compresión falla (se usa el original).
  Future<File?> _compress(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/upload_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 1200,
        minHeight: 1200,
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : null;
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
