import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:lineleap/core/service/image_storage_service.dart';
import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import 'package:lineleap/data/models/scribble_transformation_hive_model.dart';
import 'package:lineleap/data/remote/ai_horde_api.dart';
import 'package:lineleap/data/repositories/history_repository_impl.dart';
import 'package:lineleap/data/repositories/generation_queue_repo_impl.dart';
import 'package:lineleap/data/repositories/image_save_load_repository_impl.dart';
import 'package:lineleap/data/repositories/theme_mode_repository.dart';
import 'package:lineleap/data/services/horde_generation_service_impl.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';
import 'package:lineleap/domain/repositories/generation_queue_repository.dart';
import 'package:lineleap/domain/repositories/image_save_load_repository.dart';
import 'package:lineleap/domain/services/generation_service.dart';
import 'package:lineleap/domain/usecases/gallery_delete_scribbleTransformation.dart';
import 'package:lineleap/domain/usecases/enqueue_generation_request_usecase.dart';
import 'package:lineleap/domain/usecases/generate_transformationFromScribble.dart';
import 'package:lineleap/domain/usecases/gallery_get_scribbleTransformation.dart';
import 'package:lineleap/domain/usecases/get_generation_queue_usecase.dart';
import 'package:lineleap/domain/usecases/process_generation_queue_usecase.dart';
import 'package:lineleap/domain/usecases/save_scribbleTransformation_to_history.dart';
import 'package:lineleap/domain/usecases/save_imageBytes_return_path.dart';
import 'package:lineleap/domain/usecases/set_theme_mode_usecase.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/providers/theme_notifier.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  final box = sl.registerSingleton<Box<ScribbleTransformationHive>>(
    await Hive.openBox<ScribbleTransformationHive>('gallery_history'),
  );
  sl.registerSingleton<AIHordeAPI>(AIHordeAPI());
  sl.registerSingleton<GenerationQueueNotifier>(GenerationQueueNotifier());

  // Services
  sl.registerLazySingleton<ImageStorageService>(() => ImageStorageService());
  sl.registerLazySingleton<GenerationService>(
    () =>
        HordeGenerationServiceImpl(sl<AIHordeAPI>(), sl<ImageStorageService>()),
  );

  // Repositories
  sl.registerSingleton<ThemeModeRepository>(ThemeModeRepositoryImpl());
  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(
      sl<Box<ScribbleTransformationHive>>(),
      sl<ImageStorageService>(),
    ),
  );
  sl.registerLazySingleton<GenerationQueueRepository>(
    () => GenerationQueueRepositoryImpl(sl<GenerationQueueNotifier>()),
  );
  sl.registerLazySingleton<ImageSaveLoadRepository>(
    () => ImageSaveLoadRepositoryImpl(sl<ImageStorageService>()),
  );

  // Use cases
  sl.registerLazySingleton(() => SetThemeModeUseCase(sl()));
  sl.registerLazySingleton(() => GalleryGetScribbleTransformation(sl()));
  sl.registerLazySingleton(() => GalleryDeleteScribbleTransformation(sl()));
  sl.registerLazySingleton(() => SaveImagebytesReturnPath(sl()));
  sl.registerLazySingleton(() => SaveScribbletransformationToHistory(sl()));
  sl.registerLazySingleton(() => EnqueueGenerationRequestUseCase(sl()));
  sl.registerLazySingleton(() => GetGenerationQueueUseCase(sl()));
  sl.registerLazySingleton(
    () => ProcessGenerationQueueUseCase(
      queueRepository: sl(),
      generationService: sl(),
    ),
  );
  sl.registerLazySingleton(() => GenerateTransformationfromscribble(sl()));

  // Notifiers/Providers
  sl.registerFactory(() => ThemeNotifier(sl()));
  sl.registerFactory(() => EnhancedScribbleNotifier());
  sl.registerFactory(
    () => GalleryNotifier(
      getGalleryImagesUseCase: sl(),
      deleteGalleryImageUseCase: sl(),
      saveImageUseCase: sl(),
      saveImageToGalleryUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => GenerationProvider(
      enqueueUseCase: sl(),
      processUseCase: sl(),
      queueRepository: sl(),
    ),
  );
  sl.registerFactory(() => QueueStatusProvider(getQueueUseCase: sl()));
}
