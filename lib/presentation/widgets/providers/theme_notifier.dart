import 'package:flutter/material.dart';
import 'package:lineleap/domain/usecases/set_theme_mode_usecase.dart';

class ThemeNotifier extends ChangeNotifier {
  final SetThemeModeUseCase setThemeModeUseCase;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeNotifier(this.setThemeModeUseCase);

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await setThemeModeUseCase(mode);
    notifyListeners();
  }
}
