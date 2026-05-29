import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/routes.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentRadiusText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final radius = prefs.getDouble('search_radius') ?? 10.0;
    if (mounted) {
      setState(() {
        _currentRadiusText = '${radius.toInt()} ${tr('millas')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return ListenableBuilder(
      listenable: LanguageService(),
      builder: (context, _) {
        _loadCurrentSettings();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              tr('ajustes'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            centerTitle: true,
          ),
          body: ListView(
            children: [
              _buildSettingsItem(
                Icons.notifications_none_rounded,
                tr('notificaciones'),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.notificationSettings),
              ),
              _buildSettingsItem(
                Icons.track_changes_rounded,
                tr('radio_busqueda'),
                trailingText: _currentRadiusText,
                onTap: () async {
                  await Navigator.pushNamed(
                      context, AppRoutes.searchRadiusSettings);
                  _loadCurrentSettings();
                },
              ),
              _buildSettingsItem(
                Icons.lock_outline_rounded,
                tr('privacidad'),
                onTap: () =>
                    Navigator.pushNamed(context, AppRoutes.privacySettings),
              ),
              _buildSettingsItem(
                Icons.language_rounded,
                tr('idioma'),
                trailingText: LanguageService().currentLanguage == 'es'
                    ? 'Español'
                    : 'English',
                onTap: () async {
                  await Navigator.pushNamed(
                      context, AppRoutes.languageSettings);
                  _loadCurrentSettings();
                },
              ),
              _buildSettingsItem(
                Icons.verified_user_outlined,
                tr('politica_privacidad'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
              ),
              _buildSettingsItem(
                Icons.history_rounded,
                tr('terminos_condiciones'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
              ),
              _buildSettingsItem(
                Icons.gavel_rounded,
                tr('licencias_terceros'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.licenses),
              ),
              _buildSettingsItem(
                Icons.help_outline_rounded,
                tr('ayuda_soporte'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.helpSupport),
              ),
              _buildSettingsItem(
                Icons.info_outline_rounded,
                tr('acerca_de'),
                onTap: () => Navigator.pushNamed(context, AppRoutes.about),
              ),
              const SizedBox(height: 16),
              _buildSettingsItem(
                Icons.logout_rounded,
                tr('cerrar_sesion'),
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () async {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.login, (route) => false);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title, {
    String? trailingText,
    Color textColor = Colors.black87,
    Color iconColor = Colors.black87,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          leading: Icon(icon, color: iconColor, size: 24),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          trailing: SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
          onTap: onTap,
        ),
        const Divider(height: 1, indent: 24, endIndent: 24),
      ],
    );
  }
}
