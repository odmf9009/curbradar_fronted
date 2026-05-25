import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';
import 'objects_service.dart';
import 'notification_service.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/curb_object.dart';

class ProximityService {
  final LocationService _locationService = LocationService();
  final ObjectsService _objectsService = ObjectsService();
  final NotificationService _notificationService = NotificationService();
  final ApiService _api = ApiService();

  StreamSubscription<Position>? _positionSubscription;
  List<CurbObject> _availableObjects = [];
  Timer? _pollingTimer;

  // Set to keep track of notified objects to avoid spamming (lasts for the session)
  final Set<String> _notifiedObjectIds = {};

  // Distance threshold in meters (e.g., 500 meters)
  static const double proximityThreshold = 500.0;

  Position? _lastKnownPosition;

  /// Starts monitoring proximity to objects
  void startMonitoring() {
    // 1. Load nearby objects initially via REST + poll every 30s
    _pollObjects();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollObjects();
    });

    // 2. Listen to user location changes
    _positionSubscription = _locationService.locationStream.listen((position) {
      _lastKnownPosition = position;
      _checkProximity(position);
    });
  }

  Future<void> _pollObjects() async {
    if (_lastKnownPosition == null) return;
    try {
      final objects = await _objectsService.getNearbyObjects(
        lat: _lastKnownPosition!.latitude,
        lng: _lastKnownPosition!.longitude,
        radiusMeters: 5000, // 5km polling radius
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
  }

  Future<void> _checkProximity(Position userPosition) async {
    final prefs = await SharedPreferences.getInstance();
    final bool nearbyEnabled = prefs.getBool('notify_nearby') ?? true;

    if (!nearbyEnabled) return;

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    for (var object in _availableObjects) {
      // Don't notify the owner of the object
      if (object.postedByUserId == currentUserId) continue;

      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        object.latitude,
        object.longitude,
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

  void _sendAlert(CurbObject object, double distance) {
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
      _api.post(
        ApiConfig.alerts,
        data: {
          'objectId': object.id,
          'objectTitle': object.title,
          'objectImageUrl':
              object.imageUrls.isNotEmpty ? object.imageUrls[0] : '',
          'address': object.address,
          'distance': distance,
        },
      ).catchError((e) {
        print('[Proximity] Error saving alert: $e');
      });
    }
  }
}
