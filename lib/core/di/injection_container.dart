import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:lineleap/core/service/image_device_interaction_service.dart';
import 'package:lineleap/data/datasources/in_memory/generation_queue_notifier.dart';
import 'package:lineleap/data/datasources/local/generation_queue_local_datasource.dart';
import 'package:lineleap/data/models/scribble_transformation_hive_model.dart';
import 'package:lineleap/data/remote/ai_horde_api.dart';
import 'package:lineleap/data/repositories/history_repository_impl.dart';
import 'package:lineleap/data/repositories/generation_queue_repo_impl.dart';
import 'package:lineleap/data/repositories/image_save_load_delete_repository_impl.dart';
import 'package:lineleap/data/repositories/theme_mode_repository_impl.dart';
import 'package:lineleap/data/services/horde_generation_service_impl.dart';
import 'package:lineleap/domain/repositories/history_repository.dart';
import 'package:lineleap/domain/repositories/generation_queue_repository.dart';
import 'package:lineleap/domain/repositories/image_save_load_delete_repository.dart';
import 'package:lineleap/domain/repositories/theme_mode_repository.dart';
import 'package:lineleap/domain/services/horde_generation_service.dart';
import 'package:lineleap/domain/usecases/delete_scribble_transformation_from_history_usecase.dart';
import 'package:lineleap/domain/usecases/enqueue_generation_request_usecase.dart';
import 'package:lineleap/domain/usecases/get_theme_mode_usecase.dart';
import 'package:lineleap/domain/usecases/get_scribble_transformations_from_history_usecase.dart';
import 'package:lineleap/domain/usecases/get_generation_queue_usecase.dart';
import 'package:lineleap/domain/usecases/process_generation_queue_usecase.dart';
import 'package:lineleap/domain/usecases/save_scribble_transformation_to_history_usecase.dart';
import 'package:lineleap/domain/usecases/save_image_bytes_return_path_usecase.dart';
import 'package:lineleap/domain/usecases/set_theme_mode_usecase.dart';
import 'package:lineleap/domain/usecases/watch_generation_request_usecase.dart';
import 'package:lineleap/presentation/common/providers/gallery_notifier.dart';
import 'package:lineleap/presentation/common/providers/generation_provider.dart';
import 'package:lineleap/presentation/common/providers/queue_status_provider.dart';
import 'package:lineleap/presentation/common/providers/scribble_notifier.dart';
import 'package:lineleap/presentation/common/providers/theme_notifier.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  // External
  sl.registerSingleton<Box<ScribbleTransformationHive>>(
    await Hive.openBox<ScribbleTransformationHive>('gallery_history'),
  );
  sl.registerSingleton<AIHordeAPI>(AIHordeAPI());
  sl.registerSingleton<GenerationQueueNotifier>(GenerationQueueNotifier());
  sl.registerSingleton<GenerationQueueLocalDatasource>(
    GenerationQueueLocalDatasource(),
  );

  // Services
  sl.registerLazySingleton<ImageDeviceInteractionService>(
    () => ImageDeviceInteractionService(),
  );
  sl.registerLazySingleton<HordeGenerationService>(
    () => HordeGenerationServiceImpl(
      sl<AIHordeAPI>(),
      sl<ImageDeviceInteractionService>(),
    ),
  );

  // Repositories
  sl.registerSingleton<ThemeModeRepository>(ThemeModeRepositoryImpl());
  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(
      sl<Box<ScribbleTransformationHive>>(),
      sl<ImageDeviceInteractionService>(),
    ),
  );
  sl.registerLazySingleton<GenerationQueueRepository>(
    () => GenerationQueueRepositoryImpl(
      sl<GenerationQueueNotifier>(),
      sl<GenerationQueueLocalDatasource>(),
    ),
  );
  sl.registerLazySingleton<ImageSaveLoadDeleteRepository>(
    () =>
        ImageSaveLoadDeleteRepositoryImpl(sl<ImageDeviceInteractionService>()),
  );

  // Use cases
  sl.registerLazySingleton(
    () => SetThemeModeUseCase(themeModeRepository: sl()),
  );
  sl.registerLazySingleton(
    () => GetThemeModeUseCase(themeModeRepository: sl()),
  );
  sl.registerLazySingleton(
    () => GetScribbleTransformationsFromHistoryUseCase(historyRepository: sl()),
  );
  sl.registerLazySingleton(
    () =>
        DeleteScribbleTransformationFromHistoryUseCase(historyRepository: sl()),
  );
  sl.registerLazySingleton(
    () => SaveImagebytesReturnPathUseCase(imageSaveLoadDeleteRepository: sl()),
  );
  sl.registerLazySingleton(
    () => SaveScribbleTransformationToHistoryUseCase(historyRepository: sl()),
  );
  sl.registerLazySingleton(
    () => EnqueueGenerationRequestUseCase(generationQueueRepository: sl()),
  );
  sl.registerLazySingleton(
    () => GetGenerationQueueUseCase(generationQueueRepository: sl()),
  );
  sl.registerLazySingleton(
    () => ProcessGenerationQueueUseCase(
      generationQueueRepository: sl(),
      hordeGenerationService: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => WatchGenerationRequestUseCase(generationQueueRepository: sl()),
  );
  // Notifiers/Providers
  sl.registerFactory(
    () => ThemeNotifier(setThemeModeUseCase: sl(), getThemeModeUseCase: sl()),
  );
  sl.registerFactory(() => EnhancedScribbleNotifier());
  sl.registerFactory(
    () => GalleryNotifier(
      getGalleryImagesUseCase: sl(),
      deleteGalleryImageUseCase: sl(),
      saveImageToGalleryUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => GenerationProvider(
      enqueueUseCase: sl(),
      queueRepository: sl(),
      saveImageUseCase: sl(),
      watchRequestUseCase: sl(),
    ),
  );
  sl.registerFactory(
    () => QueueStatusProvider(getQueueUseCase: sl(), processQueueUseCase: sl()),
  );

  // Restore persisted queue and start event-driven processing
  final queueRepo =
      sl<GenerationQueueRepository>() as GenerationQueueRepositoryImpl;
  await queueRepo.restoreQueue();
  sl<ProcessGenerationQueueUseCase>().startListening();
}
