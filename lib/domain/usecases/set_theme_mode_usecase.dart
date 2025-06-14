import 'package:flutter/material.dart';
import 'package:lineleap/domain/repositories/theme_mode_repository.dart';

class SetThemeModeUseCase {
  final ThemeModeRepository themeModeRepository;
  SetThemeModeUseCase({required this.themeModeRepository});

  Future<void> call(ThemeMode mode) => themeModeRepository.setThemeMode(mode);
}
