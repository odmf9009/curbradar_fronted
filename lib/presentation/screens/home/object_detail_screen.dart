import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/curb_object.dart';
import '../../../core/models/comment_model.dart';
import '../../../core/services/objects_service.dart';
import '../../../core/services/users_service.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/reward_helper.dart';
import '../../../core/config/routes.dart';

class ObjectDetailScreen extends StatefulWidget {
  const ObjectDetailScreen({super.key});

  @override
  State<ObjectDetailScreen> createState() => _ObjectDetailScreenState();
}

class _ObjectDetailScreenState extends State<ObjectDetailScreen> {
  final ObjectsService _objectsService = ObjectsService();
  final UsersService _usersService = UsersService();
  final UploadService _uploadService = UploadService();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  final LocationService _locationService = LocationService();
  final SocketService _socket = SocketService();
  final TextEditingController _commentController = TextEditingController();
  final PageController _pageController = PageController();

  int _currentPage = 0;
  Timer? _refreshTimer;
  StreamSubscription<Position>? _positionSubscription;

  bool _isLoading = false;
  bool _isFavorite = false;
  bool _alreadyConfirmed = false;
  double _currentDistance = double.infinity;
  Position? _lastUserPosition;

  // Live object state — updated via socket
  CurbObject? _liveObject;

  // Comments — loaded via REST
  List<CommentModel> _comments = [];
  bool _commentsLoaded = false;

  final String _currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // Defer initialization until the first frame so ModalRoute is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initScreen();
    });

    // Refresh every second to update countdowns
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });

    _subscribeToLocation();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _pageController.dispose();
    _refreshTimer?.cancel();
    _positionSubscription?.cancel();
    // Leave socket room for this object
    if (_liveObject != null) {
      _socket.leaveObject(_liveObject!.id);
    }
    _socket.off('object:updated');
    super.dispose();
  }

  Future<void> _initScreen() async {
    final object =
        ModalRoute.of(context)?.settings.arguments as CurbObject?;
    if (object == null) return;

    setState(() => _liveObject = object);

    // Join socket room for real-time updates on this object
    _socket.joinObject(object.id);
    _socket.on('object:updated', _onObjectUpdated);

    await _checkInitialState();
    await _loadComments();
  }

  void _onObjectUpdated(dynamic data) {
    if (!mounted) return;
    try {
      final Map<String, dynamic> json =
          Map<String, dynamic>.from(data as Map);
      final updated = CurbObject.fromJson(json);
      if (updated.id == _liveObject?.id) {
        setState(() => _liveObject = updated);
      }
    } catch (_) {}
  }

  Future<void> _checkInitialState() async {
    await _checkIfFavorite();
    // Note: confirmation status is checked implicitly — if backend returns 409, already confirmed
    final pos = await _locationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _lastUserPosition = pos;
        _updateDistance(pos);
      });
    }
  }

  void _subscribeToLocation() {
    _positionSubscription =
        _locationService.locationStream.listen((position) {
      if (mounted) {
        setState(() {
          _lastUserPosition = position;
          _updateDistance(position);
        });
      }
    });
  }

  void _updateDistance(Position userPos) {
    final object = _liveObject;
    if (object != null) {
      _currentDistance = Geolocator.distanceBetween(
        userPos.latitude,
        userPos.longitude,
        object.latitude,
        object.longitude,
      );
    }
  }

  Future<void> _checkIfFavorite() async {
    try {
      final user = await _usersService.getMyProfile();
      if (user != null && _liveObject != null && mounted) {
        setState(() {
          _isFavorite = user.favorites.contains(_liveObject!.id);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    try {
      final objectId = _liveObject?.id;
      if (objectId == null) return;
      final response =
          await _api.get('${ApiConfig.objects}/$objectId/comments');
      final List<dynamic> data = response.data['comments'] ?? [];
      if (mounted) {
        setState(() {
          _comments =
              data.map((json) => CommentModel.fromJson(json)).toList();
          _commentsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _commentsLoaded = true);
    }
  }

  Future<void> _toggleFavorite(String objectId) async {
    final newStatus = !_isFavorite;
    setState(() => _isFavorite = newStatus);

    try {
      await _usersService.toggleFavorite(objectId, isFavorite: newStatus);
    } catch (e) {
      setState(() => _isFavorite = !newStatus); // Rollback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al guardar favorito: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showReportDialog(String objectId) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedReason = 'Spam o contenido falso';
        final reasons = [
          'Spam o contenido falso',
          'Ya no está en el lugar',
          'Contenido inapropiado',
          'Ubicación incorrecta',
          'Otro',
        ];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reportar hallazgo',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: const Color(0xFFFF8A00),
                    onChanged: (val) {
                      setDialogState(() => selectedReason = val!);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar',
                      style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _objectsService.reportObject(
                          objectId, selectedReason);
                    } catch (_) {}
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Gracias, hemos recibido tu reporte.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    minimumSize: const Size(100, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Enviar',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _postComment(String objectId) async {
    if (_commentController.text.trim().isEmpty) return;

    final text = _commentController.text.trim();
    _commentController.clear();
    FocusScope.of(context).unfocus();

    try {
      final response = await _api.post(
        '${ApiConfig.objects}/$objectId/comments',
        data: {'text': text},
      );
      final newComment =
          CommentModel.fromJson(response.data['comment'] ?? response.data);
      if (mounted) {
        setState(() => _comments.add(newComment));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al publicar comentario: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFullScreenImage(
      BuildContext context, List<String> urls, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: urls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      urls[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareObject(CurbObject object) {
    final String text = '¡Mira lo que encontré en CurbRadar!\n\n'
        'Objeto: ${object.title}\n'
        'Categoría: ${object.category}\n'
        'Dirección: ${object.address}\n\n'
        '¡Descarga CurbRadar para ver más tesoros en la acera!';

    Share.share(text, subject: 'Hallazgo en CurbRadar');
  }

  Future<void> _showVoyEnCaminoReminder(String id) async {
    // Check if user has an active claim via current objects list from backend
    setState(() => _isLoading = true);

    CurbObject? activeClaim;
    try {
      final myObjects = await _usersService.getMyObjects();
      activeClaim = myObjects.firstWhere(
        (o) =>
            o.status == CurbObjectStatus.onMyWay &&
            o.claimedByUserId == _currentUserId,
        orElse: () => throw StateError('none'),
      );
    } catch (_) {
      activeClaim = null;
    }

    setState(() => _isLoading = false);

    if (activeClaim != null && activeClaim.id != id) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Límite de actividad',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Text(
                'Ya tienes un objeto marcado como "Voy en camino" (${activeClaim!.title}). Para poder ir por este, primero debes recoger o abandonar el anterior.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.objectDetail,
                    arguments: activeClaim,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ver mi objeto actual',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF1976D2)),
            SizedBox(width: 10),
            Text('¡Recordatorio!',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Has marcado que vas en camino. Una vez llegues al destino, por favor, recuerda actualizar el estado del objeto para que otros usuarios puedan ver la información actualizada. Recuerde que tiene 2 horas para llegar al lugar seleccionado, de no ser así y no actualizar el estado del objeto, este se liberará automáticamente para que otros usuarios puedan verlo.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(id, CurbObjectStatus.onMyWay, isConfirming: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              minimumSize: const Size(double.infinity, 45),
            ),
            child: const Text('Entendido, ¡voy para allá!',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchNavigation(double lat, double lng) async {
    final googleMapsUrl =
        Uri.parse('google.navigation:q=$lat,$lng&mode=d');
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

  Future<void> _updatePhoto(String objectId) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

    try {
      final imageUrl =
          await _uploadService.uploadObjectImage(File(pickedFile.path));

      // PATCH image URL to backend — backend awards points if first time
      final response = await _api.patch(
        '${ApiConfig.objects}/$objectId/image',
        data: {'imageUrl': imageUrl},
      );

      final bool isFirstTime = response.data['firstTime'] == true;
      if (isFirstTime && mounted) {
        RewardHelper.showReward(context, 20);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Foto actualizada con éxito!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error al actualizar foto: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildStatusIndicator(CurbObjectStatus status,
      {String? claimedBy, String? eta}) {
    Color color;
    String text;
    switch (status) {
      case CurbObjectStatus.available:
        color = Colors.green;
        text = 'Disponible';
        break;
      case CurbObjectStatus.onMyWay:
        color = Colors.blue;
        String baseText = claimedBy != null && claimedBy.isNotEmpty
            ? '@$claimedBy va en camino'
            : 'Alguien va en camino';
        text =
            eta != null && eta.isNotEmpty ? '$baseText ($eta)' : baseText;
        break;
      case CurbObjectStatus.pickedUp:
        color = Colors.red;
        text = 'Ya no está';
        break;
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == CurbObjectStatus.onMyWay)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child:
                  Icon(Icons.directions_run, size: 14, color: Colors.blue),
            ),
          Text(
            text,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CurbObject? routeObject =
        ModalRoute.of(context)?.settings.arguments as CurbObject?;
    final liveObject = _liveObject ?? routeObject;

    if (liveObject == null) {
      return const Scaffold(
          body: Center(child: Text('Error: No se encontró el objeto')));
    }

    final bool isOwner = liveObject.postedByUserId == _currentUserId;
    final bool isInRange = _currentDistance <= 20.1 || isOwner;
    final bool isInRangePickedUp = _currentDistance <= 20.1 || isOwner;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Header with Slider and Hero
                  Stack(
                    children: [
                      Hero(
                        tag: 'image_${liveObject.id}',
                        child: Container(
                          height: 350,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: liveObject.imageUrls.isEmpty
                              ? const Icon(Icons.image,
                                  size: 100, color: Colors.white)
                              : PageView.builder(
                                  controller: _pageController,
                                  onPageChanged: (index) =>
                                      setState(() => _currentPage = index),
                                  itemCount: liveObject.imageUrls.length,
                                  itemBuilder: (context, index) =>
                                      GestureDetector(
                                    onTap: () => _showFullScreenImage(
                                        context, liveObject.imageUrls, index),
                                    child: Image.network(
                                      liveObject.imageUrls[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      if (liveObject.imageUrls.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: liveObject.imageUrls
                                .asMap()
                                .entries
                                .map((entry) {
                              return Container(
                                width: 8.0,
                                height: 8.0,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 4.0),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(
                                      _currentPage == entry.key ? 0.9 : 0.4),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      // Tap-to-zoom hint badge
                      Positioned(
                        bottom: 45,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Toca para ampliar',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCircleButton(Icons.arrow_back,
                                  () => Navigator.pop(context)),
                              Row(
                                children: [
                                  _buildCircleButton(Icons.ios_share,
                                      () => _shareObject(liveObject)),
                                  const SizedBox(width: 12),
                                  _buildCircleButton(
                                    _isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    () => _toggleFavorite(liveObject.id),
                                    color: _isFavorite
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                  if (liveObject.isChatEnabled &&
                                      liveObject.status ==
                                          CurbObjectStatus.onMyWay)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(left: 12),
                                      child: _buildCircleButton(
                                        Icons.chat_bubble_outline,
                                        () => Navigator.pushNamed(
                                            context, AppRoutes.chat,
                                            arguments: liveObject),
                                        color: const Color(0xFFFF8A00),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  _buildCircleMenu(liveObject.id),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                liveObject.title,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  _toggleFavorite(liveObject.id),
                              icon: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite
                                    ? Colors.red
                                    : Colors.black,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(tr('cerca_de_ti'),
                                style:
                                    const TextStyle(color: Colors.grey)),
                            const Spacer(),
                            Text(
                              '${tr('publicado')} ${_getTimeAgo(liveObject.createdAt)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20)),
                          child: Text(liveObject.category,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(height: 16),

                        // Countdown timer
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined,
                                  color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text('${tr('tiempo_restante')}:',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(
                                liveObject.remainingTimeText,
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        Text(liveObject.description,
                            style: const TextStyle(
                                fontSize: 16, height: 1.5)),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.black87),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(liveObject.address,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: liveObject.status ==
                                          CurbObjectStatus.onMyWay &&
                                      liveObject.claimedByUserId !=
                                          _currentUserId
                                  ? _showBlockedMessage
                                  : () {
                                      _launchNavigation(liveObject.latitude,
                                          liveObject.longitude);
                                      Navigator.pop(context, true);
                                    },
                              icon: const Icon(Icons.directions, size: 18),
                              label: Text(tr('ir')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: liveObject.status ==
                                            CurbObjectStatus.onMyWay &&
                                        liveObject.claimedByUserId !=
                                            _currentUserId
                                    ? Colors.grey[300]
                                    : const Color(0xFF1976D2),
                                foregroundColor: liveObject.status ==
                                            CurbObjectStatus.onMyWay &&
                                        liveObject.claimedByUserId !=
                                            _currentUserId
                                    ? Colors.grey[500]
                                    : Colors.white,
                                minimumSize: const Size(80, 40),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Location precision debug panel
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.gps_fixed,
                                      size: 14, color: Colors.blue),
                                  SizedBox(width: 6),
                                  Text('Precisión de Localización',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildLocationRow('Tu posición:',
                                  _lastUserPosition?.latitude,
                                  _lastUserPosition?.longitude),
                              const SizedBox(height: 4),
                              _buildLocationRow('Objeto:', liveObject.latitude,
                                  liveObject.longitude),
                              const SizedBox(height: 8),
                              const Text(
                                '* Nota: Si los números no coinciden estando tú encima del objeto, es posible que el GPS del móvil tenga interferencias o que el objeto fuera publicado con un margen de error.',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Divider(),
                        const SizedBox(height: 16),

                        // Status Section
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estado del objeto',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            _buildStatusIndicator(
                              liveObject.status,
                              claimedBy: liveObject.claimedByUserName,
                              eta: liveObject.claimedUserEta,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildActionButton(
                                    tr('sigue_ahi'),
                                    (_alreadyConfirmed && !isOwner)
                                        ? Colors.grey
                                        : Colors.green,
                                    Colors.white,
                                    onPressed: (liveObject.status ==
                                                CurbObjectStatus.onMyWay &&
                                            liveObject.claimedByUserId !=
                                                _currentUserId)
                                        ? _showBlockedMessage
                                        : ((_alreadyConfirmed && !isOwner) ||
                                                (!isInRange && !isOwner)
                                            ? null
                                            : () => _updateStatus(
                                                liveObject.id,
                                                CurbObjectStatus.available,
                                                isConfirming: true)),
                                  ),
                                  if (!_alreadyConfirmed && !isOwner)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _currentDistance == double.infinity
                                            ? 'Calculando distancia...'
                                            : (isInRange
                                                ? '¡Estás en rango!'
                                                : 'A ${_currentDistance.toInt()}m (necesitas < 20m)'),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isInRange
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildActionButton(
                                liveObject.status ==
                                            CurbObjectStatus.onMyWay &&
                                        liveObject.claimedByUserId ==
                                            _currentUserId
                                    ? tr('abandonar')
                                    : tr('on_my_way'),
                                liveObject.status ==
                                            CurbObjectStatus.onMyWay &&
                                        liveObject.claimedByUserId ==
                                            _currentUserId
                                    ? Colors.red.shade400
                                    : const Color(0xFF1976D2),
                                Colors.white,
                                subtitle: liveObject.status ==
                                            CurbObjectStatus.onMyWay &&
                                        liveObject.claimedByUserId ==
                                            _currentUserId
                                    ? liveObject.remainingClaimTimeText
                                    : '',
                                onPressed: liveObject.status ==
                                            CurbObjectStatus.onMyWay &&
                                        liveObject.claimedByUserId !=
                                            _currentUserId
                                    ? _showBlockedMessage
                                    : (liveObject.status ==
                                            CurbObjectStatus.available
                                        ? () => _showVoyEnCaminoReminder(
                                            liveObject.id)
                                        : () => _updateStatus(
                                            liveObject.id,
                                            CurbObjectStatus.available,
                                            isConfirming: false)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildActionButton(
                                    tr('actualizar_foto'),
                                    Colors.orange,
                                    Colors.white,
                                    onPressed: (liveObject.status ==
                                                CurbObjectStatus.onMyWay &&
                                            liveObject.claimedByUserId !=
                                                _currentUserId)
                                        ? _showBlockedMessage
                                        : (!isInRangePickedUp && !isOwner
                                            ? null
                                            : () =>
                                                _updatePhoto(liveObject.id)),
                                  ),
                                  if (!isOwner)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _currentDistance == double.infinity
                                            ? 'Calculando distancia...'
                                            : (isInRangePickedUp
                                                ? '¡Estás en rango!'
                                                : 'A ${_currentDistance.toInt()}m (necesitas < 20m)'),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isInRangePickedUp
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildActionButton(
                                    tr('ya_fue_recogido'),
                                    Colors.white,
                                    Colors.red,
                                    borderColor: Colors.red,
                                    onInfoTap: () => _showPickedUpInfo(),
                                    onPressed: (liveObject.status ==
                                                CurbObjectStatus.onMyWay &&
                                            liveObject.claimedByUserId !=
                                                _currentUserId)
                                        ? _showBlockedMessage
                                        : (!isInRangePickedUp && !isOwner
                                            ? null
                                            : () => _showPickedUpDialog(
                                                liveObject)),
                                  ),
                                  if (!isOwner)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _currentDistance == double.infinity
                                            ? 'Calculando distancia...'
                                            : (isInRangePickedUp
                                                ? '¡Estás en rango!'
                                                : 'A ${_currentDistance.toInt()}m (necesitas < 20m)'),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isInRangePickedUp
                                              ? Colors.green
                                              : Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (liveObject.status == CurbObjectStatus.onMyWay &&
                            liveObject.remainingClaimTimeText.isNotEmpty &&
                            liveObject.remainingClaimTimeText != 'Expirado')
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.blue, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13),
                                        children: [
                                          const TextSpan(
                                              text:
                                                  'El objeto se liberará en '),
                                          TextSpan(
                                            text: liveObject
                                                .remainingClaimTimeText,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue),
                                          ),
                                          const TextSpan(
                                              text:
                                                  ' sino se actualiza su estado'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),

                        const Divider(),
                        const SizedBox(height: 16),
                        // Poster profile link
                        InkWell(
                          onTap: () => Navigator.pushNamed(
                              context, AppRoutes.publicProfile,
                              arguments: liveObject.postedByUserId),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.grey[200],
                                child: Icon(Icons.person,
                                    color: Colors.grey[400]),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '@${liveObject.postedByUserName}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const Text(
                                    'Ver perfil del cazador',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Divider(),
                        const SizedBox(height: 24),
                        Text(tr('comunidad'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),

                        // Comments List — REST loaded, not stream
                        if (!_commentsLoaded)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(
                                color: Color(0xFFFF8A00)),
                          ))
                        else if (_comments.isEmpty)
                          const Text('Sé el primero en comentar',
                              style: TextStyle(color: Colors.grey))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.grey[200],
                                      backgroundImage: NetworkImage(
                                          'https://i.pravatar.cc/150?u=${comment.userId}'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(comment.userName,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 14)),
                                          const SizedBox(height: 2),
                                          Text(comment.text,
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Text(
                                              _getTimeAgo(
                                                  comment.createdAt),
                                              style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comment Input
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: tr('comentario_hint'),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _postComment(liveObject.id),
                    icon:
                        const Icon(Icons.send, color: Color(0xFFFF8A00)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  Widget _buildCircleButton(IconData icon, VoidCallback onTap,
      {Color color = Colors.black}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration:
            const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildCircleMenu(String objectId) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'report') _showReportDialog(objectId);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.report_problem_outlined,
                  color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Reportar este hallazgo',
                  style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
            color: Colors.white, shape: BoxShape.circle),
        child:
            const Icon(Icons.more_vert, color: Colors.black, size: 20),
      ),
    );
  }

  void _showBlockedMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Este objeto ha sido seleccionado por otro usuario para su recogida, espere por favor que el usuario llegue a su origen y modifique el estado del objeto'),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showAlreadyConfirmedMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Usted ya ha confirmado que este objeto sigue ahí.'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  void _showPickedUpInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Información',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Asegurese antes de marcar la opcion "Ya fue recogido", que no quede ningun objeto, de dejar alguno favor de tocar el boton de "Actualizar (Nueva foto)".',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido',
                style: TextStyle(
                    color: Color(0xFFFF8A00),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPickedUpDialog(CurbObject object) {
    final bool isOwner = object.postedByUserId == _currentUserId;

    if (isOwner) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirmar recogida',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            '¿Está seguro que no queda ningún objeto en el lugar?',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateStatus(object.id, CurbObjectStatus.pickedUp);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sí, se llevaron todo',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    // Distance validation (20 meters)
    if (_currentDistance > 20.1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Estás demasiado lejos (${_currentDistance.toInt()}m). Debes estar a menos de 20 metros para marcar como recogido.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Qué pasó con el objeto?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          '¿Se han llevado todo o todavía queda algo de valor en el lugar?',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updatePhoto(object.id);
            },
            child: const Text('Todavía queda algo',
                style: TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(object.id, CurbObjectStatus.pickedUp);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Se llevaron todo',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color bgColor,
    Color textColor, {
    Color? borderColor,
    required VoidCallback? onPressed,
    String subtitle = '',
    VoidCallback? onInfoTap,
  }) {
    final bool isBlocked = onPressed == _showBlockedMessage;

    return Stack(
      children: [
        ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isBlocked ? Colors.grey[300] : bgColor,
            foregroundColor:
                isBlocked ? Colors.grey[500] : textColor,
            disabledBackgroundColor: Colors.grey[200],
            disabledForegroundColor: Colors.grey[400],
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: borderColor != null && onPressed != null
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.grey))
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.normal),
                          textAlign: TextAlign.center),
                  ],
                ),
        ),
        if (onInfoTap != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onInfoTap,
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.help_outline,
                    size: 16, color: Colors.red),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _updateStatus(
    String id,
    CurbObjectStatus status, {
    bool isConfirming = false,
  }) async {
    setState(() => _isLoading = true);
    try {
      final bool isOwner = _liveObject?.postedByUserId == _currentUserId;

      if (isConfirming) {
        if (_alreadyConfirmed && !isOwner) {
          _showAlreadyConfirmedMessage();
          setState(() => _isLoading = false);
          return;
        }

        if (!isOwner && _currentDistance > 20.1) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Estás demasiado lejos (${_currentDistance.toInt()}m). Debes estar a menos de 20 metros para confirmar.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        // confirmStillThere — backend awards +10 points automatically
        final bool firstTime =
            await _objectsService.confirmStillThere(id);

        if (!firstTime && !isOwner) {
          _showAlreadyConfirmedMessage();
          setState(() => _isLoading = false);
          return;
        }

        setState(() => _alreadyConfirmed = true);

        // Show reward widget — backend actually awarded the points
        if (mounted) {
          RewardHelper.showReward(context, 10);
        }
      } else {
        // Status change: onMyWay / available (abandon) / pickedUp
        final statusStr = status.name; // 'available', 'onMyWay', 'pickedUp'
        await _objectsService.updateStatus(id, statusStr);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  Widget _buildLocationRow(
      String label, double? lat, double? lng) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.black87)),
        Text(
          lat != null && lng != null
              ? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'
              : 'Esperando señal...',
          style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.blueGrey),
        ),
      ],
    );
  }
}
