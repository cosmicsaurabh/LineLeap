import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:hive/hive.dart';

part 'generated_image_model.g.dart';

@HiveType(typeId: 0)
class GeneratedImageModel extends HiveObject {
  @HiveField(0)
  final String generatedImagefilePath;

  @HiveField(1)
  final String scribbleFilePath;

  @HiveField(2)
  final String prompt;

  @HiveField(3)
  final String timestamp;

  GeneratedImageModel({
    required this.generatedImagefilePath,
    required this.scribbleFilePath,
    required this.prompt,
    required this.timestamp,
  });

  factory GeneratedImageModel.fromEntity(GeneratedImage entity) =>
      GeneratedImageModel(
        generatedImagefilePath: entity.generatedImagefilePath,
        scribbleFilePath: entity.scribbleFilePath,
        prompt: entity.prompt,
        timestamp: entity.timestamp,
      );

  GeneratedImage toEntity() => GeneratedImage(
    generatedImagefilePath: generatedImagefilePath,
    scribbleFilePath: scribbleFilePath,
    prompt: prompt,
    timestamp: timestamp,
  );
}
