import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language Provider - Manages app language (English/Kinyarwanda)
class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = true;

  bool get isEnglish => _isEnglish;
  bool get isKinyarwanda => !_isEnglish;
  String get currentLanguage => _isEnglish ? 'en' : 'rw';

  LanguageProvider() {
    _loadLanguage();
  }

  // Load saved language preference
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnglish = prefs.getBool('isEnglish') ?? true;
      notifyListeners();
    } catch (e) {
      _isEnglish = true;
    }
  }

  // Toggle between English and Kinyarwanda
  Future<void> toggleLanguage() async {
    _isEnglish = !_isEnglish;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isEnglish', _isEnglish);
    } catch (e) {
      // Handle error silently
    }
  }

  // Set language directly
  Future<void> setLanguage(bool isEnglish) async {
    if (_isEnglish != isEnglish) {
      _isEnglish = isEnglish;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isEnglish', _isEnglish);
      } catch (e) {
        // Handle error silently
      }
    }
  }

  // Set to English
  Future<void> setEnglish() async {
    await setLanguage(true);
  }

  // Set to Kinyarwanda
  Future<void> setKinyarwanda() async {
    await setLanguage(false);
  }
}
