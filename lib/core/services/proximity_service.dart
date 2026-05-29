import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';
import 'objects_service.dart';
import 'notification_service.dart';
import 'socket_service.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/curb_object.dart';

class ProximityService {
  static final ProximityService _instance = ProximityService._internal();
  factory ProximityService() => _instance;
  ProximityService._internal();

  final LocationService _locationService = LocationService();
  final ObjectsService _objectsService = ObjectsService();
  final NotificationService _notificationService = NotificationService();
  final SocketService _socket = SocketService();
  final ApiService _api = ApiService();

  StreamSubscription<Position>? _positionSubscription;
  List<CurbObject> _availableObjects = [];
  Timer? _pollingTimer;

  final Set<String> _notifiedObjectIds = {};

  static const double proximityThreshold = 500.0;

  Position? _lastKnownPosition;
  bool _isMonitoring = false;

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // 1. Carga inicial + polling REST cada 5 min (reducido — el socket cubre los nuevos)
    _pollObjects();
    _pollingTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _pollObjects();
    });

    // 2. GPS: comprueba proximidad cuando el usuario se mueve
    _positionSubscription = _locationService.locationStream.listen((position) {
      _lastKnownPosition = position;
      _checkProximity(position);
    });

    // 3. Socket: detección INMEDIATA cuando alguien publica un objeto nuevo
    _socket.on('object:new', (data) {
      try {
        final rawObj = data['object'];
        if (rawObj == null) return;
        final obj = CurbObject.fromJson(Map<String, dynamic>.from(rawObj));

        // Añadir a la lista local para futuros checks de GPS
        if (obj.status == CurbObjectStatus.available) {
          _availableObjects.removeWhere((o) => o.id == obj.id);
          _availableObjects.add(obj);
        }

        // Si ya tenemos posición, comprobar inmediatamente sin esperar GPS
        if (_lastKnownPosition != null) {
          _checkProximityForObject(obj, _lastKnownPosition!);
        }
      } catch (e) {
        print('[Proximity] Error procesando object:new: $e');
      }
    });

    // 4. Socket: eliminar de la lista si el objeto fue recogido o expiró
    _socket.on('object:deleted', (data) {
      final objectId = data['objectId']?.toString() ?? '';
      if (objectId.isNotEmpty) {
        _availableObjects.removeWhere((o) => o.id == objectId);
        _notifiedObjectIds.remove(objectId);
      }
    });

    // 5. Socket: actualizar estado si cambia a onMyWay (ya no disponible)
    _socket.on('object:updated', (data) {
      final objectId = data['objectId']?.toString() ?? '';
      final newStatus = data['status']?.toString();
      if (objectId.isNotEmpty && newStatus == 'onMyWay') {
        _availableObjects.removeWhere((o) => o.id == objectId);
      }
    });
  }

  Future<void> _pollObjects() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    if (_lastKnownPosition == null) {
      _lastKnownPosition = await _locationService.getCurrentLocation();
    }
    if (_lastKnownPosition == null) return;

    try {
      final objects = await _objectsService.getNearbyObjects(
        lat: _lastKnownPosition!.latitude,
        lng: _lastKnownPosition!.longitude,
        radiusMeters: 5000,
      );
      _availableObjects =
          objects.where((o) => o.status == CurbObjectStatus.available).toList();
    } catch (e) {
      print('[Proximity] Error polling objects: $e');
    }
  }

  void stopMonitoring() {
    _positionSubscription?.cancel();
    _pollingTimer?.cancel();
    _socket.off('object:new');
    _socket.off('object:deleted');
    _socket.off('object:updated');
    _isMonitoring = false;
  }

  Future<void> _checkProximity(Position userPosition) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notify_nearby') ?? true)) return;

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    for (final object in List.of(_availableObjects)) {
      if (object.postedByUserId == currentUserId) continue;
      final distance = Geolocator.distanceBetween(
        userPosition.latitude, userPosition.longitude,
        object.latitude, object.longitude,
      );
      if (distance <= proximityThreshold) {
        if (!_notifiedObjectIds.contains(object.id)) {
          _notifiedObjectIds.add(object.id);
          _sendAlert(object, distance);
        }
      } else {
        _notifiedObjectIds.remove(object.id);
      }
    }
  }

  /// Comprueba un objeto concreto contra la posición actual.
  /// Se llama directamente desde el evento socket object:new para detección inmediata.
  Future<void> _checkProximityForObject(CurbObject object, Position userPosition) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notify_nearby') ?? true)) return;

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    if (object.postedByUserId == currentUserId) return;
    if (_notifiedObjectIds.contains(object.id)) return;

    final distance = Geolocator.distanceBetween(
      userPosition.latitude, userPosition.longitude,
      object.latitude, object.longitude,
    );

    if (distance <= proximityThreshold) {
      _notifiedObjectIds.add(object.id);
      _sendAlert(object, distance);
    }
  }

  Future<void> _sendAlert(CurbObject object, double distance) async {
    String distText =
        distance < 100 ? 'a pocos pasos' : 'a solo ${distance.toInt()} metros';

    // 1. Show local push notification
    _notificationService.showLocalAlert(
      '¡Tesoro detectado!',
      'Un "${object.title}" está $distText de ti. ¡Cázalo antes que nadie!',
      payload: object.id,
    );

    // 2. Save alert to backend
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await _api.post(
          ApiConfig.alerts,
          data: {
            'objectId': object.id,
            'objectTitle': object.title,
            'objectImageUrl':
                object.imageUrls.isNotEmpty ? object.imageUrls[0] : '',
            'address': object.address,
            'distance': distance,
          },
        );
      } catch (e) {
        print('[Proximity] Error saving alert: $e');
      }
    }
  }
}
