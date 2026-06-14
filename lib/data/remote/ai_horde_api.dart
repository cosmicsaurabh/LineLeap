import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:lineleap/domain/entities/generation_cancellation_token.dart';

const _defaultHordeApiKey = String.fromEnvironment(
  'AI_HORDE_API_KEY',
  defaultValue: '0000000000',
);

enum HordeApiFailureKind {
  submissionRejected,
  invalidResponse,
  pollingTimedOut,
  generationFaulted,
  downloadFailed,
  network,
}

class HordeApiException implements Exception {
  final HordeApiFailureKind kind;
  final String message;
  final int? statusCode;
  final String? responseBody;
  final bool isRetryable;

  const HordeApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.responseBody,
    this.isRetryable = false,
  });

  @override
  String toString() {
    final status = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$status';
  }
}

class HordeGenerationParams {
  final String samplerName;
  final double cfgScale;
  final double denoisingStrength;
  final int height;
  final int width;
  final int steps;
  final int samples;

  const HordeGenerationParams({
    this.samplerName = 'k_euler_a',
    this.cfgScale = 7.5,
    this.denoisingStrength = 0.75,
    this.height = 512,
    this.width = 512,
    this.steps = 20,
    this.samples = 1,
  });

  Map<String, Object> toJson() {
    return {
      'sampler_name': samplerName,
      'cfg_scale': cfgScale,
      'denoising_strength': denoisingStrength,
      'height': height,
      'width': width,
      'steps': steps,
      'n': samples,
    };
  }
}

class HordePollingPolicy {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffFactor;

  const HordePollingPolicy({
    this.maxAttempts = 20,
    this.initialDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(seconds: 20),
    this.backoffFactor = 1.35,
  });

  Duration delayForAttempt(int attempt) {
    if (initialDelay == Duration.zero) {
      return Duration.zero;
    }

    final multiplier = math.pow(backoffFactor, attempt - 1).toDouble();
    final delayMs = (initialDelay.inMilliseconds * multiplier).round();
    return Duration(milliseconds: math.min(delayMs, maxDelay.inMilliseconds));
  }
}

class HordeGenerationProgress {
  final int attempt;
  final int maxAttempts;
  final int? queuePosition;
  final int? waitTimeSeconds;
  final bool done;
  final bool faulted;

  const HordeGenerationProgress({
    required this.attempt,
    required this.maxAttempts,
    this.queuePosition,
    this.waitTimeSeconds,
    this.done = false,
    this.faulted = false,
  });

  int get percentEstimate {
    if (done) {
      return 100;
    }
    if (maxAttempts <= 1) {
      return 50;
    }
    final rawPercent = (attempt / maxAttempts * 90).round();
    return rawPercent.clamp(1, 90).toInt();
  }
}

class AIHordeAPI {
  final http.Client _client;
  final String _apiKey;
  final Uri _baseUri;
  final HordeGenerationParams _generationParams;
  final HordePollingPolicy _pollingPolicy;
  final Duration _requestTimeout;

  AIHordeAPI({
    http.Client? client,
    String apiKey = _defaultHordeApiKey,
    Uri? baseUri,
    HordeGenerationParams generationParams = const HordeGenerationParams(),
    HordePollingPolicy pollingPolicy = const HordePollingPolicy(),
    Duration requestTimeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _apiKey = apiKey,
       _baseUri = baseUri ?? Uri.parse('https://stablehorde.net'),
       _generationParams = generationParams,
       _pollingPolicy = pollingPolicy,
       _requestTimeout = requestTimeout;

  Future<String> submitSketchJob(
    String base64Image,
    String prompt, {
    GenerationCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();

    final rawBase64 = base64Image.replaceFirst(
      RegExp(r'data:image\/\w+;base64,'),
      '',
    );

    final payload = {
      'prompt': prompt,
      'params': _generationParams.toJson(),
      'nsfw': false,
      'trusted_workers': false,
      'source_image': rawBase64,
      'source_processing': 'img2img',
    };

    final response = await _send(
      () => _client.post(
        _baseUri.resolve('/api/v2/generate/async'),
        headers: {
          'apikey': _apiKey,
          'Content-Type': 'application/json',
          'Client-Agent': 'lineleap',
        },
        body: jsonEncode(payload),
      ),
      cancellationToken,
    );

    if (response.statusCode != 202) {
      throw _responseException(
        kind: HordeApiFailureKind.submissionRejected,
        context: 'AI Horde rejected generation submission',
        response: response,
      );
    }

    final data = _decodeJsonMap(
      response.body,
      'AI Horde submission response was not valid JSON',
    );
    final id = data['id'];

    if (id is! String || id.isEmpty) {
      throw HordeApiException(
        kind: HordeApiFailureKind.invalidResponse,
        message: 'AI Horde submission response did not include a job id',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    return id;
  }

  Future<String> pollForResult(
    String jobId, {
    void Function(HordeGenerationProgress)? onProgress,
    GenerationCancellationToken? cancellationToken,
  }) async {
    HordeApiException? lastRetryableError;

    for (var attempt = 1; attempt <= _pollingPolicy.maxAttempts; attempt++) {
      await _delay(_pollingPolicy.delayForAttempt(attempt), cancellationToken);

      final response = await _send(
        () => _client.get(_baseUri.resolve('/api/v2/generate/status/$jobId')),
        cancellationToken,
      );

      if (response.statusCode != 200) {
        final exception = _responseException(
          kind: HordeApiFailureKind.network,
          context: 'AI Horde status polling failed',
          response: response,
        );
        if (exception.isRetryable && attempt < _pollingPolicy.maxAttempts) {
          lastRetryableError = exception;
          continue;
        }
        throw exception;
      }

      final data = _decodeJsonMap(
        response.body,
        'AI Horde status response was not valid JSON',
      );
      final progress = _progressFromStatus(data, attempt);
      onProgress?.call(progress);

      if (progress.faulted) {
        throw HordeApiException(
          kind: HordeApiFailureKind.generationFaulted,
          message: _extractErrorMessage(response.body) ?? 'AI Horde job failed',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }

      final generations = data['generations'];
      if (generations is List && generations.isNotEmpty) {
        final imageUrl = _imageUrlFromGeneration(generations.first);
        if (imageUrl != null) {
          return imageUrl;
        }
        throw HordeApiException(
          kind: HordeApiFailureKind.invalidResponse,
          message: 'AI Horde generation response did not include an image URL',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }

      if (progress.done) {
        throw HordeApiException(
          kind: HordeApiFailureKind.invalidResponse,
          message: 'AI Horde completed without returning an image',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
    }

    throw HordeApiException(
      kind: HordeApiFailureKind.pollingTimedOut,
      message:
          lastRetryableError?.message ??
          'AI Horde timed out waiting for a generated image',
      statusCode: lastRetryableError?.statusCode,
      responseBody: lastRetryableError?.responseBody,
      isRetryable: true,
    );
  }

  Future<Uint8List> downloadImage(
    String imageUrl, {
    GenerationCancellationToken? cancellationToken,
  }) async {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasScheme) {
      throw HordeApiException(
        kind: HordeApiFailureKind.invalidResponse,
        message: 'AI Horde returned an invalid image URL',
        responseBody: imageUrl,
      );
    }

    final response = await _send(() => _client.get(uri), cancellationToken);

    if (response.statusCode != 200) {
      throw _responseException(
        kind: HordeApiFailureKind.downloadFailed,
        context: 'Failed to download generated image',
        response: response,
      );
    }

    return response.bodyBytes;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() request,
    GenerationCancellationToken? cancellationToken,
  ) async {
    try {
      cancellationToken?.throwIfCancelled();
      final response = await request().timeout(_requestTimeout);
      cancellationToken?.throwIfCancelled();
      return response;
    } on GenerationCancelledException {
      rethrow;
    } on TimeoutException {
      throw const HordeApiException(
        kind: HordeApiFailureKind.network,
        message: 'AI Horde request timed out',
        isRetryable: true,
      );
    } on http.ClientException catch (error) {
      throw HordeApiException(
        kind: HordeApiFailureKind.network,
        message: 'AI Horde network request failed: ${error.message}',
        isRetryable: true,
      );
    } catch (error) {
      throw HordeApiException(
        kind: HordeApiFailureKind.network,
        message: 'AI Horde request failed: $error',
        isRetryable: true,
      );
    }
  }

  Future<void> _delay(
    Duration delay,
    GenerationCancellationToken? cancellationToken,
  ) async {
    var remainingMs = delay.inMilliseconds;
    while (remainingMs > 0) {
      cancellationToken?.throwIfCancelled();
      final stepMs = math.min(remainingMs, 250);
      await Future.delayed(Duration(milliseconds: stepMs));
      remainingMs -= stepMs;
    }
    cancellationToken?.throwIfCancelled();
  }

  HordeGenerationProgress _progressFromStatus(
    Map<String, dynamic> data,
    int attempt,
  ) {
    return HordeGenerationProgress(
      attempt: attempt,
      maxAttempts: _pollingPolicy.maxAttempts,
      queuePosition: _readInt(data['queue_position']),
      waitTimeSeconds: _readInt(data['wait_time']),
      done: data['done'] == true,
      faulted: data['faulted'] == true,
    );
  }

  int? _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  String? _imageUrlFromGeneration(Object? generation) {
    if (generation is Map) {
      final image = generation['img'];
      if (image is String && image.isNotEmpty) {
        return image;
      }
    }
    return null;
  }

  HordeApiException _responseException({
    required HordeApiFailureKind kind,
    required String context,
    required http.Response response,
  }) {
    return HordeApiException(
      kind: kind,
      message: _extractErrorMessage(response.body) ?? context,
      statusCode: response.statusCode,
      responseBody: response.body,
      isRetryable: response.statusCode == 429 || response.statusCode >= 500,
    );
  }

  Map<String, dynamic> _decodeJsonMap(String body, String errorMessage) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Handled below with a typed exception.
    }

    throw HordeApiException(
      kind: HordeApiFailureKind.invalidResponse,
      message: errorMessage,
      responseBody: body,
    );
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        final errors = decoded['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.join(', ');
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
