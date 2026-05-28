import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_auth/firebase_auth.dart';
import '../config/api_config.dart';

/// Reemplaza los Streams de Firestore con eventos Socket.io en tiempo real.
///
/// ⭐ ARQUITECTURA HÍBRIDA:
///   - Antes: StreamBuilder con cloud_firestore → escucha cambios en BD
///   - Ahora: Socket.io → el backend emite cambios cuando ocurren
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  bool _domainWorked = false; // Flag para saber si el dominio ya funcionó

  bool get isConnected => _isConnected;

  /// Conectar al backend con el token de Firebase para autenticar el socket.
  Future<void> connect() async {
    // Si ya existe un socket y está conectado, no hacemos nada
    if (_socket != null && _socket!.connected) {
      print('[Socket] ℹ️ Ya conectado.');
      return;
    }

    // Si el dominio ya funcionó antes, intentamos reconectar el socket actual
    if (_socket != null && _domainWorked) {
      print('[Socket] 🔄 Intentando recuperar conexión con dominio...');
      _socket!.connect();
      return;
    }

    print('[Socket] 📡 Configurando conexión a: ${ApiConfig.wsUrl}');

    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      print('[Socket] Error obteniendo token: $e');
    }

    // Inicialización del socket con opciones de alta estabilidad
    _socket = io.io(
      ApiConfig.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer ${token ?? ''}'})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(5000) 
          .setReconnectionDelayMax(10000)
          .build(),
    );

    // Definición de listeners globales
    _socket!.onConnect((_) {
      _isConnected = true;
      _domainWorked = true; // El dominio funciona correctamente
      print('[Socket] ✅ Conectado con éxito. ID: ${_socket!.id}');
    });

    _socket!.onDisconnect((data) {
      _isConnected = false;
      print('[Socket] ❌ Desconectado: $data');
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      print('[Socket] ⚠️ Error de conexión: $err');
      
      // Solo usamos la IP de respaldo si el dominio NUNCA ha funcionado en esta sesión
      if (err.toString().contains('errno = 7') && !_domainWorked) {
        print('[Socket] 🆘 DNS falló y el dominio nunca funcionó. Usando IP de respaldo...');
        _reconnectWithIP(token);
      }
    });

    _socket!.onError((err) {
      print('[Socket] 🔥 Error general: $err');
    });

    _socket!.onReconnect((_) => print('[Socket] 🔄 Reconectado'));
    _socket!.onReconnectAttempt((_) => print('[Socket] ⏳ Intentando reconexión...'));
    _socket!.onReconnectFailed((_) => print('[Socket] 💀 Falló la reconexión'));

    _socket!.connect();
  }

  /// Desconectar y limpiar el socket
  void disconnect() {
    print('[Socket] Cerrando conexión y limpiando...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  // ── Salas ────────────────────────────────────────────────────────────────

  void joinMap() {
    if (_socket == null || !_socket!.connected) return;
    print('[Socket] Uniéndose a sala: map');
    _socket!.emit('joinMap');
  }

  void leaveMap() {
    if (_socket == null) return;
    print('[Socket] Saliendo de sala: map');
    _socket!.emit('leaveMap');
  }

  void joinObject(String objectId) {
    if (_socket == null || !_socket!.connected) return;
    print('[Socket] Uniéndose a sala: object_$objectId');
    _socket!.emit('joinObject', objectId);
  }

  void leaveObject(String objectId) {
    if (_socket == null) return;
    print('[Socket] Saliendo de sala: object_$objectId');
    _socket!.emit('leaveObject', objectId);
  }

  void joinHunters() {
    if (_socket == null || !_socket!.connected) return;
    print('[Socket] Uniéndose a sala: hunters');
    _socket!.emit('joinHunters');
  }

  void updateMyLocation(double lat, double lng) {
    if (_socket == null || !_socket!.connected) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _socket!.emit('updateLocation', {'lat': lat, 'lng': lng, 'firebaseUid': uid});
  }

  // ── Escuchar eventos ─────────────────────────────────────────────────────

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void once(String event, Function(dynamic) handler) {
    _socket?.once(event, handler);
  }

  /// Método de respaldo para cuando el dominio falla
  void _reconnectWithIP(String? token) {
    _socket?.disconnect();
    _socket?.dispose();
    
    print('[Socket] 🆘 Reintentando conexión con IP de respaldo: ${ApiConfig.fallbackWsUrl}');

    _socket = io.io(
      ApiConfig.fallbackWsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer ${token ?? ''}'})
          .enableAutoConnect()
          .setQuery({'forceNew': 'true'}) // Forzamos una instancia limpia
          .build(),
    );
    
    _socket!.onConnect((_) {
      _isConnected = true;
      print('[Socket] ✅ Conectado vía IP Directa (Respaldo)');
    });

    _socket!.onConnectError((err) => print('[Socket] ❌ Fallo en IP de respaldo: $err'));
    
    _socket!.connect();
  }
}
