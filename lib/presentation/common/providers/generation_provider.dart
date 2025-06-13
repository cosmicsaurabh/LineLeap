import 'package:flutter/foundation.dart';
import 'package:lineleap/domain/usecases/save_imageBytes_return_path.dart';
import '../../../domain/entities/generation_request.dart';
import '../../../domain/usecases/enqueue_generation_request_usecase.dart';
import '../../../domain/usecases/process_generation_queue_usecase.dart';
import '../../../domain/repositories/generation_queue_repository.dart';

class GenerationProvider extends ChangeNotifier {
  final EnqueueGenerationRequestUseCase _enqueueUseCase;
  final ProcessGenerationQueueUseCase _processUseCase;
  final GenerationQueueRepository _queueRepository;
  final SaveImagebytesReturnPathUseCase _saveImageUseCase;

  bool _isGenerating = false;
  String? _currentGenerationId;
  String? _error;

  GenerationProvider({
    required EnqueueGenerationRequestUseCase enqueueUseCase,
    required ProcessGenerationQueueUseCase processUseCase,
    required GenerationQueueRepository queueRepository,
    required SaveImagebytesReturnPathUseCase saveImageUseCase,
  }) : _enqueueUseCase = enqueueUseCase,
       _processUseCase = processUseCase,
       _queueRepository = queueRepository,
       _saveImageUseCase = saveImageUseCase {
    // Start the queue processor
    _processUseCase.startProcessingQueue();
  }

  bool get isGenerating => _isGenerating;
  String? get currentGenerationId => _currentGenerationId;
  String? get error => _error;

  Future<GenerationRequest> generateImage({
    required String prompt,
    required String scribblePath,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      // Enqueue the generation request
      final request = await _enqueueUseCase(
        prompt: prompt,
        scribblePath: scribblePath,
      );

      _currentGenerationId = request.localId;
      notifyListeners();

      return request;
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<String> saveImageToDevice(Uint8List imageBytes) async {
    final savedImagePath = await _saveImageUseCase(imageBytes);
    return savedImagePath;
  }

  Future<GenerationRequest?> getRequest(String localId) async {
    return await _queueRepository.getRequestById(localId);
  }

  @override
  void dispose() {
    _processUseCase.dispose();
    super.dispose();
  }
}
