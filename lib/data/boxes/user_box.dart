import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/models/user_model.dart';

class UserBox {
  static const String boxName = 'user';
  late Box<UserModel> _box;
  late UserModel _userModel;

  /// Initialize the box and load the user model
  Future<void> init() async {
    if (!Hive.isBoxOpen(boxName)) {
      throw Exception("Box '$boxName' must be opened in main.dart before calling UserBox.init()");
    }

    _box = Hive.box<UserModel>(boxName);

    // Retrieve or initialize the user data
    _userModel = _box.get(0) ?? UserModel(onboardingStatus: false);
    if (_box.get(0) == null) {
      await _box.put(0, _userModel);
    }
  }

  /// Listen to changes in the user box
  ValueListenable<Box<UserModel>> listenable() => _box.listenable();

  /// Get the onboarding status of the user
  bool getBoardingStatus() {
    return _userModel.onboardingStatus;
  }

  /// Update the user's data
  Future<void> updateUser({String? name}) async {
    if (name != null && name.isEmpty) return; // Avoid empty name updates
    if (name != null) _userModel.name = name;
    await _box.put(0, _userModel);
  }

  /// Get the current user model
  UserModel getUser() {
    return _userModel;
  }
}
