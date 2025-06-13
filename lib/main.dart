import 'package:flutter/material.dart';
import 'package:lineleap/core/service/image_storage_service.dart';
import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import 'package:lineleap/data/models/generated_image_model.dart';
import 'package:lineleap/data/remote/ai_horde_api.dart';
import 'package:lineleap/data/repositories/gallery_repository_impl.dart';
import 'package:lineleap/data/repositories/generation_queue_repo_impl.dart';
import 'package:lineleap/data/repositories/image_save_load_repository_impl.dart';
import 'package:lineleap/data/repositories/theme_mode_repository.dart';
import 'package:lineleap/data/services/horde_generation_service_impl.dart';
import 'package:lineleap/domain/usecases/delete_gallery_image_usecase.dart';
import 'package:lineleap/domain/usecases/enqueue_generation_request_usecase.dart';
import 'package:lineleap/domain/usecases/get_gallery_images_usecase.dart';
import 'package:lineleap/domain/usecases/get_generation_queue_usecase.dart';
import 'package:lineleap/domain/usecases/process_generation_queue_usecase.dart';
import 'package:lineleap/domain/usecases/save_generatedModel_usecase.dart';
import 'package:lineleap/domain/usecases/save_image_usecase.dart';
import 'package:lineleap/presentation/features/nav_bar.dart';
import 'package:lineleap/presentation/common/widgets/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/widgets/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/widgets/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/common/widgets/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/widgets/providers/theme_notifier.dart';
import 'package:lineleap/domain/usecases/set_theme_mode_usecase.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(GeneratedImageModelAdapter());
  final box = await Hive.openBox<GeneratedImageModel>('gallery_history');

  final themeModeRepository = ThemeModeRepositoryImpl();
  final setThemeModeUseCase = SetThemeModeUseCase(themeModeRepository);

  final imageStorageService = ImageStorageService();
  final imageSaveLoadRepository = ImageSaveLoadRepositoryImpl(
    imageStorageService,
    box,
  );
  final saveImageUseCase = SaveImageUseCase(imageSaveLoadRepository);

  final galleryRepository = GalleryRepositoryImpl(box);
  final getGalleryImagesUseCase = GetGalleryImagesUseCase(galleryRepository);
  final deleteGalleryImageUseCase = DeleteGalleryImageUseCase(
    galleryRepository,
  );
  final GenerationQueueRepositoryImpl generationQueueRepository =
      GenerationQueueRepositoryImpl(GenerationQueueNotifier());
  final enqueueUseCase = EnqueueGenerationRequestUseCase(
    generationQueueRepository,
  );
  final generationService = HordeGenerationServiceImpl(
    AIHordeAPI(),
    imageStorageService,
  ); // Replace with your actual service implementation
  final processUseCase = ProcessGenerationQueueUseCase(
    queueRepository: generationQueueRepository,
    generationService: generationService,
  );
  final queueRepository = GenerationQueueRepositoryImpl(
    GenerationQueueNotifier(),
  );
  final getQueueUseCase = GetGenerationQueueUseCase(generationQueueRepository);
  final SaveGeneratedModelUseCase saveGeneratedModelUseCase =
      SaveGeneratedModelUseCase(galleryRepository);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => ThemeNotifier(setThemeModeUseCase),
        ),
        ChangeNotifierProvider<EnhancedScribbleNotifier>(
          create: (_) => EnhancedScribbleNotifier(),
        ),
        ChangeNotifierProvider(
          create:
              (_) => GalleryNotifier(
                getGalleryImagesUseCase: getGalleryImagesUseCase,
                deleteGalleryImageUseCase: deleteGalleryImageUseCase,
                saveImageUseCase: saveImageUseCase,
                saveImageToGalleryUseCase: saveGeneratedModelUseCase,
              ),
        ),
        ChangeNotifierProvider(
          create:
              (_) => GenerationProvider(
                enqueueUseCase: enqueueUseCase,
                processUseCase: processUseCase,
                queueRepository: queueRepository,
              ),
        ),
        ChangeNotifierProvider<GenerationQueueNotifier>(
          create: (_) => GenerationQueueNotifier(),
        ),
        ChangeNotifierProvider(
          create: (_) => QueueStatusProvider(getQueueUseCase: getQueueUseCase),
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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Provider.of<ThemeNotifier>(context).themeMode,
      home: const NavBar(),
    );
  }
}
