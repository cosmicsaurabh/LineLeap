import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:lineleap/core/service/image_device_interaction_service.dart';
import 'package:lineleap/domain/entities/generation_cancellation_token.dart';

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
    void Function(int)? onProgress,
    GenerationCancellationToken? cancellationToken,
  }) async {
    try {
      cancellationToken?.throwIfCancelled();

      // 1. Read the scribble image and convert to base64
      final File file = File(scribblePath);
      final Uint8List bytes = await file.readAsBytes();
      final String base64Image = base64Encode(bytes);
      cancellationToken?.throwIfCancelled();

      // 2. Submit the job to AI Horde
      final String jobId = await _hordeAPI.submitSketchJob(
        base64Image,
        prompt,
        cancellationToken: cancellationToken,
      );

      log("Generation job submitted with ID: $jobId");

      // 3. Poll for results
      if (onProgress != null) {
        onProgress(1);
      }

      final String generatedImageURL = await _hordeAPI.pollForResult(
        jobId,
        onProgress: (progress) => onProgress?.call(progress.percentEstimate),
        cancellationToken: cancellationToken,
      );
      log("Generation result received: $generatedImageURL");
      // 4. Download the generated image

      final generatedImageBytes = await _hordeAPI.downloadImage(
        generatedImageURL,
        cancellationToken: cancellationToken,
      );
      cancellationToken?.throwIfCancelled();

      // 4. Save the result to a file
      final String outputPath = await _imageDeviceInteractionService
          .saveImageToDevice(generatedImageBytes, jobId);
      return outputPath;
    } on GenerationCancelledException {
      log("Generation cancelled");
      rethrow;
    } on HordeApiException {
      rethrow;
    } catch (e) {
      log("Generation error: $e");
      throw Exception("Image generation failed: $e");
    }
  }
}
