import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/unified_media.dart';

enum CalendarSource {
  anilist,
  mal,
  simkl,
  kitsu;

  String get displayName => switch (this) {
    CalendarSource.anilist => 'AniList',
    CalendarSource.mal => 'MyAnimeList',
    CalendarSource.simkl => 'Simkl',
    CalendarSource.kitsu => 'Kitsu',
  };

  String get subtitle => switch (this) {
    CalendarSource.anilist => 'Live countdowns & airing episodes',
    CalendarSource.mal => 'Broadcast time slots & seasonal anime',
    CalendarSource.simkl => 'Anime, TV series & movie broadcast schedules',
    CalendarSource.kitsu => 'Currently airing seasonal anime',
  };

  IconData get icon => switch (this) {
    CalendarSource.anilist => Icons.timer_outlined,
    CalendarSource.mal => Icons.tv_rounded,
    CalendarSource.simkl => Icons.movie_filter_outlined,
    CalendarSource.kitsu => Icons.auto_awesome_outlined,
  };

  List<MediaType> get supportedMediaTypes => switch (this) {
    CalendarSource.anilist => const [MediaType.ANIME],
    CalendarSource.mal => const [MediaType.ANIME],
    CalendarSource.kitsu => const [MediaType.ANIME],
    CalendarSource.simkl => const [
      MediaType.ANIME,
      MediaType.TV,
      MediaType.MOVIE,
    ],
  };

  bool get supportsCountdowns => switch (this) {
    CalendarSource.anilist => true,
    CalendarSource.simkl => true,
    CalendarSource.mal => true,
    CalendarSource.kitsu => false,
  };
}
