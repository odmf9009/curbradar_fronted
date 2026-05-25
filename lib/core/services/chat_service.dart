import 'dart:async';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
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

/// Servicio de chat en tiempo real via WebSocket (Socket.io) + REST.
class ChatService {
  final ApiService _api = ApiService();
  WebSocketChannel? _channel;
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messageStream => _messageController.stream;

  /// Obtiene el historial de mensajes de un objeto.
  Future<List<ChatMessage>> getMessages(String objectId) async {
    try {
      final response = await _api.get('${ApiConfig.chat}/$objectId');
      final List<dynamic> data = response.data['messages'] ?? [];
      return data.map((json) => ChatMessage.fromJson(json)).toList().reversed.toList();
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

  /// Conecta al WebSocket para recibir mensajes en tiempo real.
  void connectToObjectChat(String objectId) {
    disconnectFromChat(); // Cerrar conexión anterior si existe

    final wsUrl = '${ApiConfig.wsUrl}/socket.io/?EIO=4&transport=websocket';

    // Nota: Para Socket.io real se recomienda usar el paquete socket_io_client
    // Esta es una implementación simplificada via WebSocket nativo
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Unirse a la sala del objeto
      _channel!.sink.add(json.encode({
        'event': 'joinObject',
        'data': objectId,
      }));

      _channel!.stream.listen(
        (data) {
          try {
            final parsed = json.decode(data);
            if (parsed['event'] == 'newMessage') {
              final message = ChatMessage.fromJson(parsed['data']);
              _messageController.add(message);
            }
          } catch (_) {}
        },
        onError: (error) {
          print('[Chat] WebSocket error: $error');
        },
      );
    } catch (e) {
      print('[Chat] Error conectando WebSocket: $e');
    }
  }

  void disconnectFromChat() {
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnectFromChat();
    _messageController.close();
  }
}
