import 'package:flutter/foundation.dart';
import '../../../domain/entities/generation_request.dart';

class GenerationQueueNotifier extends ChangeNotifier {
  final List<GenerationRequest> _queue = [];

  List<GenerationRequest> get queue => List.unmodifiable(_queue);

  Future<void> addRequest(GenerationRequest request) async {
    _queue.add(request);
    notifyListeners();
  }

  Future<void> updateRequest(GenerationRequest request) async {
    final index = _queue.indexWhere((r) => r.localId == request.localId);
    if (index >= 0) {
      _queue[index] = request;
      notifyListeners();
    }
  }

  Future<void> removeRequest(String localId) async {
    _queue.removeWhere((r) => r.localId == localId);
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    notifyListeners();
  }
}
