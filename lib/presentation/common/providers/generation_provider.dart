import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/core/utils/image_utils.dart';
import 'package:lineleap/domain/usecases/save_imageBytes_return_path_usecase.dart';
import 'package:lineleap/domain/usecases/watch_generation_request_usecase.dart';
import '../../../domain/entities/generation_request.dart';
import '../../../domain/usecases/enqueue_generation_request_usecase.dart';
import '../../../domain/usecases/process_generation_queue_usecase.dart';
import '../../../domain/repositories/generation_queue_repository.dart';

class GenerationProvider extends ChangeNotifier {
  final EnqueueGenerationRequestUseCase _enqueueUseCase;
  final ProcessGenerationQueueUseCase _processUseCase;
  final GenerationQueueRepository _queueRepository;
  final SaveImagebytesReturnPathUseCase _saveImageUseCase;
  final WatchGenerationRequestUseCase _watchRequestUseCase;

  bool get isCapturing => _isCapturing;
  bool _isCapturing = false;
  bool get isWatching => _isWatching;
  bool _isWatching = false;

  String? _currentGenerationId;
  String? _error;
  StreamSubscription<GenerationRequest?>? _watchSubscription;

  GenerationProvider({
    required EnqueueGenerationRequestUseCase enqueueUseCase,
    required ProcessGenerationQueueUseCase processUseCase,
    required GenerationQueueRepository queueRepository,
    required SaveImagebytesReturnPathUseCase saveImageUseCase,
    required WatchGenerationRequestUseCase watchRequestUseCase,
  }) : _enqueueUseCase = enqueueUseCase,
       _processUseCase = processUseCase,
       _queueRepository = queueRepository,
       _saveImageUseCase = saveImageUseCase,
       _watchRequestUseCase = watchRequestUseCase {
    // Start the queue processor
    _processUseCase.startProcessingQueue();
  }

  String? get currentGenerationId => _currentGenerationId;
  String? get error => _error;

  Future<void> generateAndWatchRequest({
    required String prompt,
    required GlobalKey canvasKey,
  }) async {
    // Step 1: Generate and enqueue request
    final request = await sequenceForGenerationRequest(
      prompt: prompt,
      canvasKey: canvasKey,
    );

    if (request == null) {
      _error = 'Failed to start generation';
      notifyListeners();
      return;
    }

    // Step 2: Start watching the request
    _startWatchingRequest(request.localId);
  }

  void _startWatchingRequest(String requestId) {
    _isWatching = true;
    _currentGenerationId = requestId;
    notifyListeners();

    _watchSubscription?.cancel();
    _watchSubscription = _watchRequestUseCase(requestId).listen(
      (request) => _handleRequestUpdate(request),
      onError: (error) => _handleWatchError(error),
      onDone: () => _stopWatching(),
    );
  }

  void _handleRequestUpdate(GenerationRequest? request) async {
    if (request == null) {
      _error = 'Request was removed from queue';
      _stopWatching();
      return;
    }

    switch (request.status) {
      case GenerationStatus.submitting:
        // Request is being submitted, no action needed
        break;
      case GenerationStatus.queued:
        // continue polling
        break;
      case GenerationStatus.polling:
        // Request is being processed, no action needed
        break;
      case GenerationStatus.completed:
        _stopWatching();
        break;
      case GenerationStatus.failed:
        _error = 'Generation failed: ${request.error ?? "Unknown error"}';
        _stopWatching();
        break;
    }
  }

  void _handleWatchError(dynamic error) {
    _error = 'Error watching generation: $error';
    _stopWatching();
  }

  void _stopWatching() {
    _isWatching = false;
    _currentGenerationId = null;
    _watchSubscription?.cancel();
    _watchSubscription = null;
    notifyListeners();
  }

  void cancelCurrentGeneration() {
    if (_isWatching && _currentGenerationId != null) {
      _stopWatching();
      // Optionally remove from queue
      // _queueRepository.removeRequest(_currentGenerationId!);
    }
  }

  Future<GenerationRequest?> sequenceForGenerationRequest({
    required String prompt,
    required GlobalKey canvasKey,
  }) async {
    _isCapturing = true;
    _error = null;
    notifyListeners();
    final scribbleBytes = await generateImageFromCanvas(canvasKey: canvasKey);
    if (scribbleBytes == null) {
      _error = 'Failed to generate image from canvas';
      _isCapturing = false;
      notifyListeners();
      return null;
    }
    final scribblePath = await saveGeneratedImageFromCanvas(
      scribbleBytes: scribbleBytes,
    );
    if (scribblePath == null) {
      _error = 'Failed to save generated image';
      notifyListeners();
      return null;
    }
    _isCapturing = false;
    notifyListeners();
    final request = await enqueueGenerationRequest(
      scribblePath: scribblePath,
      prompt: prompt,
    );
    if (request == null) {
      _error = 'Failed to enqueue generation request';
      notifyListeners();
      return null;
    }
    notifyListeners();
    return request;
  }

  Future<Uint8List?> generateImageFromCanvas({
    required GlobalKey canvasKey,
  }) async {
    try {
      // 1. Capture the canvas as PNG
      return await _capturePngFromCanvas(canvasKey);
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> _capturePngFromCanvas(GlobalKey canvasKey) async {
    try {
      return await ImageUtils.capturePng(canvasKey);
    } catch (e) {
      debugPrint('Error capturing PNG from canvas: $e');
      return null;
    }
  }

  Future<String?> saveGeneratedImageFromCanvas({
    required Uint8List scribbleBytes,
  }) async {
    // 2. Save the scribble to device
    return await saveImageToDevice(scribbleBytes);
  }

  Future<GenerationRequest?> enqueueGenerationRequest({
    required String scribblePath,
    required String prompt,
  }) async {
    try {
      // 3. Enqueue the generation request
      final request = await _enqueueUseCase(
        prompt: prompt,
        scribblePath: scribblePath,
      );
      return request;
    } catch (e) {
      return null;
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
