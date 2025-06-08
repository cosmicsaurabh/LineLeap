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
      filePath: fields[0] as String,
      prompt: fields[1] as String,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GeneratedImageModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.filePath)
      ..writeByte(1)
      ..write(obj.prompt)
      ..writeByte(2)
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
