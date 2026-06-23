import 'dart:convert';

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

class MediaKitPrefs {
  final bool enableHardwareAcceleration;
  final bool enableLowLatency;
  final Duration minBuffer;
  final Duration maxBuffer;
  final MediaKitAudioChannel audioChannel;
  final bool boostVolume;

  const MediaKitPrefs({
    this.enableHardwareAcceleration = true,
    this.enableLowLatency = false,
    this.minBuffer = const Duration(seconds: 5),
    this.maxBuffer = const Duration(seconds: 30),
    this.audioChannel = MediaKitAudioChannel.stereo,
    this.boostVolume = false,
  });

  MediaKitPrefs copyWith({
    bool? enableHardwareAcceleration,
    bool? enableLowLatency,
    Duration? minBuffer,
    Duration? maxBuffer,
    MediaKitAudioChannel? audioChannel,
    bool? boostVolume,
  }) {
    return MediaKitPrefs(
      enableHardwareAcceleration:
          enableHardwareAcceleration ?? this.enableHardwareAcceleration,
      enableLowLatency: enableLowLatency ?? this.enableLowLatency,
      minBuffer: minBuffer ?? this.minBuffer,
      maxBuffer: maxBuffer ?? this.maxBuffer,
      audioChannel: audioChannel ?? this.audioChannel,
      boostVolume: boostVolume ?? this.boostVolume,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MediaKitPrefs &&
            other.enableHardwareAcceleration == enableHardwareAcceleration &&
            other.enableLowLatency == enableLowLatency &&
            other.minBuffer == minBuffer &&
            other.maxBuffer == maxBuffer &&
            other.audioChannel == audioChannel &&
            other.boostVolume == boostVolume);
  }

  @override
  int get hashCode => Object.hash(
    enableHardwareAcceleration,
    enableLowLatency,
    minBuffer,
    maxBuffer,
    audioChannel,
    boostVolume,
  );

  @override
  String toString() {
    return 'MediaKitPrefs('
        'hwAccel: $enableHardwareAcceleration, '
        'lowLatency: $enableLowLatency, '
        'minBuffer: $minBuffer, '
        'maxBuffer: $maxBuffer, '
        'audioChannel: $audioChannel, '
        'boostVolume: $boostVolume'
        ')';
  }

  factory MediaKitPrefs.fromMap(Map<String, dynamic> map) {
    return MediaKitPrefs(
      enableHardwareAcceleration: map['enableHardwareAcceleration'] ?? true,
      enableLowLatency: map['enableLowLatency'] ?? false,
      minBuffer: Duration(milliseconds: map['minBufferMs'] ?? 5000),
      maxBuffer: Duration(milliseconds: map['maxBufferMs'] ?? 30000),
      audioChannel: MediaKitAudioChannel.fromString(
        map['audioChannel'] as String?,
      ),
      boostVolume: map['boostVolume'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableHardwareAcceleration': enableHardwareAcceleration,
      'enableLowLatency': enableLowLatency,
      'minBufferMs': minBuffer.inMilliseconds,
      'maxBufferMs': maxBuffer.inMilliseconds,
      'audioChannel': audioChannel.value,
      'boostVolume': boostVolume,
    };
  }

  factory MediaKitPrefs.fromJson(String source) =>
      MediaKitPrefs.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());
}
