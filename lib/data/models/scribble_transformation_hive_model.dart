import 'package:lineleap/domain/entities/scribble_transformation.dart';
import 'package:hive/hive.dart';

part 'scribble_transformation_hive_model.g.dart';

@HiveType(typeId: 0)
class ScribbleTransformationHive extends HiveObject {
  @HiveField(0)
  final String generatedImagePathHive;

  @HiveField(1)
  final String scribbleImagePathHive;

  @HiveField(2)
  final String promptHive;

  @HiveField(3)
  final String createdAtHive;

  ScribbleTransformationHive({
    required this.generatedImagePathHive,
    required this.scribbleImagePathHive,
    required this.promptHive,
    required this.createdAtHive,
  });

  factory ScribbleTransformationHive.fromEntity(
    ScribbleTransformation entity,
  ) => ScribbleTransformationHive(
    generatedImagePathHive: entity.generatedImagePath,
    scribbleImagePathHive: entity.scribbleImagePath,
    promptHive: entity.prompt,
    createdAtHive: entity.timestamp,
  );
  ScribbleTransformation toEntity() {
    return ScribbleTransformation(
      generatedImagePath: generatedImagePathHive,
      scribbleImagePath: scribbleImagePathHive,
      prompt: promptHive,
      timestamp: createdAtHive,
    );
  }
}
