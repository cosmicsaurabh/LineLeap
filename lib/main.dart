import 'package:flutter/material.dart';
import 'package:lineleap/core/di/injection_container.dart';
import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import 'package:lineleap/data/models/generated_image_model.dart';
import 'package:lineleap/presentation/features/nav_bar.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/providers/theme_notifier.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //Hive initialization

  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(ScribbleTransformationHiveAdapter());

  //initialize dependencies
  await initDependencies();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => sl<ThemeNotifier>(),
        ),
        ChangeNotifierProvider<EnhancedScribbleNotifier>(
          create: (_) => sl<EnhancedScribbleNotifier>(),
        ),
        ChangeNotifierProvider(create: (_) => sl<GalleryNotifier>()),
        ChangeNotifierProvider(create: (_) => sl<GenerationProvider>()),
        ChangeNotifierProvider<GenerationQueueNotifier>(
          create: (_) => sl<GenerationQueueNotifier>(),
        ),
        ChangeNotifierProvider(create: (_) => sl<QueueStatusProvider>()),
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Provider.of<ThemeNotifier>(context).themeMode,
      home: const NavBar(),
    );
  }
}
