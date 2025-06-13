abstract class HordeGenerationService {
  /// Generates content based on a prompt and optional scribble image
  Future<String> generateFromPrompt({
    required String prompt,
    required String scribblePath,
  });
}
