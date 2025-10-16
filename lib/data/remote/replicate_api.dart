// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class ReplicateApi {
//   final String _apiToken = "";
//   final String _apiBaseUrl = "https://api.replicate.com/";

//   final String _scribbleModelVersion =
//       "jagilley/controlnet-scribble:435061a1b5a4c1e26740464bf786efdfa9cb3a3ac488595a2de23e143fdb0117";

//   Future<String?> submitScribbleJob(
//     String base64Scribble,
//     String prompt,
//   ) async {
//     String dataUriScribble = base64Scribble;
//     if (!base64Scribble.startsWith('data:image')) {
//       dataUriScribble = 'data:image/png;base64,$base64Scribble';
//     }

//     final uri = Uri.parse("$_apiBaseUrl/predictions");

//     final payload = {
//       "version": _scribbleModelVersion,
//       "input": {
//         "image": dataUriScribble,
//         "prompt": prompt,
//         // "num_samples": "1",
//         // "image_resolution": "512",
//         // "ddim_steps": 20,
//         // "scale": 7.5,
//         // "a_prompt": "best quality, extremely detailed", // Added prompt
//         // "n_prompt": "longbody, lowres, bad anatomy, bad hands, missing fingers, extra digit, fewer digits, cropped, worst quality, low quality" // Negative prompt
//       },
//     };

//     try {
//       final response = await http.post(
//         uri,
//         headers: {
//           'Authorization': 'Token $_apiToken',
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(payload),
//       );

//       debugPrint("REPLICATE Submit Response code: ${response.statusCode}");
//       debugPrint("REPLICATE Submit Response body: ${response.body}");

//       if (response.statusCode == 201) {
//         // 201 Created for new predictions
//         final responseBody = jsonDecode(response.body);
//         return responseBody["id"]; // This is the prediction ID
//       } else {
//         debugPrint("REPLICATE Submission failed: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("Error calling REPLICATE submission API: $e");
//       return null;
//     }
//   }

//   Future<String?> pollForResult(String predictionId) async {
//     final Uri getUrl = Uri.parse("$_apiBaseUrl/predictions/$predictionId");

//     for (int i = 0; i < 30; i++) {
//       // Poll for up to 2.5 minutes (30 * 5 seconds)
//       await Future.delayed(const Duration(seconds: 5));

//       try {
//         final response = await http.get(
//           getUrl,
//           headers: {
//             'Authorization': 'Token $_apiToken',
//             'Content-Type': 'application/json',
//           },
//         );

//         debugPrint("REPLICATE Poll Response code: ${response.statusCode}");
//         // debugPrint("REPLICATE Poll Response body: ${response.body}");

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           final status = data["status"];

//           if (status == "succeeded") {
//             if (data["output"] != null) {
//               if (data["output"] is List && data["output"].isNotEmpty) {
//                 return data["output"][0]; // URL to the generated image
//               } else if (data["output"] is String) {
//                 return data["output"]; // If output is a single string URL
//               }
//             }
//             debugPrint(
//               "REPLICATE: Output format not as expected or empty. ${data['output']}",
//             );
//             return null;
//           } else if (status == "failed" || status == "canceled") {
//             debugPrint(
//               "REPLICATE Job failed or canceled. Status: $status, Error: ${data['error']}",
//             );
//             return null;
//           }
//           // If "starting" or "processing", continue polling
//           debugPrint("REPLICATE Job status: $status. Polling again...");
//         } else {
//           debugPrint("REPLICATE Poll failed: ${response.body}");
//           // Optional: stop polling on certain persistent errors
//         }
//       } catch (e) {
//         debugPrint("Error polling REPLICATE API: $e");
//         // Optional: decide if this error should stop polling
//       }
//     }

//     debugPrint("REPLICATE: Timed out waiting for result for ID $predictionId.");
//     return null;
//   }
// }
