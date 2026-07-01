import 'dart:convert';

class MdkPrefs {
  final bool enableFastSeek;
  final String decoderPriority;
  final int bufferCapacityMs;
  final bool dropFrames;
  final String rawConfiguration;

  const MdkPrefs({
    this.enableFastSeek = true,
    this.decoderPriority = 'Auto',
    this.bufferCapacityMs = 15000,
    this.dropFrames = false,
    this.rawConfiguration = '',
  });

  MdkPrefs copyWith({
    bool? enableFastSeek,
    String? decoderPriority,
    int? bufferCapacityMs,
    bool? dropFrames,
    String? rawConfiguration,
  }) {
    return MdkPrefs(
      enableFastSeek: enableFastSeek ?? this.enableFastSeek,
      decoderPriority: decoderPriority ?? this.decoderPriority,
      bufferCapacityMs: bufferCapacityMs ?? this.bufferCapacityMs,
      dropFrames: dropFrames ?? this.dropFrames,
      rawConfiguration: rawConfiguration ?? this.rawConfiguration,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MdkPrefs &&
            other.enableFastSeek == enableFastSeek &&
            other.decoderPriority == decoderPriority &&
            other.bufferCapacityMs == bufferCapacityMs &&
            other.dropFrames == dropFrames &&
            other.rawConfiguration == rawConfiguration);
  }

  @override
  int get hashCode => Object.hash(
    enableFastSeek,
    decoderPriority,
    bufferCapacityMs,
    dropFrames,
    rawConfiguration,
  );

  factory MdkPrefs.fromMap(Map<String, dynamic> map) {
    return MdkPrefs(
      enableFastSeek: map['enableFastSeek'] ?? true,
      decoderPriority: map['decoderPriority'] ?? 'Auto',
      bufferCapacityMs: map['bufferCapacityMs'] ?? 15000,
      dropFrames: map['dropFrames'] ?? false,
      rawConfiguration: map['rawConfiguration'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableFastSeek': enableFastSeek,
      'decoderPriority': decoderPriority,
      'bufferCapacityMs': bufferCapacityMs,
      'dropFrames': dropFrames,
      'rawConfiguration': rawConfiguration,
    };
  }

  factory MdkPrefs.fromJson(String source) =>
      MdkPrefs.fromMap(jsonDecode(source));

  String toJson() => jsonEncode(toMap());
}
