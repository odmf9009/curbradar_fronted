import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_translations.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  String _currentLanguage = 'es';
  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('app_language') ?? 'es';
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    if (AppTranslations.translations.containsKey(langCode)) {
      _currentLanguage = langCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_language', langCode);
      notifyListeners();
    }
  }

  String translate(String key) {
    return AppTranslations.translations[_currentLanguage]?[key] ?? key;
  }
}

// Global shortcut for translation
String tr(String key) => LanguageService().translate(key);
