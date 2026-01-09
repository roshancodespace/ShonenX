import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/content_settings_model.dart';

final contentSettingsProvider =
    NotifierProvider<ContentSettingsNotifier, ContentSettingsModel>(
  ContentSettingsNotifier.new,
);

class ContentSettingsNotifier extends Notifier<ContentSettingsModel> {
  static const _boxName = 'content_settings';
  static const _key = 'settings';

  @override
  ContentSettingsModel build() {
    final box = Hive.box<ContentSettingsModel>(_boxName);
    return box.get(_key, defaultValue: const ContentSettingsModel()) ??
        const ContentSettingsModel();
  }

  void updateSettings(
      ContentSettingsModel Function(ContentSettingsModel) updater) {
    state = updater(state);
    Hive.box<ContentSettingsModel>(_boxName).put(_key, state);
  }
}
