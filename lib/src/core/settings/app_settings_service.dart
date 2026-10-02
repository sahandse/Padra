import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsService {
  static const _themeKey = 'padra_theme_mode';
  static const _onboardingKey = 'padra_onboarding_done';
  static const _autoScanKey = 'padra_auto_scan';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey) ?? 'system';
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeKey, value);
  }

  Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<bool> loadAutoScan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoScanKey) ?? false;
  }

  Future<void> saveAutoScan(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoScanKey, enabled);
  }

  Future<void> clearPadraLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('padra_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
