import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/experimental_model.dart';

final experimentalProvider =
    NotifierProvider<ExperimentalFeaturesNotifier, ExperimentalFeaturesModel>(
        ExperimentalFeaturesNotifier.new);

class ExperimentalFeaturesNotifier extends Notifier<ExperimentalFeaturesModel> {
  static const _boxName = 'experimental_features';
  static const _key = 'settings';

  @override
  ExperimentalFeaturesModel build() {
    final box = Hive.box<ExperimentalFeaturesModel>(_boxName);
    return box.get(_key, defaultValue: ExperimentalFeaturesModel()) ??
        ExperimentalFeaturesModel();
  }

  void updateSettings(
      ExperimentalFeaturesModel Function(ExperimentalFeaturesModel) updater) {
    state = updater(state);
    Hive.box<ExperimentalFeaturesModel>(_boxName).put(_key, state);
  }
}
