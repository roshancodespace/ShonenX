import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

@HiveType(typeId: 6)
class UserModel {
  @HiveField(1)
  String name; // Changed from String? to String to avoid null type error
  @HiveField(2)
  bool onboardingStatus;

  UserModel({
    this.name = 'Guest', // Default value to ensure it's never null
    this.onboardingStatus = false,
  });
}
