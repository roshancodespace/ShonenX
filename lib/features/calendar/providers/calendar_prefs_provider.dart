import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/calendar/domain/models/calendar_source.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class CalendarPrefsState {
  final CalendarSource source;
  final MediaType mediaType;
  final bool onlyInLibrary;
  final bool hideAired;

  const CalendarPrefsState({
    this.source = CalendarSource.anilist,
    this.mediaType = MediaType.ANIME,
    this.onlyInLibrary = false,
    this.hideAired = false,
  });

  CalendarPrefsState copyWith({
    CalendarSource? source,
    MediaType? mediaType,
    bool? onlyInLibrary,
    bool? hideAired,
  }) {
    return CalendarPrefsState(
      source: source ?? this.source,
      mediaType: mediaType ?? this.mediaType,
      onlyInLibrary: onlyInLibrary ?? this.onlyInLibrary,
      hideAired: hideAired ?? this.hideAired,
    );
  }
}

class CalendarPrefsNotifier extends Notifier<CalendarPrefsState> {
  static const _keySource = 'calendar_source';
  static const _keyMediaType = 'calendar_media_type';
  static const _keyOnlyInLibrary = 'calendar_only_in_library';
  static const _keyHideAired = 'calendar_hide_aired';

  @override
  CalendarPrefsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final sourceName = prefs.getString(_keySource);
    final source = CalendarSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => CalendarSource.anilist,
    );

    final mediaTypeName = prefs.getString(_keyMediaType);
    MediaType mediaType = MediaType.ANIME;
    if (mediaTypeName != null) {
      try {
        mediaType = MediaType.values.firstWhere((t) => t.name == mediaTypeName);
      } catch (_) {}
    }
    if (!source.supportedMediaTypes.contains(mediaType)) {
      mediaType = source.supportedMediaTypes.first;
    }

    final onlyInLibrary = prefs.getBool(_keyOnlyInLibrary) ?? false;
    final hideAired = prefs.getBool(_keyHideAired) ?? false;

    return CalendarPrefsState(
      source: source,
      mediaType: mediaType,
      onlyInLibrary: onlyInLibrary,
      hideAired: hideAired,
    );
  }

  void setSource(CalendarSource source) {
    var mediaType = state.mediaType;
    if (!source.supportedMediaTypes.contains(mediaType)) {
      mediaType = source.supportedMediaTypes.first;
      ref
          .read(sharedPreferencesProvider)
          .setString(_keyMediaType, mediaType.name);
    }
    state = state.copyWith(source: source, mediaType: mediaType);
    ref.read(sharedPreferencesProvider).setString(_keySource, source.name);
  }

  void setMediaType(MediaType type) {
    if (!state.source.supportedMediaTypes.contains(type)) return;
    state = state.copyWith(mediaType: type);
    ref.read(sharedPreferencesProvider).setString(_keyMediaType, type.name);
  }

  void setOnlyInLibrary(bool value) {
    state = state.copyWith(onlyInLibrary: value);
    ref.read(sharedPreferencesProvider).setBool(_keyOnlyInLibrary, value);
  }

  void setHideAired(bool value) {
    state = state.copyWith(hideAired: value);
    ref.read(sharedPreferencesProvider).setBool(_keyHideAired, value);
  }
}

final calendarPrefsProvider =
    NotifierProvider<CalendarPrefsNotifier, CalendarPrefsState>(
      CalendarPrefsNotifier.new,
    );
