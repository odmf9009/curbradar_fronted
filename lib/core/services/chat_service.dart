import 'dart:async';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class ChatMessage {
  final String id;
  final String objectId;
  final String senderId;
  final String senderName;
  final String senderImageUrl;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.objectId,
    required this.senderId,
    required this.senderName,
    required this.senderImageUrl,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id']?.toString() ?? '',
      objectId: json['objectId']?.toString() ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? 'Usuario',
      senderImageUrl: json['senderImageUrl'] ?? '',
      text: json['text'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Servicio de chat. Maneja la persistencia via REST.
/// El tiempo real se delega al SocketService global para consistencia.
class ChatService {
  final ApiService _api = ApiService();

  /// Obtiene el historial de mensajes de un objeto.
  Future<List<ChatMessage>> getMessages(String objectId) async {
    try {
      final response = await _api.get('${ApiConfig.chat}/$objectId');
      final List<dynamic> data = response.data['messages'] ?? [];
      // El backend devuelve los mensajes ordenados, los mapeamos.
      return data.map((json) => ChatMessage.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }

  /// Envía un mensaje al chat de un objeto.
  Future<ChatMessage> sendMessage(String objectId, String text) async {
    try {
      final response = await _api.post(
        '${ApiConfig.chat}/$objectId',
        data: {'text': text},
      );
      return ChatMessage.fromJson(response.data['message']);
    } on DioException catch (e) {
      throw Exception(ApiService.extractErrorMessage(e));
    }
  }
}
