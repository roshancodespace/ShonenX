// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_offline_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserOfflineAdapter extends TypeAdapter<UserOffline> {
  @override
  final int typeId = 0;

  @override
  UserOffline read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserOffline(
      name: fields[0] as String,
      avatar: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, UserOffline obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.avatar);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserOfflineAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
