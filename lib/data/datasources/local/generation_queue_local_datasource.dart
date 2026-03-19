import 'package:hive/hive.dart';
import '../../../domain/entities/generation_request.dart';

class GenerationQueueLocalDatasource {
  static const String _boxName = 'generation_queue';
  Box<Map>? _box;

  Future<Box<Map>> get box async {
    _box ??= await Hive.openBox<Map>(_boxName);
    return _box!;
  }

  Future<void> saveRequest(GenerationRequest request) async {
    final b = await box;
    await b.put(request.localId, _toMap(request));
  }

  Future<void> removeRequest(String localId) async {
    final b = await box;
    await b.delete(localId);
  }

  Future<List<GenerationRequest>> loadAll() async {
    final b = await box;
    return b.values.map((map) => _fromMap(Map<String, dynamic>.from(map))).toList();
  }

  Future<void> clear() async {
    final b = await box;
    await b.clear();
  }

  Map<String, dynamic> _toMap(GenerationRequest r) => {
        'localId': r.localId,
        'prompt': r.prompt,
        'scribblePath': r.scribblePath,
        'generationId': r.generationId,
        'generatedPath': r.generatedPath,
        'status': r.status.index,
        'error': r.error,
        'createdAt': r.createdAt?.toIso8601String(),
        'completedAt': r.completedAt?.toIso8601String(),
      };

  GenerationRequest _fromMap(Map<String, dynamic> map) => GenerationRequest(
        localId: map['localId'] as String,
        prompt: map['prompt'] as String,
        scribblePath: map['scribblePath'] as String,
        generationId: map['generationId'] as String?,
        generatedPath: map['generatedPath'] as String?,
        status: GenerationStatus.values[map['status'] as int],
        error: map['error'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.parse(map['createdAt'] as String)
            : null,
        completedAt: map['completedAt'] != null
            ? DateTime.parse(map['completedAt'] as String)
            : null,
      );
}
