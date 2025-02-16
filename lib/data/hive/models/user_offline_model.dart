import 'package:hive/hive.dart';

part 'user_offline_model.g.dart';  // This will generate the adapter code for the model

@HiveType(typeId: 0)  // Use a unique typeId for the object type
class UserOffline extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String avatar;

  UserOffline({required this.name, required this.avatar});
}
