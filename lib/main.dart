import 'package:flutter/material.dart';
import 'package:lineleap/core/di/injection_container.dart';
import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import 'package:lineleap/data/models/scribble_transformation_hive_model.dart';
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

  // Enhanced error handling for release mode
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('Flutter Error: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  try {
    //Hive initialization
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    Hive.registerAdapter(ScribbleTransformationHiveAdapter());

    //initialize dependencies
    await initDependencies();

    // Permission requests moved to when they're actually needed (in gallery actions)
    // This prevents startup delays and potential issues in release mode

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
  } catch (e, stackTrace) {
    debugPrint('Error during app initialization: $e');
    debugPrintStack(stackTrace: stackTrace);
    runApp(const ErrorApp(error: 'Initialization failed'));
  }
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

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
