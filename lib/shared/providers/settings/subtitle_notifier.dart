import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/core/models/settings/subtitle_appearance_model.dart';
import 'package:shonenx/main.dart';

final subtitleAppearanceProvider =
    NotifierProvider<SubtitleAppearanceNotifier, SubtitleAppearanceModel>(
      SubtitleAppearanceNotifier.new,
    );

class SubtitleAppearanceNotifier extends Notifier<SubtitleAppearanceModel> {
  static const _boxName = 'subtitle_appearance';
  static const _hiveKey = 'settings';
  static const _prefsKey = 'subtitle_appearance_data';

  @override
  SubtitleAppearanceModel build() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      return SubtitleAppearanceModel.fromJson(jsonString);
    }

    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box<SubtitleAppearanceModel>(_boxName);
        final oldSettings = box.get(_hiveKey);
        if (oldSettings != null) {
          sharedPrefs.setString(_prefsKey, oldSettings.toJson());
          return oldSettings;
        }
      } catch (_) {}
    }

    return SubtitleAppearanceModel(
      fontSize: 16,
      textColor: 0xFFFFFFFF,
      backgroundOpacity: 0.5,
      hasShadow: true,
      shadowOpacity: 0.5,
      shadowBlur: 2,
      fontFamily: null,
      position: 1,
      boldText: true,
      forceUppercase: false,
    );
  }

  void updateSettings(
    SubtitleAppearanceModel Function(SubtitleAppearanceModel) updater,
  ) {
    state = updater(state);
    sharedPrefs.setString(_prefsKey, state.toJson());
  }
}
