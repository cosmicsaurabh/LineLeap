import 'package:hive/hive.dart';

//for the time being puttin it on hold and use string for datetime as well
class DateTimeAdapter extends TypeAdapter<DateTime> {
  @override
  final typeId = 16;

  @override
  DateTime read(BinaryReader reader) {
    final micros = reader.readInt();
    return DateTime.fromMicrosecondsSinceEpoch(micros);
  }

  @override
  void write(BinaryWriter writer, DateTime obj) {
    writer.writeInt(obj.microsecondsSinceEpoch);
  }
}
