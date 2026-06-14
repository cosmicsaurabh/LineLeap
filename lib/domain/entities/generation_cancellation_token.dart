class GenerationCancellationToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }

  void throwIfCancelled() {
    if (_isCancelled) {
      throw const GenerationCancelledException();
    }
  }
}

class GenerationCancelledException implements Exception {
  final String message;

  const GenerationCancelledException([
    this.message = 'Generation was cancelled',
  ]);

  @override
  String toString() => message;
}
