import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lineleap/data/remote/ai_horde_api.dart';

void main() {
  group('AIHordeAPI', () {
    test('submitSketchJob returns a job id with configurable params', () async {
      late http.Request capturedRequest;
      final api = AIHordeAPI(
        client: MockClient((request) async {
          capturedRequest = request;
          return http.Response(jsonEncode({'id': 'job-1'}), 202);
        }),
        generationParams: const HordeGenerationParams(
          height: 256,
          width: 256,
          steps: 12,
        ),
      );

      final jobId = await api.submitSketchJob(
        'data:image/png;base64,abc123',
        'a glass tower',
      );
      final payload = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      final params = payload['params'] as Map<String, dynamic>;

      expect(jobId, 'job-1');
      expect(capturedRequest.url.path, '/api/v2/generate/async');
      expect(payload['source_image'], 'abc123');
      expect(payload['source_processing'], 'img2img');
      expect(payload.containsKey('model'), isFalse);
      expect(payload.containsKey('models'), isFalse);
      expect(params['height'], 256);
      expect(params['width'], 256);
      expect(params['steps'], 12);
    });

    test('submitSketchJob throws typed retryable errors', () async {
      final api = AIHordeAPI(
        client: MockClient((request) async {
          return http.Response(jsonEncode({'message': 'provider busy'}), 503);
        }),
      );

      await expectLater(
        api.submitSketchJob('abc123', 'a glass tower'),
        throwsA(
          isA<HordeApiException>()
              .having(
                (error) => error.kind,
                'kind',
                HordeApiFailureKind.submissionRejected,
              )
              .having((error) => error.statusCode, 'statusCode', 503)
              .having((error) => error.isRetryable, 'isRetryable', isTrue),
        ),
      );
    });

    test(
      'pollForResult returns generated image URL and reports progress',
      () async {
        final progressEvents = <HordeGenerationProgress>[];
        final api = AIHordeAPI(
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({
                'done': true,
                'queue_position': 0,
                'generations': [
                  {'img': 'https://cdn.example/image.png'},
                ],
              }),
              200,
            );
          }),
          pollingPolicy: const HordePollingPolicy(
            maxAttempts: 1,
            initialDelay: Duration.zero,
          ),
        );

        final imageUrl = await api.pollForResult(
          'job-1',
          onProgress: progressEvents.add,
        );

        expect(imageUrl, 'https://cdn.example/image.png');
        expect(progressEvents, hasLength(1));
        expect(progressEvents.single.done, isTrue);
        expect(progressEvents.single.percentEstimate, 100);
      },
    );

    test(
      'pollForResult throws typed timeout after configured attempts',
      () async {
        final api = AIHordeAPI(
          client: MockClient((request) async {
            return http.Response(
              jsonEncode({'done': false, 'generations': []}),
              200,
            );
          }),
          pollingPolicy: const HordePollingPolicy(
            maxAttempts: 2,
            initialDelay: Duration.zero,
          ),
        );

        await expectLater(
          api.pollForResult('job-1'),
          throwsA(
            isA<HordeApiException>().having(
              (error) => error.kind,
              'kind',
              HordeApiFailureKind.pollingTimedOut,
            ),
          ),
        );
      },
    );
  });
}
