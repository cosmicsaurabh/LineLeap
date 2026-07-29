import 'package:flutter/material.dart';
import 'package:lineleap/domain/repositories/theme_mode_repository.dart';

class GetThemeModeUseCase {
  final ThemeModeRepository themeModeRepository;

  GetThemeModeUseCase({required this.themeModeRepository});

  Future<ThemeMode> call() => themeModeRepository.getThemeMode();
}
