import 'package:flutter/material.dart';
import 'package:lineleap/domain/repositories/theme_mode_repository.dart';

class SetThemeModeUseCase {
  final ThemeModeRepository repository;
  SetThemeModeUseCase(this.repository);

  Future<void> call(ThemeMode mode) => repository.setThemeMode(mode);
}
