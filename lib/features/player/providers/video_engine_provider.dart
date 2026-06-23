import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/engine/better_player/better_player_engine.dart';
import 'package:shonenx/features/player/engine/media_kit/media_kit_engine.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/providers/media_kit_prefs_provider.dart';
import 'package:shonenx/features/player/providers/player_prefs_provider.dart';

class EngineState {
  final Duration position;
  final Duration duration;
  final Duration buffer;
  final bool isPlaying;
  final bool isBuffering;

  const EngineState({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffer = Duration.zero,
    this.isPlaying = false,
    this.isBuffering = false,
  });

  EngineState copyWith({
    Duration? position,
    Duration? duration,
    Duration? buffer,
    bool? isPlaying,
    bool? isBuffering,
  }) {
    return EngineState(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffer: buffer ?? this.buffer,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }
}

class EngineStateNotifier extends Notifier<EngineState> {
  @override
  EngineState build() => const EngineState();

  void updateState({
    Duration? position,
    Duration? duration,
    Duration? buffer,
    bool? isPlaying,
    bool? isBuffering,
  }) {
    state = state.copyWith(
      position: position,
      duration: duration,
      buffer: buffer,
      isPlaying: isPlaying,
      isBuffering: isBuffering,
    );
  }
}

final videoEngineStateProvider =
    NotifierProvider.autoDispose<EngineStateNotifier, EngineState>(
      EngineStateNotifier.new,
    );

final videoEngineProvider = Provider.autoDispose<VideoEngine>((ref) {
  final playerType = ref.watch(playerPrefsProvider.select((s) => s.playerType));

  switch (playerType) {
    case PlayerType.mediakit:
      final prefs = ref.read(mediaKitPrefsProvider);
      final engine = MediaKitEngine(prefs, ref);

      ref.listen(mediaKitPrefsProvider, (previous, next) async {
        await engine.updatePrefs(next);
      });

      ref.onDispose(engine.dispose);
      return engine;
    case PlayerType.betterplayer:
      final engine = BetterPlayerEngine(ref);

      ref.onDispose(engine.dispose);
      return engine;
  }
});
