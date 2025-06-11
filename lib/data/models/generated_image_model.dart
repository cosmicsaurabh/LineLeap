import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:hive/hive.dart';

part 'generated_image_model.g.dart';

@HiveType(typeId: 0)
class GeneratedImageModel extends HiveObject {
  @HiveField(0)
  final String generatedImageFilePath;

  @HiveField(1)
  final String scribbleImageFilePath;

  @HiveField(2)
  final String prompt;

  @HiveField(3)
  final String timestamp;

  GeneratedImageModel({
    required this.generatedImageFilePath,
    required this.scribbleImageFilePath,
    required this.prompt,
    required this.timestamp,
  });

  factory GeneratedImageModel.fromEntity(GeneratedImage entity) =>
      GeneratedImageModel(
        generatedImageFilePath: entity.generatedImageFilePath,
        scribbleImageFilePath: entity.scribbleImageFilePath,
        prompt: entity.prompt,
        timestamp: entity.timestamp,
      );

  GeneratedImage toEntity() => GeneratedImage(
    generatedImageFilePath: generatedImageFilePath,
    scribbleImageFilePath: scribbleImageFilePath,
    prompt: prompt,
    timestamp: timestamp,
  );
}
