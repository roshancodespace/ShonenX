import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';
import 'package:shonenx/main.dart';

final experimentalProvider =
    NotifierProvider<ExperimentalFeaturesNotifier, ExperimentalFeaturesModel>(
      ExperimentalFeaturesNotifier.new,
    );

class ExperimentalFeaturesNotifier extends Notifier<ExperimentalFeaturesModel> {
  static const _boxName = 'experimental_features';
  static const _hiveKey = 'settings';
  static const _prefsKey = 'experimental_features_data';

  @override
  ExperimentalFeaturesModel build() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      return ExperimentalFeaturesModel.fromJson(jsonString);
    }

    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box<ExperimentalFeaturesModel>(_boxName);
        final oldSettings = box.get(_hiveKey);
        if (oldSettings != null) {
          sharedPrefs.setString(_prefsKey, oldSettings.toJson());
          return oldSettings;
        }
      } catch (_) {}
    }

    return ExperimentalFeaturesModel();
  }

  void updateSettings(
    ExperimentalFeaturesModel Function(ExperimentalFeaturesModel) updater,
  ) {
    state = updater(state);
    sharedPrefs.setString(_prefsKey, state.toJson());
  }
}
