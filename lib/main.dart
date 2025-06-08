import 'package:flutter/material.dart';
import 'package:flutter_scribble/data/models/generated_image_model.dart';
import 'package:flutter_scribble/data/repositories/gallery_repository_impl.dart';
import 'package:flutter_scribble/data/repositories/theme_mode_repository.dart';
import 'package:flutter_scribble/domain/usecases/get_image_usecase.dart';
import 'package:flutter_scribble/presentation/pages/home_page.dart';
import 'package:flutter_scribble/presentation/widgets/providers/gallery_notifier.dart';
import 'package:flutter_scribble/presentation/widgets/providers/scribble_notifier.dart';
import 'package:flutter_scribble/presentation/widgets/providers/theme_notifier.dart';
import 'package:flutter_scribble/domain/usecases/set_theme_mode_usecase.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(GeneratedImageModelAdapter());
  final box = await Hive.openBox<GeneratedImageModel>('gallery_history');

  final themeModeRepository = ThemeModeRepositoryImpl();
  final setThemeModeUseCase = SetThemeModeUseCase(themeModeRepository);

  final repo = GalleryRepositoryImpl(box);
  final getImagesUseCase = GetImagesUseCase(repo);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(setThemeModeUseCase),
        ),
        ChangeNotifierProvider<ScribbleNotifier>(
          create: (_) => ScribbleNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => GalleryNotifier(getImagesUseCase: getImagesUseCase),
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
      home: const HomePage(),
    );
  }
}
