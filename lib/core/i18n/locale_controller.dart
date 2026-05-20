library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();
  static const String _prefKey = 'app_language';

  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code == 'ln') {
      _locale = const Locale('ln');
      notifyListeners();
      return;
    }
    _locale = const Locale('fr');
  }

  Future<void> setLanguageCode(String code) async {
    final next = code == 'ln' ? const Locale('ln') : const Locale('fr');
    if (_locale == next) return;
    _locale = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, next.languageCode);
  }
}
