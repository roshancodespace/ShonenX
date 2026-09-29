import 'package:flutter/widgets.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/engine/media_kit/media_kit_engine.dart';
import 'package:shonenx/features/player/engine/better_player/better_player_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/media_kit/media_kit_settings.dart';
import 'package:shonenx/features/player/presentation/widgets/better_player/better_player_settings.dart';

extension VideoEngineSettingsExt on VideoEngine {
  Widget? buildSettingsView(BuildContext context) {
    if (this is MediaKitEngine) {
      return const MediaKitAdvancedSettings();
    } else if (this is BetterPlayerEngine) {
      return const BetterPlayerSettingsContent();
    }
    return null;
  }
}
