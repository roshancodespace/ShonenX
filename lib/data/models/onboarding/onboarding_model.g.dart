// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OnboardingModelAdapter extends TypeAdapter<OnboardingModel> {
  @override
  final int typeId = 5;

  @override
  OnboardingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OnboardingModel(
      isOnboardingCompleted: fields[0] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OnboardingModel obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.isOnboardingCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
