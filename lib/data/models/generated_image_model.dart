import 'package:lineleap/domain/entities/generated_image.dart';
import 'package:hive/hive.dart';

part 'generated_image_model.g.dart';

@HiveType(typeId: 0)
class GeneratedImageModel extends HiveObject {
  @HiveField(0)
  final String filePath;

  @HiveField(1)
  final String prompt;

  @HiveField(2)
  final DateTime timestamp;

  GeneratedImageModel({
    required this.filePath,
    required this.prompt,
    required this.timestamp,
  });

  factory GeneratedImageModel.fromEntity(GeneratedImage entity) =>
      GeneratedImageModel(
        filePath: entity.filePath,
        prompt: entity.prompt,
        timestamp: entity.timestamp,
      );

  GeneratedImage toEntity() =>
      GeneratedImage(filePath: filePath, prompt: prompt, timestamp: timestamp);
}
