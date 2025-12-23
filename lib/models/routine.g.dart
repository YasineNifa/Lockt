// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoutineAdapter extends TypeAdapter<Routine> {
  @override
  final int typeId = 1;

  @override
  Routine read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Routine(
      id: fields[0] as String,
      name: fields[1] as String,
      items: (fields[2] as List).cast<ChecklistItem>(),
      iconPoint: fields[3] as int,
      colorPoint: fields[4] as int,
      resetPolicy: fields[5] as ResetPolicy?,
      customResetDurationMinutes: fields[6] as int?,
      mediaAutoDeleteDurationHours: fields[7] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Routine obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.iconPoint)
      ..writeByte(4)
      ..write(obj.colorPoint)
      ..writeByte(5)
      ..write(obj.resetPolicy)
      ..writeByte(6)
      ..write(obj.customResetDurationMinutes)
      ..writeByte(7)
      ..write(obj.mediaAutoDeleteDurationHours);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ResetPolicyAdapter extends TypeAdapter<ResetPolicy> {
  @override
  final int typeId = 2;

  @override
  ResetPolicy read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ResetPolicy.daily4am;
      case 1:
        return ResetPolicy.customDuration;
      default:
        return ResetPolicy.daily4am;
    }
  }

  @override
  void write(BinaryWriter writer, ResetPolicy obj) {
    switch (obj) {
      case ResetPolicy.daily4am:
        writer.writeByte(0);
        break;
      case ResetPolicy.customDuration:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResetPolicyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
