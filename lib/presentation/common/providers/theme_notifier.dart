import 'package:flutter/material.dart';
import 'package:lineleap/domain/usecases/get_theme_mode_usecase.dart';
import 'package:lineleap/domain/usecases/set_theme_mode_usecase.dart';

class ThemeNotifier extends ChangeNotifier {
  final SetThemeModeUseCase setThemeModeUseCase;
  final GetThemeModeUseCase getThemeModeUseCase;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeNotifier({
    required this.setThemeModeUseCase,
    required this.getThemeModeUseCase,
  });

  ThemeMode get themeMode => _themeMode;

  Future<void> restoreThemeMode() async {
    _themeMode = await getThemeModeUseCase();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await setThemeModeUseCase(mode);
    notifyListeners();
  }
}
