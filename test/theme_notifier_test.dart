import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lineleap/data/repositories/theme_mode_repository._impl.dart';
import 'package:lineleap/domain/repositories/theme_mode_repository.dart';
import 'package:lineleap/domain/usecases/get_theme_mode_usecase.dart';
import 'package:lineleap/domain/usecases/set_theme_mode_usecase.dart';
import 'package:lineleap/presentation/common/providers/theme_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a new notifier restores the persisted theme choice', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = ThemeModeRepositoryImpl();
    final original = _buildNotifier(repository);
    final restored = _buildNotifier(repository);
    addTearDown(original.dispose);
    addTearDown(restored.dispose);

    await original.setThemeMode(ThemeMode.dark);
    await restored.restoreThemeMode();

    expect(restored.themeMode, ThemeMode.dark);
  });

  test('an invalid persisted theme falls back to system', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 99});

    final restoredTheme = await ThemeModeRepositoryImpl().getThemeMode();

    expect(restoredTheme, ThemeMode.system);
  });

  testWidgets('the first rendered frame uses the restored theme', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final storedTheme = Completer<ThemeMode>();
    final repository = _DelayedThemeModeRepository(storedTheme.future);
    final notifier = _buildNotifier(repository);
    addTearDown(notifier.dispose);

    var restoreCompleted = false;
    final restoreFuture = notifier.restoreThemeMode();
    restoreFuture.then((_) => restoreCompleted = true);
    await tester.pump();

    expect(restoreCompleted, isFalse);

    storedTheme.complete(ThemeMode.dark);
    await restoreFuture;
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeNotifier>.value(
        value: notifier,
        child: const _ThemeHarness(),
      ),
    );

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final themedContext = tester.element(
      find.byKey(const ValueKey('themed-content')),
    );
    expect(repository.readCalls, 1);
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(Theme.of(themedContext).brightness, Brightness.dark);
  });
}

ThemeNotifier _buildNotifier(ThemeModeRepository repository) {
  return ThemeNotifier(
    setThemeModeUseCase: SetThemeModeUseCase(themeModeRepository: repository),
    getThemeModeUseCase: GetThemeModeUseCase(themeModeRepository: repository),
  );
}

class _ThemeHarness extends StatelessWidget {
  const _ThemeHarness();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: context.watch<ThemeNotifier>().themeMode,
      home: const SizedBox(key: ValueKey('themed-content')),
    );
  }
}

class _DelayedThemeModeRepository implements ThemeModeRepository {
  final Future<ThemeMode> storedTheme;
  int readCalls = 0;

  _DelayedThemeModeRepository(this.storedTheme);

  @override
  Future<ThemeMode> getThemeMode() {
    readCalls++;
    return storedTheme;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {}
}
