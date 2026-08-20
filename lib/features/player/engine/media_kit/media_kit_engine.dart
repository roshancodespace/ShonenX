import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/features/player/domain/media_kit_prefs.dart';
import 'package:shonenx/features/player/domain/subtitle_prefs.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/media_kit/media_kit_settings.dart';
import 'package:shonenx/shared/models/video_stream.dart' as stream;
import 'package:shonenx/core/utils/app_logger.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';

class MediaKitEngine implements VideoEngine {
  static final _log = AppLogger.scope('MediaKitEngine');

  late final Player _player;
  late final VideoController _controller;

  MediaKitPrefs prefs;
  final Ref ref;

  bool _disposed = false;

  StreamSubscription<Duration>? _positionSubscription;

  Future<void> updatePrefs(MediaKitPrefs newPrefs) async {
    _log.d('Updating preferences');
    if (_disposed) return;
    prefs = newPrefs;

    final player = _player.platform;
    if (player is! NativePlayer) return;

    Future<void> setPropSafe(String key, String value) async {
      if (_disposed) return;
      try {
        await player.setProperty(key, value);
      } catch (e) {
        _log.w('Failed to set property $key=$value: $e');
      }
    }

    await setPropSafe('audio-channels', prefs.audioChannel.value);
    await setPropSafe('volume-max', '200');

    try {
      await _player.setVolume(prefs.boostVolume ? 140 : 100);
    } catch (_) {}

    if (prefs.audioNormalizePreset != MediaKitAudioNormalizePreset.none) {
      await setPropSafe('af', prefs.audioNormalizePreset.filter);
    } else {
      await setPropSafe('af', '');
    }

    await setPropSafe('cache', 'yes');
    await setPropSafe('demuxer-seekable-cache', 'yes');
    await setPropSafe('demuxer-max-bytes', '154857600');
    await setPropSafe('demuxer-max-back-bytes', '52428800');
    await setPropSafe('demuxer-lavf-probesize', '5000000');
    await setPropSafe('demuxer-lavf-analyzeduration', '5000000');

    final readaheadSecs = prefs.maxBuffer.inSeconds < 60
        ? '60'
        : prefs.maxBuffer.inSeconds.toString();
    await setPropSafe('cache-secs', readaheadSecs);
    await setPropSafe('demuxer-readahead-secs', readaheadSecs);

    await setPropSafe('brightness', prefs.colorPreset.brightness.toString());
    await setPropSafe('contrast', prefs.colorPreset.contrast.toString());
    await setPropSafe('saturation', prefs.colorPreset.saturation.toString());
    await setPropSafe('gamma', prefs.colorPreset.gamma.toString());
    await setPropSafe('hue', prefs.colorPreset.hue.toString());

    if (prefs.rawConfiguration.isNotEmpty) {
      for (final line in prefs.rawConfiguration.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final index = trimmed.indexOf('=');

        if (index != -1) {
          final key = trimmed.substring(0, index).trim();
          final value = trimmed.substring(index + 1).trim();

          await setPropSafe(key, value);
        }
      }
    }
  }

  final List<StreamSubscription> _subscriptions = [];

  MediaKitEngine(this.prefs, this.ref) {
    _player = Player();
    _controller = VideoController(
      _player,
      configuration: VideoControllerConfiguration(
        hwdec: prefs.hwdec,
        enableHardwareAcceleration: prefs.enableHardwareAcceleration,
        vo: prefs.vo != 'auto' ? prefs.vo : null,
      ),
    );
    updatePrefs(prefs);

    _subscriptions.addAll([
      _player.stream.position.listen((pos) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(position: pos);
        }
      }),
      _player.stream.duration.listen((dur) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(duration: dur);
        }
      }),
      _player.stream.buffer.listen((buf) {
        if (!_disposed) {
          ref.read(videoEngineStateProvider.notifier).updateState(buffer: buf);
        }
      }),
      _player.stream.playing.listen((playing) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isPlaying: playing);
        }
      }),
      _player.stream.buffering.listen((buffering) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(isBuffering: buffering);
        }
      }),
      _player.stream.tracks.listen((tracks) {
        if (!_disposed) {
          final audioList = tracks.audio.map((t) => _mapAudioTrack(t)).toList();
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(audioTracks: audioList);
        }
      }),
      _player.stream.track.listen((track) {
        if (!_disposed) {
          ref
              .read(videoEngineStateProvider.notifier)
              .updateState(activeAudioTrack: _mapAudioTrack(track.audio));
        }
      }),
    ]);

    Future.microtask(() {
      if (!_disposed) {
        final initialAudioList = _player.state.tracks.audio
            .map((t) => _mapAudioTrack(t))
            .toList();
        ref
            .read(videoEngineStateProvider.notifier)
            .updateState(
              audioTracks: initialAudioList,
              activeAudioTrack: _mapAudioTrack(_player.state.track.audio),
            );
      }
    });
  }

  Future<void> _waitUntilReady(Future<void> Function() onReady) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final completer = Completer<void>();
    var handled = false;

    _positionSubscription = _player.stream.position.listen((position) async {
      if (handled || position.inMilliseconds <= 0) return;
      handled = true;

      await _positionSubscription?.cancel();
      _positionSubscription = null;

      try {
        await onReady();
      } finally {
        if (!completer.isCompleted) completer.complete();
      }
    });

    await completer.future;
  }

  @override
  Future<void> initialize(
    stream.VideoStream stream, {
    stream.SubtitleTrack? subtitle,
    Duration? startAt,
  }) async {
    _log.i('Initializing player with URL: ${stream.url}');
    final media = Media(stream.url, httpHeaders: stream.headers);

    await _player.open(media, play: true);

    await _waitUntilReady(() async {
      if (subtitle != null) {
        await setSubtitle(subtitle);
      }
      if (startAt != null) {
        await _player.seek(startAt);
      }
    });
  }

  @override
  Widget buildVideoView() {
    return Consumer(
      builder: (context, ref, _) {
        final fit = ref.watch(videoEngineStateProvider.select((s) => s.fit));
        final subtitlePrefs = ref.watch(subtitlePrefsProvider);
        final screenWidth = MediaQuery.sizeOf(context).width;
        final responsiveFontSize = getResponsiveSubtitleSize(
          screenWidth,
          subtitlePrefs.fontSize,
        );

        return Video(
          controller: _controller,
          controls: NoVideoControls,
          fit: fit,
          subtitleViewConfiguration: SubtitleViewConfiguration(
            padding: EdgeInsets.only(bottom: subtitlePrefs.bottomPadding),
            style: getSubtitleStrokeStyleInShadowForm(
              subtitlePrefs,
              responsiveFontSize,
            ),
            textScaler: TextScaler.linear(subtitlePrefs.fontSize / 1.2),
          ),
        );
      },
    );
  }

  @override
  Widget? buildSettingsView(BuildContext context) => MediaKitSettings();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seekTo(Duration position) => _player.seek(position);

  @override
  Future<void> seekRelative(Duration offset) async {
    final currentPos = _player.state.position;
    await _player.seek(currentPos + offset);
  }

  @override
  Future<void> changeQuality(stream.VideoStream newStream) async {
    _log.i('Changing quality to URL: ${newStream.url}');
    final currentPos = _player.state.position;

    await _player.open(Media(newStream.url, httpHeaders: newStream.headers));
    await _waitUntilReady(() async {
      await _player.seek(currentPos);
      await _player.play();
    });
  }

  @override
  Future<void> setSubtitle(stream.SubtitleTrack? subtitle) async {
    if (subtitle == null || subtitle.url.isEmpty) {
      _log.d('Disabling subtitle');
      await _player.setSubtitleTrack(SubtitleTrack.no());
    } else {
      _log.d('Setting subtitle: ${subtitle.url} (lang: ${subtitle.language})');
      await _player.setSubtitleTrack(
        SubtitleTrack.uri(subtitle.url, language: subtitle.language),
      );
    }
  }

  stream.AudioTrack _mapAudioTrack(AudioTrack track) {
    if (track.id == 'auto') return stream.AudioTrack.auto;
    if (track.id == 'no') return stream.AudioTrack.none;

    final title = track.title?.trim();
    final lang = track.language?.trim();

    String label;
    if (title != null && title.isNotEmpty) {
      if (lang != null &&
          lang.isNotEmpty &&
          !title.toLowerCase().contains(lang.toLowerCase())) {
        label = '$title ($lang)';
      } else {
        label = title;
      }
    } else if (lang != null && lang.isNotEmpty) {
      label = lang.toUpperCase();
    } else {
      label = 'Track ${track.id}';
    }

    return stream.AudioTrack(id: track.id, label: label, language: lang);
  }

  @override
  Future<void> setAudioTrack(stream.AudioTrack track) async {
    if (track.id == 'auto') {
      _log.d('Setting audio track: auto');
      await _player.setAudioTrack(AudioTrack.auto());
    } else if (track.id == 'no') {
      _log.d('Disabling audio track');
      await _player.setAudioTrack(AudioTrack.no());
    } else {
      final target = _player.state.tracks.audio.firstWhere(
        (t) => t.id == track.id,
        orElse: () => AudioTrack.auto(),
      );
      _log.d('Setting audio track: ${target.id} (${target.title})');
      await _player.setAudioTrack(target);
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setRate(speed);
  }

  @override
  Future<void> dispose() async {
    _log.i('Disposing engine');
    _disposed = true;
    await _positionSubscription?.cancel();
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    await _player.dispose();
  }

  @override
  Duration get currentPosition => _player.state.position;

  @override
  Duration get currentDuration => _player.state.duration;
}
