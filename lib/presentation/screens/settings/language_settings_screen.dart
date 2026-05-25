import 'package:flutter/material.dart';
import '../../../core/services/language_service.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  final LanguageService _languageService = LanguageService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _languageService,
      builder: (context, _) {
        final currentLang = _languageService.currentLanguage;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              tr('idioma'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF121212),
            elevation: 0,
            centerTitle: true,
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                _buildLanguageOption(
                  'Español',
                  'Spanish',
                  'es',
                  '🇪🇸',
                  currentLang == 'es',
                ),
                _buildLanguageOption(
                  'English',
                  'Inglés',
                  'en',
                  '🇺🇸',
                  currentLang == 'en',
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    currentLang == 'es' 
                      ? 'CurbRadar ajustará la interfaz automáticamente al idioma seleccionado.'
                      : 'CurbRadar will automatically adjust the interface to the selected language.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String title, String subtitle, String code, String flag, bool isSelected) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Color(0xFFFF8A00))
          : null,
      onTap: () => _languageService.setLanguage(code),
    );
  }
}
