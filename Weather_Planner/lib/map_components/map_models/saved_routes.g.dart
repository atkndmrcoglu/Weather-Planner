part of 'saved_routes.dart';

class SavedRouteAdapter extends TypeAdapter<SavedRoute> {
  @override
  final int typeId = 1;

  @override
  SavedRoute read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedRoute(
      id: fields[0] as String,
      title: fields[1] as String,
      points: (fields[2] as List)
          .map((dynamic e) => (e as List).cast<double>())
          .toList(),
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SavedRoute obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedRouteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
