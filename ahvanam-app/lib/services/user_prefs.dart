import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/app_lang.dart';
import '../models/ceremony.dart';
import '../theme/app_theme.dart';

/// Remembers the user's tradition so the picker is shown only once.
/// Stored with shared_preferences (Android SharedPreferences /
/// iOS NSUserDefaults), so it survives closing the app, removing it from
/// recents and restarting the phone. Only uninstalling or "Clear data" resets it.
class UserPrefs {
  UserPrefs._();

  static const _key = 'tradition';
  static const _themeKey = 'themeMode';
  static const _langKey = 'appLang';
  static Tradition? tradition;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key);
      for (final t in Tradition.values) {
        if (t.name == name) tradition = t;
      }
      final theme = prefs.getString(_themeKey);
      for (final m in ThemeMode.values) {
        if (m.name == theme) ThemeController.mode.value = m;
      }
      final lang = prefs.getString(_langKey);
      for (final l in AppLang.values) {
        if (l.name == lang) AppLangController.lang.value = l;
      }
    } catch (e) {
      debugPrint('UserPrefs.load failed: $e');
    }
  }

  static Future<void> saveTradition(Tradition t) async {
    tradition = t;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, t.name);
    } catch (e) {
      debugPrint('UserPrefs.save failed: $e');
    }
  }

  static Future<void> saveAppLang(AppLang l) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_langKey, l.name);
    } catch (e) {
      debugPrint('UserPrefs.saveAppLang failed: $e');
    }
  }

  static Future<void> saveThemeMode(ThemeMode m) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, m.name);
    } catch (e) {
      debugPrint('UserPrefs.saveThemeMode failed: $e');
    }
  }
}
