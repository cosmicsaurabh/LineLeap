import 'package:flutter/material.dart';
import 'package:flutter_scribble/data/repositories/theme_mode_repository.dart';
import 'package:flutter_scribble/presentation/widgets/providers/scribble_notifier.dart';
import 'package:flutter_scribble/presentation/widgets/providers/theme_notifier.dart';
import 'package:flutter_scribble/domain/usecases/set_theme_mode_usecase.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/scribble_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create the repository and use case
  final themeModeRepository = ThemeModeRepositoryImpl();
  final setThemeModeUseCase = SetThemeModeUseCase(themeModeRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(setThemeModeUseCase),
        ),
        ChangeNotifierProvider<ScribbleNotifier>(
          create: (_) => ScribbleNotifier(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: Provider.of<ThemeNotifier>(context).themeMode,
      home: const ScribblePage(),
    );
  }
}
