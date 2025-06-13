// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scribble_transformation_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScribbleTransformationHiveAdapter
    extends TypeAdapter<ScribbleTransformationHive> {
  @override
  final int typeId = 0;

  @override
  ScribbleTransformationHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScribbleTransformationHive(
      generatedImagePathHive: fields[0] as String,
      scribbleImagePathHive: fields[1] as String,
      promptHive: fields[2] as String,
      createdAtHive: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ScribbleTransformationHive obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.generatedImagePathHive)
      ..writeByte(1)
      ..write(obj.scribbleImagePathHive)
      ..writeByte(2)
      ..write(obj.promptHive)
      ..writeByte(3)
      ..write(obj.createdAtHive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScribbleTransformationHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
