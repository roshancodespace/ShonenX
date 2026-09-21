import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

enum MediaKitAudioChannel {
  stereo('stereo'),
  mono('mono'),
  surround51('5.1'),
  surround71('7.1');

  final String value;
  const MediaKitAudioChannel(this.value);

  static MediaKitAudioChannel fromString(String? value) {
    if (value == null) return MediaKitAudioChannel.stereo;

    return MediaKitAudioChannel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MediaKitAudioChannel.stereo,
    );
  }
}

enum MediaKitColorPreset {
  default_('Default', 0, 0, 0, 0, 0, 'default_'),
  vibrant('Vibrant', 5, 10, 30, 0, 0, 'vibrant'),
  anime('Anime (Colorful)', 5, 5, 40, 0, 0, 'anime'),
  film('Film (Cinematic)', -5, 20, -10, 10, 0, 'film'),
  cool('Cool (Bluish)', 0, 5, 10, 0, -5, 'cool'),
  warm('Warm (Yellowish)', 0, 5, 10, 0, 5, 'warm');

  final String label;
  final int brightness;
  final int contrast;
  final int saturation;
  final int gamma;
  final int hue;
  final String value;

  const MediaKitColorPreset(
    this.label,
    this.brightness,
    this.contrast,
    this.saturation,
    this.gamma,
    this.hue,
    this.value,
  );

  static MediaKitColorPreset fromString(String? val) {
    if (val == null) return MediaKitColorPreset.default_;
    return MediaKitColorPreset.values.firstWhere(
      (e) => e.value == val || e.name == val,
      orElse: () => MediaKitColorPreset.default_,
    );
  }
}

enum MediaKitAudioNormalizePreset {
  none('None', '', 'none'),
  light('Light', 'acompressor=ratio=2:makeup=2', 'light'),
  standard('Standard', 'acompressor=ratio=4:makeup=4', 'standard'),
  heavy('Heavy', 'acompressor=ratio=8:makeup=8', 'heavy');

  final String label;
  final String filter;
  final String value;

  const MediaKitAudioNormalizePreset(this.label, this.filter, this.value);

  static MediaKitAudioNormalizePreset fromString(String? val) {
    if (val == null) return MediaKitAudioNormalizePreset.none;
    return MediaKitAudioNormalizePreset.values.firstWhere(
      (e) => e.value == val || e.name == val,
      orElse: () => MediaKitAudioNormalizePreset.none,
    );
  }
}

class MediaKitPrefs {
  final bool enableHardwareAcceleration;
  final String hwdec;
  final String vo;
  final bool enableLowLatency;
  final Duration minBuffer;
  final Duration maxBuffer;
  final MediaKitAudioChannel audioChannel;
  final bool boostVolume;
  final MediaKitAudioNormalizePreset audioNormalizePreset;
  final MediaKitColorPreset colorPreset;
  final String rawConfiguration;
  final bool libassEnabled;

  const MediaKitPrefs({
    this.enableHardwareAcceleration = true,
    this.hwdec = 'auto-copy',
    this.vo = 'auto',
    this.enableLowLatency = false,
    this.minBuffer = const Duration(seconds: 5),
    this.maxBuffer = const Duration(seconds: 30),
    this.audioChannel = MediaKitAudioChannel.stereo,
    this.boostVolume = false,
    this.audioNormalizePreset = MediaKitAudioNormalizePreset.none,
    this.colorPreset = MediaKitColorPreset.default_,
    this.rawConfiguration = '',
    this.libassEnabled = true,
  });

  MediaKitPrefs copyWith({
    bool? enableHardwareAcceleration,
    String? hwdec,
    String? vo,
    bool? enableLowLatency,
    Duration? minBuffer,
    Duration? maxBuffer,
    MediaKitAudioChannel? audioChannel,
    bool? boostVolume,
    MediaKitAudioNormalizePreset? audioNormalizePreset,
    MediaKitColorPreset? colorPreset,
    String? rawConfiguration,
    bool? libassEnabled,
  }) {
    return MediaKitPrefs(
      enableHardwareAcceleration:
          enableHardwareAcceleration ?? this.enableHardwareAcceleration,
      hwdec: hwdec ?? this.hwdec,
      vo: vo ?? this.vo,
      enableLowLatency: enableLowLatency ?? this.enableLowLatency,
      minBuffer: minBuffer ?? this.minBuffer,
      maxBuffer: maxBuffer ?? this.maxBuffer,
      audioChannel: audioChannel ?? this.audioChannel,
      boostVolume: boostVolume ?? this.boostVolume,
      audioNormalizePreset: audioNormalizePreset ?? this.audioNormalizePreset,
      colorPreset: colorPreset ?? this.colorPreset,
      rawConfiguration: rawConfiguration ?? this.rawConfiguration,
      libassEnabled: libassEnabled ?? this.libassEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MediaKitPrefs &&
            other.enableHardwareAcceleration == enableHardwareAcceleration &&
            other.hwdec == hwdec &&
            other.vo == vo &&
            other.enableLowLatency == enableLowLatency &&
            other.minBuffer == minBuffer &&
            other.maxBuffer == maxBuffer &&
            other.audioChannel == audioChannel &&
            other.boostVolume == boostVolume &&
            other.audioNormalizePreset == audioNormalizePreset &&
            other.colorPreset == colorPreset &&
            other.rawConfiguration == rawConfiguration &&
            other.libassEnabled == libassEnabled);
  }

  @override
  int get hashCode => Object.hash(
    enableHardwareAcceleration,
    hwdec,
    vo,
    enableLowLatency,
    minBuffer,
    maxBuffer,
    audioChannel,
    boostVolume,
    audioNormalizePreset,
    colorPreset,
    rawConfiguration,
    libassEnabled,
  );

  @override
  String toString() {
    return 'MediaKitPrefs('
        'hwAccel: $enableHardwareAcceleration, '
        'hwdec: $hwdec, '
        'vo: $vo, '
        'lowLatency: $enableLowLatency, '
        'minBuffer: $minBuffer, '
        'maxBuffer: $maxBuffer, '
        'audioChannel: $audioChannel, '
        'boostVolume: $boostVolume, '
        'audioNorm: $audioNormalizePreset, '
        'colorPreset: $colorPreset, '
        'rawConfiguration: $rawConfiguration, '
        'libassEnabled: $libassEnabled'
        ')';
  }

  factory MediaKitPrefs.fromMap(Map<String, dynamic> map) {
    String defaultHwdec = 'auto-copy';
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      defaultHwdec = 'auto-safe';
    }

    return MediaKitPrefs(
      enableHardwareAcceleration:
          map['enableHardwareAcceleration'] as bool? ?? true,
      hwdec: map['hwdec'] as String? ?? defaultHwdec,
      vo: map['vo'] as String? ?? 'auto',
      enableLowLatency: map['enableLowLatency'] as bool? ?? false,
      minBuffer: Duration(milliseconds: map['minBufferMs'] as int? ?? 5000),
      maxBuffer: Duration(milliseconds: map['maxBufferMs'] as int? ?? 30000),
      audioChannel: MediaKitAudioChannel.fromString(
        map['audioChannel'] as String?,
      ),
      boostVolume: map['boostVolume'] as bool? ?? false,
      audioNormalizePreset: MediaKitAudioNormalizePreset.fromString(
        map['audioNormalizePreset'] as String?,
      ),
      colorPreset: MediaKitColorPreset.fromString(
        map['colorPreset'] as String?,
      ),
      rawConfiguration: map['rawConfiguration'] as String? ?? '',
      libassEnabled: map['libassEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableHardwareAcceleration': enableHardwareAcceleration,
      'hwdec': hwdec,
      'vo': vo,
      'enableLowLatency': enableLowLatency,
      'minBufferMs': minBuffer.inMilliseconds,
      'maxBufferMs': maxBuffer.inMilliseconds,
      'audioChannel': audioChannel.value,
      'boostVolume': boostVolume,
      'audioNormalizePreset': audioNormalizePreset.value,
      'colorPreset': colorPreset.value,
      'rawConfiguration': rawConfiguration,
      'libassEnabled': libassEnabled,
    };
  }

  factory MediaKitPrefs.fromJson(String source) =>
      MediaKitPrefs.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());
}
