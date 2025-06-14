import 'package:flutter/foundation.dart';
import 'package:lineleap/domain/usecases/process_generation_queue_usecase.dart';
import '../../../domain/entities/generation_request.dart';
import '../../../domain/usecases/get_generation_queue_usecase.dart';

class QueueStatusProvider extends ChangeNotifier {
  final GetGenerationQueueUseCase _getQueueUseCase;
  final ProcessGenerationQueueUseCase _processQueueUseCase;
  List<GenerationRequest> _queueItems = [];
  bool _isLoading = false;

  QueueStatusProvider({
    required GetGenerationQueueUseCase getQueueUseCase,
    required ProcessGenerationQueueUseCase processQueueUseCase,
  }) : _getQueueUseCase = getQueueUseCase,
       _processQueueUseCase = processQueueUseCase {
    _initStream();
  }

  List<GenerationRequest> get queueItems => _queueItems;
  bool get isLoading => _isLoading;

  void _initStream() {
    _getQueueUseCase.observe().listen((items) {
      _queueItems = items;
      notifyListeners();
    });
  }

  Future<void> refreshQueue() async {
    _isLoading = true;
    notifyListeners();

    try {
      _queueItems = await _getQueueUseCase();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFromQueue(GenerationRequest request) async {
    await _getQueueUseCase.removeFromQueue(request);
    // Optionally refresh the queue after removal
    await refreshQueue();
  }

  Future<void> retryGeneration(GenerationRequest request) async {
    try {
      await _processQueueUseCase.retryRequestById(request.localId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error retrying generation: $e');
    }
  }
}
