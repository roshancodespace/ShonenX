import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'dart:developer' as developer;
import 'dart:io';

class GestureHandler {
  double? _initialBrightness;
  double? _initialVolume;
  double _brightnessValue = 0.5;
  double _volumeValue = 0.5;
  final VoidCallback resetTimer;
  final Function(BuildContext, {required bool isBrightness}) showOverlay;
  DateTime _lastUpdate = DateTime.now();
  static const _mobileDebounceDuration = Duration(milliseconds: 50);
  static const _minDeltaThreshold = 0.01;
  double _accumulatedDelta = 0.0;

  GestureHandler({
    required this.resetTimer,
    required this.showOverlay,
    double initialBrightness = 0.5,
    double initialVolume = 0.5,
  })  : _brightnessValue = initialBrightness,
        _volumeValue = initialVolume;

  Future<void> initialize() async {
    if (!_isMobile) return;
    try {
      _brightnessValue = await ScreenBrightness().application;
      _volumeValue = await FlutterVolumeController.getVolume() ?? 0.5;
    } catch (e) {
      developer.log('Error initializing brightness/volume: $e');
    }
  }

  void onPanStart(BuildContext context, DragStartDetails details) {
    if (!_isMobile) return;

    resetTimer();
    _accumulatedDelta = 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final xPos = details.globalPosition.dx;

    if (xPos < screenWidth / 2) {
      _initialBrightness = _brightnessValue;
      showOverlay(context, isBrightness: true);
    } else {
      _initialVolume = _volumeValue;
      showOverlay(context, isBrightness: false);
    }
  }

  Future<void> onPanUpdate(
      BuildContext context, DragUpdateDetails details) async {
    if (!_isMobile || (_initialBrightness == null && _initialVolume == null)) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastUpdate) < _mobileDebounceDuration) {
      _accumulatedDelta +=
          -details.delta.dy / (MediaQuery.of(context).size.height / 2);
      return;
    }
    _lastUpdate = now;

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final xPos = details.globalPosition.dx;
    final delta = -details.delta.dy / (screenHeight / 2);
    _accumulatedDelta += delta;

    if (_accumulatedDelta.abs() < _minDeltaThreshold) return;

    try {
      if (xPos < screenWidth / 2 && _initialBrightness != null) {
        _brightnessValue =
            (_initialBrightness! + _accumulatedDelta).clamp(0.0, 1.0);
        await ScreenBrightness()
            .setApplicationScreenBrightness(_brightnessValue);
        if (context.mounted) {
          showOverlay(context, isBrightness: true);
        }
      } else if (_initialVolume != null) {
        _volumeValue = (_initialVolume! + _accumulatedDelta).clamp(0.0, 1.0);
        await FlutterVolumeController.setVolume(_volumeValue);
        if (context.mounted) {
          showOverlay(context, isBrightness: false);
        }
      }
      _accumulatedDelta = 0.0;
    } catch (e) {
      developer.log('Error adjusting brightness/volume: $e');
    }
  }

  void onPanEnd() {
    if (!_isMobile) return;
    _initialBrightness = null;
    _initialVolume = null;
    _accumulatedDelta = 0.0;
    resetTimer();
  }

  double get brightnessValue => _brightnessValue;
  double get volumeValue => _volumeValue;

  bool get _isMobile => Platform.isAndroid || Platform.isIOS;
}
