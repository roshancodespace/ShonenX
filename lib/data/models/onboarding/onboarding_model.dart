import 'package:hive/hive.dart';

part 'onboarding_model.g.dart';

@HiveType(typeId: 5)
class OnboardingModel extends HiveObject {
  @HiveField(0)
  bool isOnboardingCompleted;

  OnboardingModel({this.isOnboardingCompleted = false});
}
