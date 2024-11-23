import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

@HiveType(typeId: 5)
class UserModel {
  @HiveField(1)
  String? name;
  // final String? username;
  // final String? email;
  // final String? password;
  // final int? age;
  @HiveField(2)
  bool onboardingStatus;


  UserModel({
    this.name,
    // this.username,
    // this.password
    // this.age,
    // this.email,
    this.onboardingStatus = false,
    
  });
}
