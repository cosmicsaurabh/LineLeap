import 'package:flutter/foundation.dart';
import '../../../domain/entities/generation_request.dart';
import '../../../domain/usecases/get_generation_queue_usecase.dart';

class QueueStatusProvider extends ChangeNotifier {
  final GetGenerationQueueUseCase _getQueueUseCase;
  List<GenerationRequest> _queueItems = [];
  bool _isLoading = false;

  QueueStatusProvider({required GetGenerationQueueUseCase getQueueUseCase})
    : _getQueueUseCase = getQueueUseCase {
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
}
