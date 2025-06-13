enum GenerationStatus { queued, submitting, polling, completed, failed }

class GenerationRequest {
  final String localId; // UUID
  final String prompt;
  final String scribblePath;
  final String? generationId; // API returned ID
  final String? generatedPath;
  final GenerationStatus status;
  final String? error;
  final DateTime? completedAt;

  GenerationRequest({
    required this.localId,
    required this.prompt,
    required this.scribblePath,
    this.generationId,
    this.generatedPath,
    this.status = GenerationStatus.queued,
    this.error,
    this.completedAt,
  });

  GenerationRequest copyWith({
    String? localId,
    String? prompt,
    String? scribblePath,
    String? generationId,
    String? generatedPath,
    GenerationStatus? status,
    String? error,
    DateTime? completedAt,
  }) {
    return GenerationRequest(
      localId: localId ?? this.localId,
      prompt: prompt ?? this.prompt,
      scribblePath: scribblePath ?? this.scribblePath,
      generationId: generationId ?? this.generationId,
      generatedPath: generatedPath ?? this.generatedPath,
      status: status ?? this.status,
      error: error ?? this.error,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
