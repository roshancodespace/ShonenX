import 'dart:convert';
import 'dart:io';

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
  default_('Default', 0, 0, 0, 0, 0),
  vibrant('Vibrant', 5, 10, 30, 0, 0),
  anime('Anime (Colorful)', 5, 5, 40, 0, 0),
  film('Film (Cinematic)', -5, 20, -10, 10, 0),
  cool('Cool (Bluish)', 0, 5, 10, 0, -5),
  warm('Warm (Yellowish)', 0, 5, 10, 0, 5);

  final String label;
  final int brightness;
  final int contrast;
  final int saturation;
  final int gamma;
  final int hue;

  const MediaKitColorPreset(
    this.label,
    this.brightness,
    this.contrast,
    this.saturation,
    this.gamma,
    this.hue,
  );

  static MediaKitColorPreset fromString(String? value) {
    if (value == null) return MediaKitColorPreset.default_;
    return MediaKitColorPreset.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MediaKitColorPreset.default_,
    );
  }
}

enum MediaKitAudioNormalizePreset {
  none('None', ''),
  light('Light', 'acompressor=ratio=2:makeup=2'),
  standard('Standard', 'acompressor=ratio=4:makeup=4'),
  heavy('Heavy', 'acompressor=ratio=8:makeup=8');

  final String label;
  final String filter;

  const MediaKitAudioNormalizePreset(this.label, this.filter);

  static MediaKitAudioNormalizePreset fromString(String? value) {
    if (value == null) return MediaKitAudioNormalizePreset.none;
    return MediaKitAudioNormalizePreset.values.firstWhere(
      (e) => e.name == value,
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
            other.rawConfiguration == rawConfiguration);
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
        'rawConfiguration: $rawConfiguration'
        ')';
  }

  factory MediaKitPrefs.fromMap(Map<String, dynamic> map) {
    String defaultHwdec = 'auto-copy';
    try {
      if (Platform.isAndroid || Platform.isIOS) defaultHwdec = 'auto-safe';
    } catch (_) {}

    return MediaKitPrefs(
      enableHardwareAcceleration: map['enableHardwareAcceleration'] ?? true,
      hwdec: map['hwdec'] ?? defaultHwdec,
      vo: map['vo'] ?? 'auto',
      enableLowLatency: map['enableLowLatency'] ?? false,
      minBuffer: Duration(milliseconds: map['minBufferMs'] ?? 5000),
      maxBuffer: Duration(milliseconds: map['maxBufferMs'] ?? 30000),
      audioChannel: MediaKitAudioChannel.fromString(
        map['audioChannel'] as String?,
      ),
      boostVolume: map['boostVolume'] ?? false,
      audioNormalizePreset:
          MediaKitAudioNormalizePreset.fromString(
                map['audioNormalizePreset'] as String?,
              ) ==
              MediaKitAudioNormalizePreset.none
          ? MediaKitAudioNormalizePreset.none
          : MediaKitAudioNormalizePreset.fromString(
              map['audioNormalizePreset'] as String?,
            ),
      colorPreset: MediaKitColorPreset.fromString(
        map['colorPreset'] as String?,
      ),
      rawConfiguration: map['rawConfiguration'] ?? '',
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
      'audioNormalizePreset': audioNormalizePreset.name,
      'colorPreset': colorPreset.name,
      'rawConfiguration': rawConfiguration,
    };
  }

  factory MediaKitPrefs.fromJson(String source) =>
      MediaKitPrefs.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());
}
