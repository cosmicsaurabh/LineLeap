// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;

// class GoogleVertexAIApi {
//   // IMPORTANT: Replace with your actual API key and project details
//   final String _apiKey =
//       "YOUR_VERTEX_AI_API_KEY"; // Or handle auth via gcloud/service account
//   final String _projectId = "YOUR_GOOGLE_CLOUD_PROJECT_ID";
//   final String _region = "us-central1"; // e.g., us-central1
//   final String _modelId =
//       "gemini-pro-vision"; // Example: or another multimodal model

//   // Construct the base URL for Vertex AI predictions
//   // e.g., https://us-central1-aiplatform.googleapis.com/v1/projects/your-project-id/locations/us-central1/publishers/google/models/gemini-pro-vision:streamGenerateContent
//   // For non-streaming, it might be :predict
//   // This will vary based on the specific model and method (predict, streamGenerateContent, etc.)
//   String get _apiBaseUrl => "https://$_region-aiplatform.googleapis.com/v1";

//   Future<String?> submitMultimodalJob({
//     required String base64Image,
//     required String textPrompt,
//   }) async {
//     // Ensure base64Image is raw base64, without data URI prefix
//     String rawBase64Image = base64Image.replaceFirst(
//       RegExp(r'data:image\/\w+;base64,'),
//       '',
//     );

//     // The endpoint can vary. For Gemini, it might be :streamGenerateContent or :predict
//     // This example assumes a :predict endpoint structure.
//     final uri = Uri.parse(
//       "$_apiBaseUrl/projects/$_projectId/locations/$_region/publishers/google/models/$_modelId:predict",
//     );

//     // The payload structure is highly specific to the Vertex AI model.
//     // This is a simplified example for a model like Gemini Vision.
//     // Refer to the official Google Vertex AI documentation for the correct payload.
//     final payload = {
//       "instances": [
//         {
//           "contents": [
//             {
//               "role": "user",
//               "parts": [
//                 {"text": textPrompt},
//                 {
//                   "inline_data": {
//                     "mime_type": "image/png", // Or image/jpeg, etc.
//                     "data": rawBase64Image,
//                   },
//                 },
//               ],
//             },
//           ],
//         },
//       ],
//       // Parameters can be added here, e.g., "parameters": {"maxOutputTokens": 256}
//       // "parameters": {
//       //   "temperature": 0.7,
//       //   "maxOutputTokens": 1024,
//       // }
//     };

//     debugPrint("VERTEX AI Request URL: $uri");
//     debugPrint("VERTEX AI Request Payload: ${jsonEncode(payload)}");

//     try {
//       final response = await http.post(
//         uri,
//         headers: {
//           'Authorization': 'Bearer $_apiKey', // For API Key auth
//           // If using service account, you might use `gcloud auth print-access-token`
//           // and pass the token, or use a library that handles service account auth.
//           'Content-Type': 'application/json',
//         },
//         body: jsonEncode(payload),
//       );

//       debugPrint("VERTEX AI Submit Response code: ${response.statusCode}");
//       debugPrint("VERTEX AI Submit Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         // For synchronous predictions, the result might be directly in the response.
//         // For long-running operations, this would return an operation ID.
//         // This example assumes a synchronous response for simplicity.
//         final responseBody = jsonDecode(response.body);
//         // Parsing the response will depend heavily on the model's output structure
//         // For Gemini, it might be in responseBody["predictions"][0]["candidates"][0]["content"]["parts"][0]["text"]
//         // This is a placeholder:
//         if (responseBody["predictions"] != null &&
//             responseBody["predictions"].isNotEmpty &&
//             responseBody["predictions"][0]["candidates"] != null &&
//             responseBody["predictions"][0]["candidates"].isNotEmpty &&
//             responseBody["predictions"][0]["candidates"][0]["content"] !=
//                 null &&
//             responseBody["predictions"][0]["candidates"][0]["content"]["parts"] !=
//                 null &&
//             responseBody["predictions"][0]["candidates"][0]["content"]["parts"]
//                 .isNotEmpty &&
//             responseBody["predictions"][0]["candidates"][0]["content"]["parts"][0]["text"] !=
//                 null) {
//           return responseBody["predictions"][0]["candidates"][0]["content"]["parts"][0]["text"];
//         } else if (responseBody["predictions"] != null &&
//             responseBody["predictions"].isNotEmpty &&
//             responseBody["predictions"][0]["safetyAttributes"] != null &&
//             responseBody["predictions"][0]["safetyAttributes"]["blocked"] ==
//                 true) {
//           debugPrint(
//             "VERTEX AI: Content blocked by safety attributes. ${responseBody["predictions"][0]["safetyAttributes"]}",
//           );
//           return "Error: Content blocked due to safety reasons.";
//         }
//         // If it's an operation ID for polling:
//         // return responseBody["name"]; // e.g., projects/.../operations/...
//         debugPrint(
//           "VERTEX AI: Unexpected response structure. ${response.body}",
//         );
//         return null;
//       } else {
//         debugPrint("VERTEX AI Submission failed: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("Error calling VERTEX AI submission API: $e");
//       return null;
//     }
//   }

//   // Polling might not be needed if the :predict endpoint is synchronous.
//   // If using an endpoint that starts a long-running operation,
//   // you would implement polling similar to Replicate or AI Horde,
//   // but targeting the Vertex AI operations endpoint.
//   // Example: GET https://<region>-aiplatform.googleapis.com/v1/<operation-name>
//   //
//   // Future<String?> pollForMultimodalResult(String operationName) async {
//   //   final Uri getUrl = Uri.parse("$_apiBaseUrl/$operationName"); // operationName is the full path
//   //
//   //   for (int i = 0; i < 30; i++) { // Poll for a certain duration
//   //     await Future.delayed(const Duration(seconds: 10));
//   //
//   //     try {
//   //       final response = await http.get(
//   //         getUrl,
//   //         headers: {
//   //           'Authorization': 'Bearer $_apiKey',
//   //           'Content-Type': 'application/json',
//   //         },
//   //       );
//   //
//   //       debugPrint("VERTEX AI Poll Response code: ${response.statusCode}");
//   //       // debugPrint("VERTEX AI Poll Response body: ${response.body}");
//   //
//   //       if (response.statusCode == 200) {
//   //         final data = jsonDecode(response.body);
//   //         if (data["done"] == true) {
//   //           if (data.containsKey("response")) {
//   //             // Extract the actual result from data["response"]
//   //             // This structure depends on the original method that created the operation
//   //             // For example, it might be data["response"]["predictions"][0]...
//   //             // This is a placeholder:
//   //             final prediction = data["response"]["predictions"][0];
//   //             if (prediction["candidates"] != null && prediction["candidates"].isNotEmpty) {
//   //                return prediction["candidates"][0]["content"]["parts"][0]["text"];
//   //             }
//   //             return jsonEncode(data["response"]); // Placeholder
//   //           } else if (data.containsKey("error")) {
//   //             debugPrint("VERTEX AI Operation failed: ${data['error']}");
//   //             return null;
//   //           }
//   //         }
//   //         // If not done, continue polling
//   //         debugPrint("VERTEX AI Job status: processing. Polling again...");
//   //       } else {
//   //         debugPrint("VERTEX AI Poll failed: ${response.body}");
//   //         return null; // Stop polling on error
//   //       }
//   //     } catch (e) {
//   //       debugPrint("Error polling VERTEX AI API: $e");
//   //       return null; // Stop polling on error
//   //     }
//   //   }
//   //
//   //   debugPrint("VERTEX AI: Timed out waiting for result for operation $operationName.");
//   //   return null;
//   // }
// }
