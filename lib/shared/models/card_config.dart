import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

abstract class CardConfig {
  const CardConfig();
  Map<String, dynamic> toJson();

  static CardConfig fromJson(MediaCardStyle style, Map<String, dynamic>? json) {
    switch (style) {
      case MediaCardStyle.experimentalLiquid:
        return ExperimentalLiquidConfig.fromJson(json ?? {});
      default:
        return const EmptyCardConfig();
    }
  }
}

class EmptyCardConfig extends CardConfig {
  const EmptyCardConfig();

  @override
  Map<String, dynamic> toJson() => {};

  @override
  bool operator ==(Object other) => other is EmptyCardConfig;

  @override
  int get hashCode => 0;
}

class ExperimentalLiquidConfig extends CardConfig {
  final double distortion;
  final double magnification;
  final double smoothness;
  final bool interactiveOrb;
  final double borderSaturation;
  final double chromaticAberration;
  final bool enable3dTilt;

  const ExperimentalLiquidConfig({
    this.distortion = 0.16,
    this.magnification = 1.08,
    this.smoothness = 46.0,
    this.interactiveOrb = true,
    this.borderSaturation = 1.6,
    this.chromaticAberration = 0.006,
    this.enable3dTilt = true,
  });

  ExperimentalLiquidConfig copyWith({
    double? distortion,
    double? magnification,
    double? smoothness,
    bool? interactiveOrb,
    double? borderSaturation,
    double? chromaticAberration,
    bool? enable3dTilt,
  }) {
    return ExperimentalLiquidConfig(
      distortion: distortion ?? this.distortion,
      magnification: magnification ?? this.magnification,
      smoothness: smoothness ?? this.smoothness,
      interactiveOrb: interactiveOrb ?? this.interactiveOrb,
      borderSaturation: borderSaturation ?? this.borderSaturation,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      enable3dTilt: enable3dTilt ?? this.enable3dTilt,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'distortion': distortion,
    'magnification': magnification,
    'smoothness': smoothness,
    'interactiveOrb': interactiveOrb,
    'borderSaturation': borderSaturation,
    'chromaticAberration': chromaticAberration,
    'enable3dTilt': enable3dTilt,
  };

  factory ExperimentalLiquidConfig.fromJson(Map<String, dynamic> json) {
    return ExperimentalLiquidConfig(
      distortion: (json['distortion'] as num?)?.toDouble() ?? 0.16,
      magnification: (json['magnification'] as num?)?.toDouble() ?? 1.08,
      smoothness: (json['smoothness'] as num?)?.toDouble() ?? 46.0,
      interactiveOrb: json['interactiveOrb'] as bool? ?? true,
      borderSaturation: (json['borderSaturation'] as num?)?.toDouble() ?? 1.6,
      chromaticAberration:
          (json['chromaticAberration'] as num?)?.toDouble() ?? 0.006,
      enable3dTilt: json['enable3dTilt'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExperimentalLiquidConfig &&
        other.distortion == distortion &&
        other.magnification == magnification &&
        other.smoothness == smoothness &&
        other.interactiveOrb == interactiveOrb &&
        other.borderSaturation == borderSaturation &&
        other.chromaticAberration == chromaticAberration &&
        other.enable3dTilt == enable3dTilt;
  }

  @override
  int get hashCode => Object.hash(
    distortion,
    magnification,
    smoothness,
    interactiveOrb,
    borderSaturation,
    chromaticAberration,
    enable3dTilt,
  );
}
