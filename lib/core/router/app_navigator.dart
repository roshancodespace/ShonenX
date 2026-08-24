import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/domain/models/search_filter_options.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/core/services/backup_service.dart';

extension AppNavigator on BuildContext {
  // Splash & Onboarding & Home
  void goHome() => go('/home');
  void goOnboarding() => go('/onboarding');
  void pushPendingLink(String link) => push(link);

  // Settings
  void pushSettings() => push('/settings');
  void pushSettingsDownloads() => push('/settings/downloads');
  void pushSettingsPermissions() => push('/settings/permissions');
  void pushSettingsNotifications() => push('/settings/notifications');
  void pushSettingsTracking() => push('/settings/tracking');
  void pushSettingsExtensions({
    String? autoAddUrl,
    String? autoAddType,
    String? autoAddManager,
  }) {
    final queryParams = <String, String>{};
    if (autoAddUrl != null) queryParams['autoAddUrl'] = autoAddUrl;
    if (autoAddType != null) queryParams['autoAddType'] = autoAddType;
    if (autoAddManager != null) queryParams['autoAddManager'] = autoAddManager;

    final uri = Uri(
      path: '/settings/extensions',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    push(uri.toString());
  }

  void pushSettingsExtensionsTest() => push('/settings/extensions/test');
  void pushSettingsRemoteConfigEditor() =>
      push('/settings/remote_config_editor');
  void pushSettingsContent() => push('/settings/content');
  void pushSettingsTheme() => push('/settings/theme');
  void pushSettingsHome() => push('/settings/home');
  void pushSettingsPlayer() => push('/settings/player');
  void pushSettingsReader() => push('/settings/reader');
  void pushSettingsCache() => push('/settings/cache');
  void pushSettingsUi() => push('/settings/ui');
  void pushSettingsBackup() => push('/settings/backup');
  void pushSettingsBackupPreview(BackupManifest manifest) =>
      push('/settings/backup/preview', extra: manifest);
  void pushSettingsTroubleshoot() => push('/settings/troubleshoot');
  void pushSettingsDebug() => push('/settings/debug');
  void pushSettingsLogs() => push('/settings/logs');
  void pushSettingsUpdates() => push('/settings/updates');
  void pushSettingsAbout() => push('/settings/about');
  void pushSettingsDiscord() => push('/settings/discord');

  // Details
  void pushDetails({
    required MediaType mediaType,
    required UnifiedMedia media,
    int initialTabIndex = 0,
    Object? autoPlayMode,
    String tag = 'details',
  }) {
    push(
      '/details/${mediaType.id}?tag=$tag',
      extra: {
        'media': media,
        'initialTabIndex': initialTabIndex,
        'autoPlayMode': autoPlayMode,
      },
    );
  }

  // Player & Reader
  void pushPlayer(PlayerMode mode) => push('/player', extra: mode);
  void pushReader(ReaderModeOnline mode) => push('/reader', extra: mode);

  // Discover & Library
  void pushLibrary() => push('/library');
  void pushDiscover({
    String? query,
    String? source,
    MediaType? type,
    List<String>? genres,
    List<String>? tags,
    String? category,
    SearchSort? sort,
    SearchStatusFilter? status,
    SearchFormatFilter? format,
  }) {
    final queryParams = <String, dynamic>{};
    if (query != null) queryParams['query'] = query;
    if (source != null) queryParams['source'] = source;
    if (type != null) queryParams['type'] = type.id;
    if (genres != null && genres.isNotEmpty) queryParams['genres'] = genres;
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags;
    if (category != null) queryParams['category'] = category;
    if (sort != null && sort != SearchSort.popularity) {
      queryParams['sort'] = sort.name;
    }
    if (status != null && status != SearchStatusFilter.all) {
      queryParams['status'] = status.name;
    }
    if (format != null && format != SearchFormatFilter.all) {
      queryParams['format'] = format.name;
    }

    // If filters/category are present, push to results screen so Back pops it
    final hasFilters =
        query != null ||
        source != null ||
        (genres != null && genres.isNotEmpty) ||
        (tags != null && tags.isNotEmpty) ||
        category != null ||
        sort != null ||
        status != null ||
        format != null;
    final path = hasFilters ? '/discover/results' : '/discover';

    final uri = Uri(
      path: path,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    push(uri.toString());
  }

  void pushFilteredDiscover({
    String? query,
    String? source,
    MediaType? type,
    List<String>? genres,
    List<String>? tags,
    String? category,
    String? title,
    SearchSort? sort,
    SearchStatusFilter? status,
    SearchFormatFilter? format,
  }) {
    final queryParams = <String, dynamic>{};
    if (query != null) queryParams['query'] = query;
    if (source != null) queryParams['source'] = source;
    if (type != null) queryParams['type'] = type.id;
    if (genres != null && genres.isNotEmpty) queryParams['genres'] = genres;
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags;
    if (category != null) queryParams['category'] = category;
    if (title != null) queryParams['title'] = title;
    if (sort != null && sort != SearchSort.popularity) {
      queryParams['sort'] = sort.name;
    }
    if (status != null && status != SearchStatusFilter.all) {
      queryParams['status'] = status.name;
    }
    if (format != null && format != SearchFormatFilter.all) {
      queryParams['format'] = format.name;
    }

    final uri = Uri(
      path: '/discover/results',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    push(uri.toString());
  }

  void goDiscover({
    String? query,
    String? source,
    MediaType? type,
    List<String>? genres,
    List<String>? tags,
    String? category,
  }) {
    final queryParams = <String, dynamic>{};
    if (query != null) queryParams['query'] = query;
    if (source != null) queryParams['source'] = source;
    if (type != null) queryParams['type'] = type.id;
    if (genres != null && genres.isNotEmpty) queryParams['genres'] = genres;
    if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags;
    if (category != null) queryParams['category'] = category;

    final uri = Uri(
      path: '/discover',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    go(uri.toString());
  }

  // Downloads
  void pushDownloads() => push('/downloads');

  // History / Continue
  void pushContinueHistory(MediaType type) => push('/continue/${type.id}');
  void pushContinueHistoryItem(MediaType type, String mediaId) =>
      push('/continue/${type.id}/$mediaId');
}
