import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/theme_model.dart';

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeModel>(
  ThemeSettingsNotifier.new,
);

class ThemeSettingsNotifier extends Notifier<ThemeModel> {
  static const _boxName = 'theme_settings';
  static const _key = 'settings';

  @override
  ThemeModel build() {
    if (!Hive.isBoxOpen(_boxName)) {
      Hive.openBox<ThemeModel>(_boxName);
    }
    final box = Hive.box<ThemeModel>(_boxName);
    return box.get(_key, defaultValue: ThemeModel()) ?? ThemeModel();
  }

  void updateSettings(ThemeModel Function(ThemeModel) updater) {
    state = updater(state);
    Hive.box<ThemeModel>(_boxName).put(_key, state);
  }
}
