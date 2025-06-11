// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_image_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GeneratedImageModelAdapter extends TypeAdapter<GeneratedImageModel> {
  @override
  final int typeId = 0;

  @override
  GeneratedImageModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GeneratedImageModel(
      generatedImagefilePath: fields[0] as String,
      scribbleFilePath: fields[1] as String,
      prompt: fields[2] as String,
      timestamp: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, GeneratedImageModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.generatedImagefilePath)
      ..writeByte(1)
      ..write(obj.scribbleFilePath)
      ..writeByte(2)
      ..write(obj.prompt)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratedImageModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
