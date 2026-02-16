import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shonenx/core/providers/settings/player_notifier.dart';

part 'player_ui_controller.g.dart';

@immutable
class PlayerUIState {
  final bool isVisible;
  final bool isLocked;
  final double volume;
  final double brightness;
  final bool isSeekForward;
  final int seekAmount;

  const PlayerUIState({
    this.isVisible = true,
    this.isLocked = false,
    this.volume = 0.5,
    this.brightness = 0.5,
    this.isSeekForward = true,
    this.seekAmount = 0,
  });

  PlayerUIState copyWith({
    bool? isVisible,
    bool? isLocked,
    double? volume,
    double? brightness,
    bool? isSeekForward,
    int? seekAmount,
  }) {
    return PlayerUIState(
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      volume: volume ?? this.volume,
      brightness: brightness ?? this.brightness,
      isSeekForward: isSeekForward ?? this.isSeekForward,
      seekAmount: seekAmount ?? this.seekAmount,
    );
  }
}

@riverpod
class PlayerUIController extends _$PlayerUIController {
  Timer? _hideTimer;
  Timer? _seekResetTimer;

  @override
  PlayerUIState build() {
    _initVolumeBrightness();
    ref.onDispose(() {
      _hideTimer?.cancel();
      _seekResetTimer?.cancel();
    });
    return const PlayerUIState();
  }

  Future<void> _initVolumeBrightness() async {
    try {
      final v = (await FlutterVolumeController.getVolume()) ?? 0.5;
      final b = await ScreenBrightness().application;
      state = state.copyWith(volume: v, brightness: b);
    } catch (_) {}
  }

  void restartHideTimer() {
    _hideTimer?.cancel();
    if (state.isLocked || !state.isVisible) return;

    final settings = ref.read(playerSettingsProvider);
    _hideTimer = Timer(Duration(seconds: settings.autoHideDuration), () {
      state = state.copyWith(isVisible: false);
    });
  }

  void toggleVisibility({bool? override}) {
    final newVal = override ?? !state.isVisible;
    state = state.copyWith(isVisible: newVal);
    newVal ? restartHideTimer() : _hideTimer?.cancel();
  }

  void toggleLock() {
    final newLock = !state.isLocked;
    state = state.copyWith(isLocked: newLock, isVisible: true);
    restartHideTimer();
  }

  Future<void> setVolume(double value) async {
    final v = value.clamp(0.0, 1.0);
    state = state.copyWith(volume: v);
    await FlutterVolumeController.setVolume(v);
  }

  Future<void> setBrightness(double value) async {
    final b = value.clamp(0.0, 1.0);
    state = state.copyWith(brightness: b);
    try {
      await ScreenBrightness().setApplicationScreenBrightness(b);
    } catch (_) {}
  }

  void showSeekIndicator(bool forward, int amount) {
    _seekResetTimer?.cancel();

    // Accumulate if same direction, reset otherwise
    int newAmount = amount;
    if (state.seekAmount > 0 && state.isSeekForward == forward) {
      newAmount = state.seekAmount + amount;
    }

    state = state.copyWith(isSeekForward: forward, seekAmount: newAmount);

    _seekResetTimer = Timer(const Duration(seconds: 1), () {
      state = state.copyWith(seekAmount: 0);
    });

    restartHideTimer();
  }
}
