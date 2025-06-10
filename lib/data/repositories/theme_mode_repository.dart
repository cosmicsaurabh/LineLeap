import 'package:flutter/material.dart';
import 'package:lineleap/domain/usecases/set_theme_mode_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeRepositoryImpl implements ThemeModeRepository {
  static const _key = 'theme_mode';

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_key);
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index];
  }
}
