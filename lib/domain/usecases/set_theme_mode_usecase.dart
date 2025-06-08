import 'package:flutter/material.dart';

abstract class ThemeModeRepository {
  Future<void> setThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();
}

class SetThemeModeUseCase {
  final ThemeModeRepository repository;
  SetThemeModeUseCase(this.repository);

  Future<void> call(ThemeMode mode) => repository.setThemeMode(mode);
}
