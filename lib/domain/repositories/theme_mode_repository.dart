import 'package:flutter/material.dart';

abstract class ThemeModeRepository {
  Future<void> setThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();
}
