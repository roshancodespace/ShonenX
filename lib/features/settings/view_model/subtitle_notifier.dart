import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/settings/model/subtitle_appearance_model.dart';

final subtitleAppearanceProvider =
    NotifierProvider<SubtitleAppearanceNotifier, SubtitleAppearanceModel>(
  SubtitleAppearanceNotifier.new,
);

class SubtitleAppearanceNotifier extends Notifier<SubtitleAppearanceModel> {
  static const _boxName = 'subtitle_appearance';
  static const _key = 'settings';

  @override
  SubtitleAppearanceModel build() {
    final box = Hive.box<SubtitleAppearanceModel>(_boxName);
    return box.get(_key, defaultValue: SubtitleAppearanceModel()) ??
        SubtitleAppearanceModel(
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
      SubtitleAppearanceModel Function(SubtitleAppearanceModel) updater) {
    state = updater(state);
    Hive.box<SubtitleAppearanceModel>(_boxName).put(_key, state);
  }
}
