import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/content_settings_model.dart';
import 'package:shonenx/main.dart';

final contentSettingsProvider =
    NotifierProvider<ContentSettingsNotifier, ContentSettingsModel>(
      ContentSettingsNotifier.new,
    );

class ContentSettingsNotifier extends Notifier<ContentSettingsModel> {
  static const _boxName = 'content_settings';
  static const _hiveKey = 'settings';
  static const _prefsKey = 'content_settings_data';

  @override
  ContentSettingsModel build() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      return ContentSettingsModel.fromJson(jsonString);
    }

    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box<ContentSettingsModel>(_boxName);
        final oldSettings = box.get(_hiveKey);
        if (oldSettings != null) {
          sharedPrefs.setString(_prefsKey, oldSettings.toJson());
          return oldSettings;
        }
      } catch (_) {}
    }

    return const ContentSettingsModel();
  }

  void updateSettings(
    ContentSettingsModel Function(ContentSettingsModel) updater,
  ) {
    state = updater(state);
    sharedPrefs.setString(_prefsKey, state.toJson());
  }
}
