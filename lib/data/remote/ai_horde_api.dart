import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AIHordeAPI {
  final String _apiKey = "0000000000"; //it's anonymous
  Future<String?> submitSketchJob(String base64Image, String prompt) async {
    // Remove the data URI prefix if present //learned hard way
    String rawBase64 = base64Image.replaceFirst(
      RegExp(r'data:image\/\w+;base64,'),
      '',
    );

    final uri = Uri.parse("https://stablehorde.net/api/v2/generate/async");

    final payload = {
      "prompt": prompt,
      "params": {
        "sampler_name": "k_euler_a", // Faster sampler (free tier friendly)
        "cfg_scale": 7.5,
        "denoising_strength": 0.75,
        "height": 512,
        "width": 512,
        "steps": 20, // Reduced from 30 (free tier limit)
        "n": 1,
      },
      "nsfw": false,
      "trusted_workers": false,
      "source_image": rawBase64,
      "source_processing": "img2img",
    };

    final response = await http.post(
      uri,
      headers: {
        'apikey': _apiKey,
        'Content-Type': 'application/json',
        'Client-Agent': 'flutter_scribble',
      },
      body: jsonEncode(payload),
    );
    debugPrint("📥 Response code: ${response.statusCode}");

    if (response.statusCode == 202) {
      final id = jsonDecode(response.body)["id"];
      debugPrint("Job submitted. ID: $id");
      return id;
    } else {
      debugPrint("Submission failed: ${response.body}");
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

    debugPrint("AI Horde: Timed out waiting for result.");
    return null;
  }
}
