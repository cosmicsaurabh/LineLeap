import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:lineleap/core/service/image_device_interaction_service.dart';

import '../../domain/services/horde_generation_service.dart';
import '../remote/ai_horde_api.dart';

class HordeGenerationServiceImpl implements HordeGenerationService {
  final AIHordeAPI _hordeAPI;
  final ImageDeviceInteractionService _imageDeviceInteractionService;

  HordeGenerationServiceImpl(
    this._hordeAPI,
    this._imageDeviceInteractionService,
  );

  @override
  Future<String> generateFromPrompt({
    required String prompt,
    required String scribblePath,
  }) async {
    try {
      // 1. Read the scribble image and convert to base64
      final File file = File(scribblePath);
      final Uint8List bytes = await file.readAsBytes();
      final String base64Image = base64Encode(bytes);

      // 2. Submit the job to AI Horde
      final String? jobId = await _hordeAPI.submitSketchJob(
        base64Image,
        prompt,
      );

      if (jobId == null) {
        throw Exception("Failed to submit generation job");
      }

      log("Generation job submitted with ID: $jobId");

      // 3. Poll for results

      final String? generatedImageURL = await _hordeAPI.pollForResult(jobId);
      if (generatedImageURL == null) {
        throw Exception("Failed to get generation result");
      }
      log("Generation result received: $generatedImageURL");
      // 4. Download the generated image

      Uint8List? generatedImageBytes;
      final res = await http.get(Uri.parse(generatedImageURL));
      if (res.statusCode == 200) {
        generatedImageBytes = res.bodyBytes;
      }

      if (generatedImageBytes == null) {
        throw Exception("Failed to get generation result");
      }

      // 4. Save the result to a file
      final String outputPath = await _imageDeviceInteractionService
          .saveImageToDevice(generatedImageBytes, jobId);
      return outputPath;
    } catch (e) {
      log("Generation error: $e");
      throw Exception("Image generation failed: $e");
    }
  }
}
