import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/ui_model.dart';

final uiSettingsProvider = NotifierProvider<UiSettingsNotifier, UiModel>(
  UiSettingsNotifier.new,
);

class UiSettingsNotifier extends Notifier<UiModel> {
  static const _boxName = 'ui_settings';
  static const _key = 'settings';

  @override
  UiModel build() {
    final box = Hive.box<UiModel>(_boxName);
    return box.get(_key, defaultValue: UiModel()) ?? UiModel();
  }

  void updateSettings(UiModel Function(UiModel) updater) {
    state = updater(state);
    Hive.box<UiModel>(_boxName).put(_key, state);
  }
}
