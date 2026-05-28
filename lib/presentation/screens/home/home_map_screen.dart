import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/objects_service.dart';
import '../../../core/services/users_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/models/user_model.dart';
import '../../../core/models/filter_model.dart';
import '../../../core/config/routes.dart';
import 'filters_screen.dart';

class HomeMapScreen extends StatefulWidget {
  final bool isOnline;
  final Function(bool) onToggleOnline;
  final ConnectivityStatus connectivityStatus;

  const HomeMapScreen({
    super.key,
    required this.isOnline,
    required this.onToggleOnline,
    required this.connectivityStatus,
  });

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final LocationService _locationService = LocationService();
  final ObjectsService _objectsService = ObjectsService();
  final UsersService _usersService = UsersService();
  final SocketService _socket = SocketService();
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();

  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<void>? _objectCreatedSubscription;
  Position? _currentPosition;
  LatLng? _manualLocation;
  bool _isFollowingUser = true;

  List<CurbObject> _allObjects = [];
  List<UserModel> _activeHunters = [];
  List<CurbObject> _nearbyObjects = [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  String _etaText = '';
  String _distanceText = '';
  bool _showEtaCard = false;
  String? _navigatingTargetId;

  bool _isInitialLoading = true;
  FilterModel _currentFilters = FilterModel(
    distance: 5.0,
    category: 'Todos',
    status: 'available',
    timeRange: 'all',
    searchQuery: '',
  );
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  final Set<String> _loadingIcons = {};
  Timer? _debounceTimer;
  Timer? _objectsRefreshTimer;

  static const String googleMapsApiKey =
      "AIzaSyCUVtYc5DVhtStudSzSpTKj5_P6WOwZsUU";

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(25.7617, -80.1918),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenToSocketEvents();
    _loadActiveHunters();

    // Escuchar cuando el propio usuario realiza acciones (publicar, reclamar, confirmar)
    _objectCreatedSubscription = ObjectsService.onObjectAction.listen((_) async {
      print('[HomeMap] Acción local detectada. Refrescando datos...');
      
      // Si el usuario abandona o recoge el objeto, ocultamos la tarjeta de ETA automáticamente
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      bool stillHasActiveClaim = _allObjects.any((o) => 
          o.id == _navigatingTargetId && 
          o.status == CurbObjectStatus.onMyWay && 
          o.claimedByUserId == uid);
      
      if (!stillHasActiveClaim) {
        setState(() {
          _showEtaCard = false;
          _navigatingTargetId = null;
          _polylines.clear();
        });
      }

      // Esperamos un momento para que el backend procese la acción
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) _loadObjects();
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _objectCreatedSubscription?.cancel();
    _debounceTimer?.cancel();
    _objectsRefreshTimer?.cancel();
    _listScrollController.dispose();
    _socket.leaveMap();
    _socket.off('object:new');
    _socket.off('object:updated');
    _socket.off('object:deleted');
    _socket.off('hunter:location');
    super.dispose();
  }

  /// Load initial objects via REST
  Future<void> _loadObjects() async {
    if (_currentPosition == null) return;
    try {
      if (mounted) setState(() => _isInitialLoading = true);

      // Si el filtro es 'available', no enviamos status al servidor para que nos devuelva 
      // tanto 'available' como 'onMyWay', y luego filtramos localmente.
      final String? statusFilter = (_currentFilters.status == 'available' || _currentFilters.status == 'Todos') 
          ? null 
          : _currentFilters.status;

      final objects = await _objectsService.getNearbyObjects(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        radiusMeters: _currentFilters.distance * 1609.34,
        category: _currentFilters.category != 'Todos'
            ? _currentFilters.category
            : null,
        status: statusFilter,
        timeRange: _currentFilters.timeRange != 'all'
            ? _currentFilters.timeRange
            : null,
        searchQuery: _currentFilters.searchQuery.isNotEmpty
            ? _currentFilters.searchQuery
            : null,
      );
      if (mounted) {
        setState(() {
          _allObjects = objects;
          _isInitialLoading = false;
        });
        _filterAndRefreshMap();
      }
    } catch (e) {
      if (mounted) setState(() => _isInitialLoading = false);
      print('[HomeMap] Error loading objects: $e');
    }
  }

  /// Load active hunters via REST
  Future<void> _loadActiveHunters() async {
    try {
      final hunters = await _usersService.getActiveHunters();
      final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (mounted) {
        _activeHunters =
            hunters.where((h) => h.firebaseUid != uid).toList();
        _filterAndRefreshMap();
      }
    } catch (e) {
      print('[HomeMap] Error loading hunters: $e');
    }
  }

  void _listenToSocketEvents() {
    _socket.joinMap();

    // New object published
    _socket.on('object:new', (data) {
      if (!mounted) return;
      try {
        // El payload del socket viene envuelto en una llave 'object'
        final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
        final objectData = payload.containsKey('object') ? payload['object'] : payload;
        
        final obj = CurbObject.fromJson(Map<String, dynamic>.from(objectData));
        
        setState(() {
          // Evitar duplicados si ya existe
          _allObjects.removeWhere((o) => o.id == obj.id);
          _allObjects.add(obj);
        });
        _filterAndRefreshMap();
      } catch (e) {
        print('[HomeMap] Error parsing object:new: $e');
      }
    });

    // Object updated (status change, ETA, etc.)
    _socket.on('object:updated', (data) {
      if (!mounted) return;
      try {
        final Map<String, dynamic> payload = Map<String, dynamic>.from(data);
        final objectData = payload.containsKey('object') ? payload['object'] : payload;
        
        final updatedObj = CurbObject.fromJson(Map<String, dynamic>.from(objectData));
        final idx = _allObjects.indexWhere((o) => o.id == updatedObj.id);

        // Auto-hide ETA card if no longer claimed by me
        if (_showEtaCard && _navigatingTargetId == updatedObj.id) {
          final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          if (updatedObj.status != CurbObjectStatus.onMyWay ||
              updatedObj.claimedByUserId != uid) {
            setState(() {
              _showEtaCard = false;
              _navigatingTargetId = null;
              _polylines.clear();
            });
          }
        }

        if (idx != -1) {
          setState(() => _allObjects[idx] = updatedObj);
        } else {
          setState(() => _allObjects.add(updatedObj));
        }
        _filterAndRefreshMap();
      } catch (e) {
        print('[HomeMap] Error parsing object:updated: $e');
      }
    });

    // Object deleted / expired
    _socket.on('object:deleted', (data) {
      if (!mounted) return;
      try {
        final objectId = data['objectId']?.toString() ?? '';
        if (objectId.isNotEmpty) {
          setState(() {
            _allObjects.removeWhere((o) => o.id == objectId);
          });
          _filterAndRefreshMap();
        }
      } catch (e) {
        print('[HomeMap] Error parsing object:deleted: $e');
      }
    });

    // Hunter location update
    _socket.on('hunter:location', (data) {
      if (!mounted) return;
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final firebaseUid = data['firebaseUid']?.toString() ?? '';
        if (firebaseUid == uid) return; // Skip self

        final double lat = (data['lat'] as num).toDouble();
        final double lng = (data['lng'] as num).toDouble();

        final idx =
            _activeHunters.indexWhere((h) => h.firebaseUid == firebaseUid);
        if (idx != -1) {
          // Update existing hunter position
          final updated = UserModel(
            id: _activeHunters[idx].id,
            firebaseUid: firebaseUid,
            name: _activeHunters[idx].name,
            username: _activeHunters[idx].username,
            email: _activeHunters[idx].email,
            profileImageUrl: _activeHunters[idx].profileImageUrl,
            points: _activeHunters[idx].points,
            level: _activeHunters[idx].level,
            levelTitle: _activeHunters[idx].levelTitle,
            isOnline: true,
            latitude: lat,
            longitude: lng,
          );
          setState(() => _activeHunters[idx] = updated);
          _filterAndRefreshMap();
        }
      } catch (e) {
        print('[HomeMap] Error parsing hunter:location: $e');
      }
    });
  }

  void _filterAndRefreshMap() {
    final double? refLat =
        _manualLocation?.latitude ?? _currentPosition?.latitude;
    final double? refLng =
        _manualLocation?.longitude ?? _currentPosition?.longitude;

    if (refLat == null || refLng == null) {
      if (mounted) setState(() {});
      return;
    }

    final double maxDistanceInMeters = _currentFilters.distance * 1609.34;
    const double globalLimitInMeters = 50 * 1609.34;
    final String query = _currentFilters.searchQuery.toLowerCase();
    final now = DateTime.now();

    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final filtered = _allObjects.where((obj) {
      // 1. SIEMPRE mostrar mi propio reclamo activo, ignorando filtros de distancia/estado
      if (obj.status == CurbObjectStatus.onMyWay && obj.claimedByUserId == currentUid) {
        return true;
      }

      double distanceInMeters = Geolocator.distanceBetween(
          refLat, refLng, obj.latitude, obj.longitude);

      if (distanceInMeters > globalLimitInMeters) return false;
      if (distanceInMeters > maxDistanceInMeters) return false;

      if (_currentFilters.category != 'Todos' &&
          obj.category != _currentFilters.category) return false;

      // Mostrar disponibles, o si el filtro es 'disponible' mostrar también los 'en camino' 
      // (aunque los de otros se filtrarán en la UI o se verán con icono azul)
      bool matchesStatus = _currentFilters.status == 'Todos' ||
          obj.status.name == _currentFilters.status ||
          (_currentFilters.status == 'available' &&
              obj.status.name == 'onMyWay');
      if (!matchesStatus) return false;

      if (_currentFilters.timeRange == '24h') {
        if (now.difference(obj.createdAt).inHours > 24) return false;
      } else if (_currentFilters.timeRange == '3d') {
        if (now.difference(obj.createdAt).inDays > 3) return false;
      }

      if (query.isNotEmpty) {
        bool matchesSearch = obj.title.toLowerCase().contains(query) ||
            obj.description.toLowerCase().contains(query) ||
            obj.category.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      return true;
    }).toList();
    filtered.sort((a, b) {
      // 1. Mis reclamos activos primero
      bool aIsMyClaim =
          a.status == CurbObjectStatus.onMyWay && a.claimedByUserId == currentUid;
      bool bIsMyClaim =
          b.status == CurbObjectStatus.onMyWay && b.claimedByUserId == currentUid;

      if (aIsMyClaim && !bIsMyClaim) return -1;
      if (!aIsMyClaim && bIsMyClaim) return 1;
      
      // 2. Lo más nuevo después
      return b.createdAt.compareTo(a.createdAt);
    });

    final Set<Marker> newMarkers = {};

    // Add Hunters (Carts)
    for (var hunter in _activeHunters) {
      if (hunter.latitude != null && hunter.longitude != null) {
        const String cacheKey = 'hunter_icon';
        BitmapDescriptor icon = _markerIconCache[cacheKey] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

        if (!_markerIconCache.containsKey(cacheKey) &&
            !_loadingIcons.contains(cacheKey)) {
          _loadingIcons.add(cacheKey);
          _createCartMarker().then((customIcon) {
            if (mounted && customIcon != null) {
              _markerIconCache[cacheKey] = customIcon;
              _filterAndRefreshMap();
            }
          });
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId('hunter_${hunter.firebaseUid}'),
            position: LatLng(hunter.latitude!, hunter.longitude!),
            icon: icon,
            infoWindow: InfoWindow(
                title: '@${hunter.displayName}',
                snippet: tr('cazador_camino')),
          ),
        );
      }
    }

    // Add Objects
    for (var obj in filtered) {
      final bool isNavigating =
          obj.id == _navigatingTargetId && _showEtaCard;
      final String cacheKey =
          '${obj.imageUrls.isNotEmpty ? obj.imageUrls[0] : 'no_img'}_${obj.status.name}_${obj.category}${isNavigating ? '_nav' : ''}';
      BitmapDescriptor icon = _markerIconCache[cacheKey] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

      if (!_markerIconCache.containsKey(cacheKey) &&
          obj.imageUrls.isNotEmpty &&
          !_loadingIcons.contains(cacheKey)) {
        _loadingIcons.add(cacheKey);

        Color statusColor = obj.status == CurbObjectStatus.available
            ? const Color(0xFF4CAF50)
            : const Color(0xFF1976D2);

        _loadCustomMarker(
          obj.imageUrls[0],
          statusColor,
          obj.category,
          label: isNavigating ? _etaText : null,
        ).then((customIcon) {
          if (mounted) {
            if (customIcon != null) {
              _markerIconCache[cacheKey] = customIcon;
            }
            _loadingIcons.remove(cacheKey);

            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 100), () {
              if (mounted) _filterAndRefreshMap();
            });
          }
        });
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(obj.id),
          position: LatLng(obj.latitude, obj.longitude),
          icon: icon,
          onTap: () => _goToDetails(obj),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _nearbyObjects = filtered;
        _markers = newMarkers;
      });
    }
  }

  Future<void> _goToDetails(CurbObject obj) async {
    final result = await Navigator.pushNamed(
        context, AppRoutes.objectDetail,
        arguments: obj);

    if (result == true) {
      final index = _allObjects.indexWhere((o) => o.id == obj.id);
      if (index != -1) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        _allObjects[index] = _allObjects[index].copyWith(
          status: 'onMyWay',
          claimedByUserId: currentUid,
          claimedAt: DateTime.now(),
        );
        _filterAndRefreshMap();
      }

      _drawRoute(LatLng(obj.latitude, obj.longitude), obj.id);

      Future.delayed(const Duration(milliseconds: 600), () {
        if (_listScrollController.hasClients) {
          _listScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 1000),
            curve: Curves.fastOutSlowIn,
          );
        }
      });
    } else if (result == false) {
      setState(() {
        _showEtaCard = false;
        _polylines.clear();
        _navigatingTargetId = null;
      });
    }
  }

  Future<void> _drawRoute(LatLng destination, String objectId) async {
    if (_currentPosition == null) return;

    PolylinePoints polylinePoints = PolylinePoints(apiKey: googleMapsApiKey);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(
            _currentPosition!.latitude, _currentPosition!.longitude),
        destination:
            PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      List<LatLng> polylineCoordinates = [];
      double totalDistance = 0;

      for (int i = 0; i < result.points.length; i++) {
        polylineCoordinates.add(
            LatLng(result.points[i].latitude, result.points[i].longitude));
        if (i > 0) {
          totalDistance += Geolocator.distanceBetween(
              result.points[i - 1].latitude,
              result.points[i - 1].longitude,
              result.points[i].latitude,
              result.points[i].longitude);
        }
      }

      int minutes = (totalDistance / 416).ceil();
      if (minutes < 1) minutes = 1;

      double miles = totalDistance / 1609.34;

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId("route"),
            color: const Color(0xFF1976D2),
            points: polylineCoordinates,
            width: 5,
          ),
        );
        _etaText = '$minutes min';
        _distanceText = '${miles.toStringAsFixed(1)} mi';
        _showEtaCard = true;
        _navigatingTargetId = objectId;
        _isFollowingUser = true;
      });

      // Update ETA in backend via REST
      _objectsService.updateEta(objectId, _etaText).catchError((_) {});

      _fitRoute(polylineCoordinates);
    }
  }

  Future<void> _fitRoute(List<LatLng> points) async {
    final controller = await _controller.future;
    LatLngBounds bounds;
    if (points.length == 1) {
      bounds =
          LatLngBounds(southwest: points.first, northeast: points.first);
    } else {
      double minLat = points.first.latitude,
          minLng = points.first.longitude;
      double maxLat = points.first.latitude,
          maxLng = points.first.longitude;
      for (var point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
      bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng));
    }
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  Future<BitmapDescriptor?> _createCartMarker() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..isAntiAlias = true;

    const double size = 100.0;
    const double radius = size / 2;

    paint.color = const Color(0xFFFF8A00);
    canvas.drawCircle(const Offset(radius, radius), radius, paint);

    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 4;
    canvas.drawCircle(const Offset(radius, radius), radius - 2, paint);

    const icon = Icons.directions_car;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 60,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(radius - 25, radius - 25));

    final ui.Image finalImage = await pictureRecorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final ByteData? byteData =
        await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<BitmapDescriptor?> _loadCustomMarker(
      String url, Color borderColor, String category,
      {String? label}) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(bytes,
            targetWidth: 120, targetHeight: 120);
        final ui.FrameInfo fi = await codec.getNextFrame();
        final ui.Image image = fi.image;
        final pictureRecorder = ui.PictureRecorder();
        final canvas = Canvas(pictureRecorder);
        final paint = Paint()..isAntiAlias = true;

        const double baseSize = 120.0;
        const double labelHeight = 40.0;
        final double totalHeight =
            label != null ? baseSize + labelHeight : baseSize;
        final double centerX = baseSize / 2;
        final double circleCenterY =
            label != null ? labelHeight + (baseSize / 2) : baseSize / 2;
        const double radius = baseSize / 2;

        if (label != null) {
          final labelPainter = TextPainter(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
          );
          labelPainter.layout();

          final double bubbleW = labelPainter.width + 20;
          final double bubbleH = labelPainter.height + 10;
          final Rect bubbleRect = Rect.fromCenter(
            center: Offset(centerX, bubbleH / 2),
            width: bubbleW,
            height: bubbleH,
          );

          paint.color = const Color(0xFF1976D2);
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  bubbleRect, const Radius.circular(10)),
              paint);

          final path = Path();
          path.moveTo(centerX - 8, bubbleH);
          path.lineTo(centerX + 8, bubbleH);
          path.lineTo(centerX, bubbleH + 8);
          path.close();
          canvas.drawPath(path, paint);

          labelPainter.paint(
              canvas,
              Offset(centerX - (labelPainter.width / 2),
                  (bubbleH / 2) - (labelPainter.height / 2)));
        }

        paint.color = borderColor;
        canvas.drawCircle(Offset(centerX, circleCenterY), radius, paint);

        final Path clipPath = Path()
          ..addOval(Rect.fromLTWH(centerX - radius + 4,
              circleCenterY - radius + 4, baseSize - 8, baseSize - 8));
        canvas.save();
        canvas.clipPath(clipPath);
        canvas.drawImageRect(
            image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromLTWH(centerX - radius + 4, circleCenterY - radius + 4,
                baseSize - 8, baseSize - 8),
            paint);
        canvas.restore();

        final double badgeRadius = 22.0;
        final Offset badgeCenter =
            Offset(baseSize - badgeRadius, circleCenterY + radius - badgeRadius);

        paint.color = Colors.white;
        canvas.drawCircle(badgeCenter, badgeRadius, paint);
        paint.color = borderColor;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 2;
        canvas.drawCircle(badgeCenter, badgeRadius, paint);
        paint.style = PaintingStyle.fill;

        IconData categoryIcon;
        switch (category) {
          case 'Muebles':
            categoryIcon = Icons.chair;
            break;
          case 'Electrodomésticos':
            categoryIcon = Icons.kitchen;
            break;
          case 'Electrónica':
            categoryIcon = Icons.tv;
            break;
          case 'Ropa':
            categoryIcon = Icons.checkroom;
            break;
          case 'Juguetes':
            categoryIcon = Icons.smart_toy;
            break;
          default:
            categoryIcon = Icons.category;
        }

        final textPainter = TextPainter(textDirection: TextDirection.ltr);
        textPainter.text = TextSpan(
          text: String.fromCharCode(categoryIcon.codePoint),
          style: TextStyle(
            fontSize: 28,
            fontFamily: categoryIcon.fontFamily,
            color: borderColor,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas,
            Offset(badgeCenter.dx - 14, badgeCenter.dy - 14));

        final ui.Image finalImage = await pictureRecorder
            .endRecording()
            .toImage(baseSize.toInt(), totalHeight.toInt());
        final ByteData? byteData =
            await finalImage.toByteData(format: ui.ImageByteFormat.png);
        return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
      }
    } catch (e) {
      print('Error loading marker image: $e');
    }
    return null;
  }

  Future<void> _initLocation() async {
    final hasPermission =
        await _locationService.checkAndRequestPermissions();
    if (hasPermission) {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() => _currentPosition = position);
        _updateUserPosition(position, isInitial: true);
        _loadObjects(); // Initial load via REST
        _subscribeToCurrentCity(position);
      }
      _positionSubscription =
          _locationService.locationStream.listen((position) {
        if (mounted) {
          setState(() => _currentPosition = position);
          _updateUserPosition(position);
        }
      });
    }
  }

  Future<void> _subscribeToCurrentCity(Position position) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final String? city = placemarks[0].locality;
        if (city != null && city.isNotEmpty) {
          await _notificationService.subscribeToLocality(city);
        }
      }
    } catch (e) {
      print('Error al suscribirse a la ciudad: $e');
    }
  }

  Future<void> _updateUserPosition(Position position,
      {bool isInitial = false}) async {
    if (_isFollowingUser || isInitial) {
      final controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 15,
          tilt: 45)));
    }

    if (_navigatingTargetId != null && _showEtaCard) {
      final targetObj = _allObjects
          .cast<CurbObject?>()
          .firstWhere((o) => o?.id == _navigatingTargetId,
              orElse: () => null);
      if (targetObj != null) {
        _updateEtaSilently(
            LatLng(targetObj.latitude, targetObj.longitude), targetObj.id);
      }
    }
  }

  Future<void> _updateEtaSilently(
      LatLng destination, String objectId) async {
    if (_currentPosition == null) return;

    PolylinePoints polylinePoints = PolylinePoints(apiKey: googleMapsApiKey);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(
            _currentPosition!.latitude, _currentPosition!.longitude),
        destination:
            PointLatLng(destination.latitude, destination.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      double totalDistance = 0;
      for (int i = 1; i < result.points.length; i++) {
        totalDistance += Geolocator.distanceBetween(
            result.points[i - 1].latitude,
            result.points[i - 1].longitude,
            result.points[i].latitude,
            result.points[i].longitude);
      }

      int minutes = (totalDistance / 416).ceil();
      if (minutes < 1) minutes = 1;
      String newEta = '$minutes min';

      if (newEta != _etaText) {
        setState(() {
          _etaText = newEta;
          _distanceText =
              '${(totalDistance / 1609.34).toStringAsFixed(1)} mi';
        });
        // Update ETA in backend via REST
        _objectsService.updateEta(objectId, newEta).catchError((_) {});
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;

    try {
      final List<geo.Location> locations =
          await geo.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final LatLng target = LatLng(loc.latitude, loc.longitude);

        setState(() {
          _manualLocation = target;
          _isFollowingUser = false;
        });

        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15),
        ));

        _filterAndRefreshMap();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo encontrar la dirección')),
        );
      }
    }
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final appleMapsUrl =
        Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else if (await canLaunchUrl(appleMapsUrl)) {
      await launchUrl(appleMapsUrl);
    } else {
      final webUrl = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showBottomPanel =
        _nearbyObjects.isNotEmpty || _isInitialLoading;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialCameraPosition,
              mapType: MapType.normal,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              padding: EdgeInsets.only(
                  bottom: showBottomPanel ? 240 : 20, top: 100),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 8),
                  if (widget.isOnline &&
                      widget.connectivityStatus == ConnectivityStatus.online)
                    _buildRadarActiveBadge(),
                  if (widget.connectivityStatus == ConnectivityStatus.offline)
                    _buildOfflineBanner(),
                ],
              ),
            ),
          ),
          if (_showEtaCard) _buildEtaCard(),
          _buildBottomPanel(),
          Positioned(
            bottom: showBottomPanel ? 340 : 160,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Show "IR" shortcut if there's an active claim without route showing
                if (_navigatingTargetId == null)
                  Builder(builder: (context) {
                    final uid =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    final activeClaim = _allObjects
                        .cast<CurbObject?>()
                        .firstWhere(
                          (o) =>
                              o?.claimedByUserId == uid &&
                              o?.status == CurbObjectStatus.onMyWay &&
                              !(o!.isClaimExpired),
                          orElse: () => null,
                        );

                    if (activeClaim == null) return const SizedBox.shrink();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FloatingActionButton.extended(
                        heroTag: 'go_active_fab',
                        onPressed: () => _drawRoute(
                            LatLng(activeClaim.latitude,
                                activeClaim.longitude),
                            activeClaim.id),
                        backgroundColor: const Color(0xFF1976D2),
                        icon: const Icon(Icons.directions,
                            color: Colors.white),
                        label: Text(tr('ir'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    );
                  }),
                FloatingActionButton(
                  heroTag: 'gps_fab',
                  onPressed: () {
                    setState(() {
                      _isFollowingUser = true;
                      _manualLocation = null;
                      _searchController.clear();
                      _polylines.clear();
                      _showEtaCard = false;
                    });
                    if (_currentPosition != null) {
                      _updateUserPosition(_currentPosition!);
                    }
                    _filterAndRefreshMap();
                  },
                  backgroundColor: const Color(0xFFFF8A00),
                  shape: const CircleBorder(),
                  child: Icon(
                      _isFollowingUser
                          ? Icons.my_location
                          : Icons.location_searching,
                      color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarActiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.radar, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            tr('radar_activo'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tr('modo_offline'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtaCard() {
    return Positioned(
      top: 180,
      left: 16,
      right: 16,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2), blurRadius: 10)
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.directions_car,
                color: Colors.white, size: 24),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tr('tiempo_llegada'),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11)),
                Text('$_etaText ($_distanceText)',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const Spacer(),
            if (_navigatingTargetId != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      final target = _allObjects
                          .cast<CurbObject?>()
                          .firstWhere(
                              (o) => o?.id == _navigatingTargetId,
                              orElse: () => null);
                      if (target != null) {
                        Navigator.pushNamed(
                            context, AppRoutes.objectDetail,
                            arguments: target);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(tr('objeto'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () {
                      final target = _allObjects
                          .cast<CurbObject?>()
                          .firstWhere(
                              (o) => o?.id == _navigatingTargetId,
                              orElse: () => null);
                      if (target != null) {
                        _launchNavigation(
                            target.latitude, target.longitude);
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1976D2),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(tr('iniciar'),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close,
                  color: Colors.white70, size: 20),
              onPressed: () {
                if (_navigatingTargetId != null) {
                  _objectsService
                      .updateEta(_navigatingTargetId!, '')
                      .catchError((_) {});
                }
                setState(() {
                  _showEtaCard = false;
                  _navigatingTargetId = null;
                  _polylines.clear();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8)
                    ]),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.menu, size: 20),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _searchAddress,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                            hintText: tr('search_hint'),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12)),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune, size: 20),
                      onPressed: () async {
                        final FilterModel? result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FiltersScreen(
                                    initialFilters: _currentFilters)));
                        if (result != null) {
                          setState(() {
                            _currentFilters = result;
                          });
                          _loadObjects(); // Reload with new filters
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8)
                  ]),
              child: Row(
                children: [
                  Icon(
                    widget.isOnline
                        ? Icons.directions_car
                        : Icons.directions_car_outlined,
                    size: 18,
                    color: widget.isOnline
                        ? const Color(0xFFFF8A00)
                        : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: widget.isOnline,
                      onChanged: widget.onToggleOnline,
                      activeColor: const Color(0xFFFF8A00),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (_currentFilters.category != 'Todos')
                _buildChip(_currentFilters.category),
              _buildChip('${_currentFilters.distance.toInt()} millas'),
              if (_currentFilters.status != 'Todos')
                _buildChip(_currentFilters.status == 'available'
                    ? 'Disponible'
                    : _currentFilters.status),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1), blurRadius: 4)
          ]),
      child: Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(width: 4),
        const Icon(Icons.close, size: 14, color: Colors.grey)
      ]),
    );
  }

  Widget _buildBottomPanel() {
    if (_nearbyObjects.isEmpty && !_isInitialLoading) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 240,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, spreadRadius: 2)
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isInitialLoading
                        ? tr('buscando')
                        : '${tr('results')} (${_nearbyObjects.length})',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.allNearby,
                        arguments: {
                          'objects': _nearbyObjects,
                          'position': _currentPosition,
                        },
                      );
                    },
                    child: Text(tr('see_all'),
                        style: const TextStyle(
                            color: Color(0xFFFF8A00))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 160,
                child: _isInitialLoading
                    ? _buildShimmerLoading()
                    : ListView.builder(
                        controller: _listScrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        itemCount: _nearbyObjects.length,
                        itemBuilder: (context, index) =>
                            _buildItemCard(_nearbyObjects[index]),
                      ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.white,
        child: Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12, bottom: 20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16)))),
                const SizedBox(height: 8),
                Container(width: 100, height: 12, color: Colors.white),
              ]),
        ),
      ),
    );
  }

  Widget _buildItemCard(CurbObject obj) {
    final String currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isMyClaim = obj.status == CurbObjectStatus.onMyWay &&
        obj.claimedByUserId == currentUid;

    Color statusColor = obj.status == CurbObjectStatus.available
        ? const Color(0xFF4CAF50)
        : const Color(0xFF1976D2);

    return GestureDetector(
      onTap: () => _goToDetails(obj),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isMyClaim)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tr('en_camino'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                ),
              ),
            Expanded(
              child: Hero(
                tag: 'image_${obj.id}',
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: obj.imageUrls.isNotEmpty
                        ? Image.network(obj.imageUrls[0],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                        Icons.broken_image_outlined)))
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                    child: Text(obj.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(obj.remainingTimeText,
                      style: const TextStyle(
                          color: Colors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(obj.address,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
