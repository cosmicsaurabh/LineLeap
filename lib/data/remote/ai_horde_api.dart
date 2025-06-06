import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AIHordeAPI {
  final String _apiKey =
      "0000000000"; // Replace with real key for faster results

  Future<String?> submitSketchJob(Uint8List sketchBytes, String prompt) async {
    final base64Image = base64Encode(sketchBytes);
    final uri = Uri.parse("https://stablehorde.net/api/v2/generate/async");

    final response = await http.post(
      uri,
      headers: {'apikey': _apiKey, 'Content-Type': 'application/json'},
      body: jsonEncode({
        "prompt": prompt,
        "params": {
          "n": 1,
          "k": "k_euler",
          "steps": 20,
          "cfg": 7,
          "denoising_strength": 0.4,
        },
        "source_image": "data:image/png;base64,$base64Image",
      }),
    );

    if (response.statusCode == 202) {
      return jsonDecode(response.body)['id'];
    } else {
      print('AI Horde submission error: ${response.body}');
      return null;
    }
  }

  Future<String?> pollForResult(String jobId) async {
    final url = "https://stablehorde.net/api/v2/generate/status/$jobId";

    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 5));

      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final gens = data["generations"];
        if (gens != null && gens.isNotEmpty) {
          return gens[0]["img"]; // URL to the image
        }
      }
    }

    print("AI Horde: Timed out waiting for result.");
    return null;
  }

  Future<String?> generateImageFromSketch(
    Uint8List sketchBytes,
    String prompt,
  ) async {
    final jobId = await submitSketchJob(sketchBytes, prompt);
    if (jobId == null) return null;

    return await pollForResult(jobId);
  }
}
