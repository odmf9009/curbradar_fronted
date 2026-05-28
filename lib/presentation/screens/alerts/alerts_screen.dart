import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/services/alerts_service.dart';
import '../../../core/services/objects_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/config/routes.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final LocationService _locationService = LocationService();
  double? _lat;
  double? _lng;
  String _currentCity = '...';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final pos = await _locationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      try {
        final p =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (p.isNotEmpty && mounted) {
          setState(() => _currentCity = p[0].locality ?? tr('tu_area'));
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(tr('comunidad_alertas'),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              bottom: TabBar(
                labelColor: const Color(0xFFFF8A00),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFF8A00),
                tabs: [
                  Tab(
                      text: tr('radar'),
                      icon: const Icon(Icons.radar)),
                  Tab(
                      text: tr('novedades'),
                      icon: const Icon(Icons.new_releases_outlined)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _RadarTab(
                    currentUserId: FirebaseAuth
                            .instance.currentUser?.uid ??
                        ''),
                _NovedadesTab(lat: _lat, lng: _lng, city: _currentCity),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RadarTab extends StatefulWidget {
  final String currentUserId;
  const _RadarTab({required this.currentUserId});
  @override
  State<_RadarTab> createState() => _RadarTabState();
}

class _RadarTabState extends State<_RadarTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final AlertsService _alertsService = AlertsService();
  final ObjectsService _objectsService = ObjectsService();
  List<AlertModel> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    try {
      final alerts = await _alertsService.getMyAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_alerts.isEmpty) {
      return _buildEmpty(tr('no_hay_alertas'), Icons.radar,
          tr('no_hay_alertas_desc'));
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      color: const Color(0xFFFF8A00),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _alerts.length,
        separatorBuilder: (context, i) =>
            const Divider(height: 1, indent: 76),
        itemBuilder: (context, i) =>
            _buildAlertItem(context, _alerts[i]),
      ),
    );
  }

  Widget _buildAlertItem(BuildContext context, AlertModel alert) {
    return InkWell(
      onTap: () async {
        _alertsService.markAsRead(alert.id);
        setState(() => alert.isRead = true);
        try {
          final obj =
              await _objectsService.getObjectById(alert.objectId);
          if (obj != null && mounted) {
            Navigator.pushNamed(context, AppRoutes.objectDetail,
                arguments: obj);
          }
        } catch (_) {}
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: alert.objectImageUrl.isNotEmpty
                    ? Image.network(
                        alert.objectImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: Colors.grey[200],
                          child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.objectTitle,
                      style: TextStyle(
                          fontWeight: alert.isRead
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 16)),
                  Text(
                      tr('a_metros').replaceFirst(
                          '{d}', alert.distance.toInt().toString()),
                      style: const TextStyle(
                          color: Color(0xFFFF8A00),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  Text(_getTimeAgo(alert.createdAt),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (!alert.isRead)
              const Icon(Icons.circle,
                  size: 8, color: Color(0xFFFF8A00)),
            const Icon(Icons.chevron_right,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NovedadesTab extends StatefulWidget {
  final double? lat;
  final double? lng;
  final String city;
  const _NovedadesTab({this.lat, this.lng, required this.city});
  @override
  State<_NovedadesTab> createState() => _NovedadesTabState();
}

class _NovedadesTabState extends State<_NovedadesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ObjectsService _objectsService = ObjectsService();
  List<CurbObject> _objects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  @override
  void didUpdateWidget(_NovedadesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lat != widget.lat || oldWidget.lng != widget.lng) {
      _loadObjects();
    }
  }

  Future<void> _loadObjects() async {
    final lat = widget.lat;
    final lng = widget.lng;
    if (lat == null || lng == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 50 miles ≈ 80467 meters
      final objects = await _objectsService.getNearbyObjects(
        lat: lat,
        lng: lng,
        radiusMeters: 80467,
      );
      if (mounted) {
        setState(() {
          _objects = objects;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_objects.isEmpty) {
      return _buildEmpty(tr('sin_novedades'), Icons.new_releases,
          tr('sin_novedades_desc'));
    }

    return RefreshIndicator(
      onRefresh: _loadObjects,
      color: const Color(0xFFFF8A00),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _objects.length,
        separatorBuilder: (context, i) =>
            const Divider(height: 1, indent: 76),
        itemBuilder: (context, i) =>
            _buildObjectItem(context, _objects[i]),
      ),
    );
  }

  Widget _buildObjectItem(BuildContext context, CurbObject obj) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRoutes.objectDetail,
          arguments: obj),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: obj.imageUrls.isNotEmpty
                    ? Image.network(
                        obj.imageUrls[0],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: Colors.grey[200],
                          child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey),
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(obj.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(obj.category,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14)),
                  Text(_getTimeAgo(obj.createdAt),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(tr('nuevo'),
                  style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

Widget _buildEmpty(String t, IconData i, String s) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(i, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 24),
          Text(t,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey)),
          const SizedBox(height: 12),
          Text(s,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

String _getTimeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return tr('hace_un_momento');
  if (diff.inMinutes < 60) {
    return tr('hace_m').replaceFirst('{m}', diff.inMinutes.toString());
  }
  if (diff.inHours < 24) {
    return tr('hace_h').replaceFirst('{h}', diff.inHours.toString());
  }
  return tr('hace_d').replaceFirst('{d}', diff.inDays.toString());
}
