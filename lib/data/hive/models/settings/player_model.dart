import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/data/hive/hive_type_ids.dart';
import 'package:shonenx/data/hive/models/subtitle_style_model.dart';

part 'player_model.g.dart';

@HiveType(typeId: HiveTypeIds.player)
class PlayerSettings extends HiveObject {
  @HiveField(0)
  final double episodeCompletionThreshold;

  @HiveField(1)
  final bool autoPlayNextEpisode;

  @HiveField(2)
  final bool preferSubtitles;

  // Subtitle style fields
  @HiveField(3)
  final double subtitleFontSize;

  @HiveField(4)
  final int subtitleTextColor; // Store as int (Color.value)

  @HiveField(5)
  final double subtitleBackgroundOpacity;

  @HiveField(6)
  final bool subtitleHasShadow;

  @HiveField(7)
  final double subtitleShadowOpacity;

  @HiveField(8)
  final double subtitleShadowBlur;

  @HiveField(9)
  final String? subtitleFontFamily;

  @HiveField(10)
  final int subtitlePosition; // Store as int (0=top, 1=middle, 2=bottom)

  // Playback settings
  @HiveField(11)
  final double defaultPlaybackSpeed;

  @HiveField(12)
  final bool skipIntro;

  @HiveField(13)
  final bool skipOutro;

  @HiveField(14)
  final bool subtitleBoldText;

  @HiveField(15)
  final bool subtitleForceUppercase;

  @HiveField(16)
  final bool showRemainingTime;

  @HiveField(17)
  final bool showNextEpisodeAutoPlay;

  PlayerSettings({
    this.episodeCompletionThreshold = 0.9,
    this.autoPlayNextEpisode = true,
    this.preferSubtitles = true,
    this.subtitleFontSize = 16.0,
    this.subtitleTextColor = 0xFFFFFFFF, // Default white
    this.subtitleBackgroundOpacity = 0.6,
    this.subtitleHasShadow = true,
    this.subtitleShadowOpacity = 0.5,
    this.subtitleShadowBlur = 2.0,
    this.subtitleFontFamily,
    this.subtitlePosition = 2,
    this.defaultPlaybackSpeed = 1.0,
    this.skipIntro = true,
    this.skipOutro = true,
    this.subtitleBoldText = true,
    this.subtitleForceUppercase = false,
    this.showRemainingTime = true,
    this.showNextEpisodeAutoPlay = true,
  });

  // Convert to runtime SubtitleStyle
  SubtitleStyle toSubtitleStyle() {
    return SubtitleStyle(
      fontSize: subtitleFontSize,
      textColor: Color(subtitleTextColor),
      backgroundOpacity: subtitleBackgroundOpacity,
      hasShadow: subtitleHasShadow,
      shadowOpacity: subtitleShadowOpacity,
      shadowBlur: subtitleShadowBlur,
      fontFamily: subtitleFontFamily,
      position: subtitlePosition,
      boldText: subtitleBoldText,
      forceUppercase: subtitleForceUppercase,
    );
  }

  PlayerSettings copyWith({
    double? episodeCompletionThreshold,
    bool? autoPlayNextEpisode,
    bool? preferSubtitles,
    double? subtitleFontSize,
    int? subtitleTextColor,
    double? subtitleBackgroundOpacity,
    bool? subtitleHasShadow,
    double? subtitleShadowOpacity,
    double? subtitleShadowBlur,
    int? subtitlePosition,
    String? subtitleFontFamily,
    double? defaultPlaybackSpeed,
    bool? skipIntro,
    bool? skipOutro,
    bool? subtitleBoldText,
    bool? subtitleForceUppercase,
    bool? showRemainingTime,
    bool? showNextEpisodeAutoPlay,
  }) {
    return PlayerSettings(
      episodeCompletionThreshold:
          episodeCompletionThreshold ?? this.episodeCompletionThreshold,
      autoPlayNextEpisode: autoPlayNextEpisode ?? this.autoPlayNextEpisode,
      preferSubtitles: preferSubtitles ?? this.preferSubtitles,
      subtitleFontSize: subtitleFontSize ?? this.subtitleFontSize,
      subtitleTextColor: subtitleTextColor ?? this.subtitleTextColor,
      subtitleBackgroundOpacity:
          subtitleBackgroundOpacity ?? this.subtitleBackgroundOpacity,
      subtitleHasShadow: subtitleHasShadow ?? this.subtitleHasShadow,
      subtitleShadowOpacity:
          subtitleShadowOpacity ?? this.subtitleShadowOpacity,
      subtitleShadowBlur: subtitleShadowBlur ?? this.subtitleShadowBlur,
      subtitleFontFamily: subtitleFontFamily ?? this.subtitleFontFamily,
      subtitlePosition: subtitlePosition ?? this.subtitlePosition,
      defaultPlaybackSpeed: defaultPlaybackSpeed ?? this.defaultPlaybackSpeed,
      skipIntro: skipIntro ?? this.skipIntro,
      skipOutro: skipOutro ?? this.skipOutro,
      subtitleBoldText: subtitleBoldText ?? this.subtitleBoldText,
      subtitleForceUppercase:
          subtitleForceUppercase ?? this.subtitleForceUppercase,
      showRemainingTime: showRemainingTime ?? this.showRemainingTime,
      showNextEpisodeAutoPlay:
          showNextEpisodeAutoPlay ?? this.showNextEpisodeAutoPlay,
    );
  }
}
