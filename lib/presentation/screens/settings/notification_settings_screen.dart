import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _nearbyAlerts = true;
  bool _chatNotifications = true;
  bool _pointsAlerts = true;
  bool _appUpdates = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nearbyAlerts = prefs.getBool('notify_nearby') ?? true;
      _chatNotifications = prefs.getBool('notify_chat') ?? true;
      _pointsAlerts = prefs.getBool('notify_points') ?? true;
      _appUpdates = prefs.getBool('notify_updates') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF8A00)))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildHeader('Alertas de Radar'),
                _buildSwitchTile(
                  'Objetos cercanos',
                  'Recibe avisos cuando hay tesoros a menos de 500m mientras te mueves.',
                  _nearbyAlerts,
                  (val) {
                    setState(() => _nearbyAlerts = val);
                    _saveSetting('notify_nearby', val);
                  },
                ),
                _buildSwitchTile(
                  'Nuevas publicaciones',
                  'Alertas de objetos nuevos publicados en tu ciudad.',
                  _appUpdates,
                  (val) {
                    setState(() => _appUpdates = val);
                    _saveSetting('notify_updates', val);
                  },
                ),
                const Divider(),
                _buildHeader('Actividad Social'),
                _buildSwitchTile(
                  'Mensajes del chat',
                  'Notificaciones de usuarios que quieren recoger tus objetos.',
                  _chatNotifications,
                  (val) {
                    setState(() => _chatNotifications = val);
                    _saveSetting('notify_chat', val);
                  },
                ),
                _buildSwitchTile(
                  'Puntos y Recompensas',
                  'Avisos cuando ganas XP o subes de nivel.',
                  _pointsAlerts,
                  (val) {
                    setState(() => _pointsAlerts = val);
                    _saveSetting('notify_points', val);
                  },
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Puedes cambiar estos ajustes en cualquier momento para personalizar tu experiencia de caza.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFFF8A00),
          fontWeight: FontWeight.bold,
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      ),
      value: value,
      activeColor: const Color(0xFFFF8A00),
      onChanged: onChanged,
    );
  }
}
