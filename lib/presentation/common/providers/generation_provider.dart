import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lineleap/core/utils/image_utils.dart';
import 'package:lineleap/domain/usecases/save_image_bytes_return_path_usecase.dart';
import 'package:lineleap/domain/usecases/watch_generation_request_usecase.dart';
import '../../../domain/entities/generation_request.dart';
import '../../../domain/usecases/enqueue_generation_request_usecase.dart';
import '../../../domain/repositories/generation_queue_repository.dart';

class GenerationProvider extends ChangeNotifier {
  final EnqueueGenerationRequestUseCase _enqueueUseCase;
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
    required GenerationQueueRepository queueRepository,
    required SaveImagebytesReturnPathUseCase saveImageUseCase,
    required WatchGenerationRequestUseCase watchRequestUseCase,
  }) : _enqueueUseCase = enqueueUseCase,
       _queueRepository = queueRepository,
       _saveImageUseCase = saveImageUseCase,
       _watchRequestUseCase = watchRequestUseCase;

  String? get currentGenerationId => _currentGenerationId;
  String? get error => _error;

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }

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
      _error ??= 'Couldn’t start generation. Please try again.';
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
      case GenerationStatus.cancelled:
        _error = request.error ?? 'Generation cancelled';
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

    try {
      final scribbleBytes = await generateImageFromCanvas(canvasKey: canvasKey);
      if (scribbleBytes == null) {
        _error =
            'Couldn’t capture the drawing. Keep the canvas open and try again.';
        return null;
      }

      String? scribblePath;
      try {
        scribblePath = await saveGeneratedImageFromCanvas(
          scribbleBytes: scribbleBytes,
        );
      } catch (_) {
        _error =
            'Couldn’t save the drawing on this device. '
            'Check available storage and try again.';
        return null;
      }
      if (scribblePath == null || scribblePath.isEmpty) {
        _error =
            'Couldn’t save the drawing on this device. '
            'Check available storage and try again.';
        return null;
      }

      try {
        final request = await enqueueGenerationRequest(
          scribblePath: scribblePath,
          prompt: prompt,
        );
        if (request == null) {
          _error =
              'Couldn’t add the request to the generation queue. Try again.';
        }
        return request;
      } catch (_) {
        _error = 'Couldn’t add the request to the generation queue. Try again.';
        return null;
      }
    } catch (_) {
      _error = 'Couldn’t start generation. Please try again.';
      return null;
    } finally {
      _isCapturing = false;
      notifyListeners();
    }
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
    // 3. Enqueue the generation request
    return await _enqueueUseCase(prompt: prompt, scribblePath: scribblePath);
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
    _watchSubscription?.cancel();
    super.dispose();
  }
}
