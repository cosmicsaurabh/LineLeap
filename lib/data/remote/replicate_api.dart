// File: lib/data/remote/replicate_api.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ReplicateAPI {
  final String _apiKey = "YOUR_REPLICATE_API_KEY";
  final String _url = "https://api.replicate.com/v1/predictions";

  Future<String?> generateImageFromSketch(
    Uint8List sketchBytes,
    String prompt,
  ) async {
    final base64Image = base64Encode(sketchBytes);
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Token $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "version": "MODEL_VERSION_ID",
        "input": {
          "image": "data:image/png;base64,$base64Image",
          "prompt": prompt,
        },
      }),
    );

    if (response.statusCode == 201) {
      final output = jsonDecode(response.body);
      return output["urls"]?["get"];
    } else {
      print("Replicate error: ${response.body}");
      return null;
    }
  }

  Future<Uint8List?> fetchResultImage(String url) async {
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) return res.bodyBytes;
    return null;
  }
}
