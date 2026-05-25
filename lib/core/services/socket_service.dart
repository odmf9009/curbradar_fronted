import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

/// Reemplaza los Streams de Firestore con eventos Socket.io en tiempo real.
///
/// ⭐ ARQUITECTURA HÍBRIDA:
///   - Antes: StreamBuilder con cloud_firestore → escucha cambios en BD
///   - Ahora: Socket.io → el backend emite cambios cuando ocurren
///
/// Eventos que el servidor emite (escuchar con [on]):
///   "object:new"       → { object }         nuevo objeto en el mapa
///   "object:updated"   → { objectId, ...}   cambio de estado
///   "object:deleted"   → { objectId }       objeto eliminado/recogido
///   "hunter:location"  → { firebaseUid, lat, lng }
///   "newMessage"       → { message }        mensaje de chat
///
/// Eventos que enviamos al servidor:
///   "joinMap"          → entrar a sala del mapa
///   "leaveMap"
///   "joinObject"       → entrar al chat/detalle de un objeto
///   "leaveObject"
///   "joinHunters"      → activar visibilidad de cazadores
///   "updateLocation"   → { lat, lng, firebaseUid }
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Conectar al backend con el token de Firebase para autenticar el socket.
  Future<void> connect() async {
    if (_isConnected) return;

    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {}

    _socket = IO.io(
      ApiConfig.wsUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer ${token ?? ''}'})
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      print('[Socket] ✅ Conectado al servidor');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('[Socket] ❌ Desconectado');
    });

    _socket!.onError((err) {
      print('[Socket] Error: $err');
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // ── Salas ────────────────────────────────────────────────────────────────

  /// Entrar a la sala del mapa para recibir object:new / object:updated / object:deleted
  void joinMap() => _socket?.emit('joinMap');
  void leaveMap() => _socket?.emit('leaveMap');

  /// Entrar a la sala de un objeto (chat + detalle en tiempo real)
  void joinObject(String objectId) => _socket?.emit('joinObject', objectId);
  void leaveObject(String objectId) => _socket?.emit('leaveObject', objectId);

  /// Activar modo cazador — ver otros cazadores en el mapa
  void joinHunters() => _socket?.emit('joinHunters');

  /// Enviar mi ubicación a otros cazadores
  void updateMyLocation(double lat, double lng) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _socket?.emit('updateLocation', {'lat': lat, 'lng': lng, 'firebaseUid': uid});
  }

  // ── Escuchar eventos ─────────────────────────────────────────────────────

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  /// Escuchar un evento una sola vez
  void once(String event, Function(dynamic) handler) {
    _socket?.once(event, handler);
  }
}
