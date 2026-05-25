import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/home_map_screen.dart';
import '../alerts/alerts_screen.dart';
import '../ranking/ranking_screen.dart';
import '../profile/profile_screen.dart';
import '../../../core/config/routes.dart';
import '../../../core/services/users_service.dart';
import '../../../core/services/proximity_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/socket_service.dart';
import '../../../core/services/language_service.dart';
import '../../../core/models/user_model.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final UsersService _usersService = UsersService();
  final LocationService _locationService = LocationService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final SocketService _socket = SocketService();

  ConnectivityStatus _connectivityStatus = ConnectivityStatus.online;
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  bool _hasCheckedAlias = false;
  bool _isOnline = false;
  Timer? _locationSyncTimer;

  @override
  void initState() {
    super.initState();
    _checkUserAlias();
    _startRadar();
    _syncOnlineStatus();
    _initConnectivity();
    _connectSocket();
  }

  @override
  void dispose() {
    _locationSyncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _connectivityService.dispose();
    _socket.leaveMap();
    super.dispose();
  }

  Future<void> _connectSocket() async {
    await _socket.connect();
  }

  void _initConnectivity() {
    _connectivitySubscription =
        _connectivityService.statusStream.listen((status) {
      if (mounted) {
        if (_connectivityStatus == ConnectivityStatus.offline &&
            status == ConnectivityStatus.online) {
          _showStatusSnackBar('¡Estás de vuelta! Reconectando...', Colors.green);
          // Reconnect socket when back online
          _socket.connect();
        } else if (status == ConnectivityStatus.offline) {
          _showStatusSnackBar('Sin conexión. Modo offline activo.', Colors.orange);
        }
        setState(() => _connectivityStatus = status);
      }
    });
  }

  void _showStatusSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _syncOnlineStatus() async {
    try {
      final user = await _usersService.getMyProfile();
      if (user != null && mounted) {
        setState(() => _isOnline = user.isOnline);
        if (_isOnline) _startLocationSync();
      }
    } catch (e) {
      print('[MainNav] Error syncing online status: $e');
    }
  }

  void _startLocationSync() {
    _locationSyncTimer?.cancel();
    _locationSyncTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!_isOnline) {
        timer.cancel();
        return;
      }
      final pos = await _locationService.getCurrentLocation();
      if (pos != null) {
        await _usersService.updateLocation(pos.latitude, pos.longitude,
            isOnline: true);
        // Also broadcast to socket for hunters feature
        _socket.updateMyLocation(pos.latitude, pos.longitude);
      }
    });
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    setState(() => _isOnline = value);

    if (value) {
      final pos = await _locationService.getCurrentLocation();
      await _usersService.updateLocation(
        pos?.latitude ?? 0,
        pos?.longitude ?? 0,
        isOnline: true,
      );
      if (pos != null) {
        _socket.updateMyLocation(pos.latitude, pos.longitude);
        _socket.joinHunters();
      }
      _startLocationSync();
    } else {
      await _usersService.updateLocation(0, 0, isOnline: false);
      _locationSyncTimer?.cancel();
    }
  }

  void _startRadar() {
    ProximityService().startMonitoring();
  }

  Future<void> _checkUserAlias() async {
    if (_hasCheckedAlias) return;

    try {
      final user = await _usersService.getMyProfile();

      if (user != null && user.username.isEmpty) {
        if (mounted) {
          _showMandatoryAliasDialog(context, user);
        }
      }
    } catch (e) {
      print('[MainNav] Error checking alias: $e');
    }
    _hasCheckedAlias = true;
  }

  void _showMandatoryAliasDialog(BuildContext context, UserModel user) {
    final TextEditingController controller = TextEditingController();
    bool isLanguageStep = false;
    String selectedLang = LanguageService().currentLanguage;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                isLanguageStep
                    ? 'Idioma de preferencia'
                    : 'Configura tu Alias',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isLanguageStep) ...[
                    const Text(
                      'Para proteger tu privacidad, necesitas elegir un nombre público (alias) para usar en la comunidad.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Ej: CazadorPro88',
                        prefixText: '@',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      'Selecciona el idioma que prefieras para la interfaz de la aplicación.',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedLang = 'es'),
                            child: _buildLangOption(
                                '🇪🇸', 'Español', selectedLang == 'es'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setDialogState(() => selectedLang = 'en'),
                            child: _buildLangOption(
                                '🇺🇸', 'English', selectedLang == 'en'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '* Puedes cambiarlo más tarde en los ajustes de la APP.',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!isLanguageStep) {
                            final alias = controller.text
                                .trim()
                                .replaceAll('@', '');

                            if (alias.length < 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'El alias debe tener al menos 3 caracteres')),
                              );
                              return;
                            }

                            // Try to update — if 409, alias is taken
                            setDialogState(() => isSaving = true);
                            try {
                              await _usersService.updateProfile(
                                  username: alias);
                              setDialogState(() {
                                isSaving = false;
                                isLanguageStep = true;
                              });
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (e.toString().contains('409') ||
                                  e.toString().toLowerCase().contains('taken') ||
                                  e.toString().toLowerCase().contains('uso')) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'El alias "@$alias" ya está en uso. Prueba con otro.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red),
                                  );
                                }
                              }
                            }
                          } else {
                            // Save language and finish
                            await LanguageService().setLanguage(selectedLang);
                            final alias = controller.text
                                .trim()
                                .replaceAll('@', '');

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(selectedLang == 'es'
                                        ? '¡Bienvenido, @$alias!'
                                        : 'Welcome, @$alias!')),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          isLanguageStep
                              ? (selectedLang == 'es' ? 'Finalizar' : 'Finish')
                              : 'Siguiente',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLangOption(String flag, String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFF8A00).withOpacity(0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFFF8A00) : Colors.grey[300]!,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xFFFF8A00)
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeMapScreen(
        isOnline: _isOnline,
        onToggleOnline: _toggleOnlineStatus,
        connectivityStatus: _connectivityStatus,
      ),
      const AlertsScreen(),
      const RankingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'main_fab',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.publish),
        backgroundColor: const Color(0xFFFF8A00),
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.map_outlined, tr('mapa')),
              _buildNavItem(
                  1, Icons.notifications_none_rounded, tr('alertas')),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(
                  2, Icons.emoji_events_outlined, tr('ranking')),
              _buildNavItem(
                  3, Icons.person_outline_rounded, tr('perfil')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFFFF8A00) : Colors.grey;

    return InkWell(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
