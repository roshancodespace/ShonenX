import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/updates/models/app_version.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/env.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class UpdatePreferences {
  final bool includePrerelease;
  final bool autoCheckOnStartup;
  final int? lastSeenReleaseId;
  final int? lastDismissedReleaseId;

  const UpdatePreferences({
    this.includePrerelease = false,
    this.autoCheckOnStartup = true,
    this.lastSeenReleaseId,
    this.lastDismissedReleaseId,
  });

  UpdatePreferences copyWith({
    bool? includePrerelease,
    bool? autoCheckOnStartup,
    int? lastSeenReleaseId,
    int? lastDismissedReleaseId,
    bool clearDismissed = false,
  }) {
    return UpdatePreferences(
      includePrerelease: includePrerelease ?? this.includePrerelease,
      autoCheckOnStartup: autoCheckOnStartup ?? this.autoCheckOnStartup,
      lastSeenReleaseId: lastSeenReleaseId ?? this.lastSeenReleaseId,
      lastDismissedReleaseId: clearDismissed
          ? null
          : (lastDismissedReleaseId ?? this.lastDismissedReleaseId),
    );
  }
}

class UpdatePrefsNotifier extends Notifier<UpdatePreferences> {
  static const _keyIncludePrerelease = 'update_include_prerelease';
  static const _keyAutoCheck = 'update_auto_check_startup';
  static const _keyLastSeenId = 'update_last_seen_release_id';
  static const _keyLastDismissedId = 'update_last_dismissed_release_id';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  UpdatePreferences build() {
    return UpdatePreferences(
      includePrerelease: _prefs.getBool(_keyIncludePrerelease) ?? false,
      autoCheckOnStartup: _prefs.getBool(_keyAutoCheck) ?? true,
      lastSeenReleaseId: _prefs.getInt(_keyLastSeenId),
      lastDismissedReleaseId: _prefs.getInt(_keyLastDismissedId),
    );
  }

  Future<void> setIncludePrerelease(bool value) async {
    await _prefs.setBool(_keyIncludePrerelease, value);
    state = state.copyWith(includePrerelease: value, clearDismissed: true);
  }

  Future<void> setAutoCheckOnStartup(bool value) async {
    await _prefs.setBool(_keyAutoCheck, value);
    state = state.copyWith(autoCheckOnStartup: value);
  }

  Future<void> setLastSeenReleaseId(int id) async {
    await _prefs.setInt(_keyLastSeenId, id);
    state = state.copyWith(lastSeenReleaseId: id);
  }

  Future<void> setLastDismissedReleaseId(int id) async {
    await _prefs.setInt(_keyLastDismissedId, id);
    state = state.copyWith(lastDismissedReleaseId: id);
  }
}

final updatePrefsProvider =
    NotifierProvider<UpdatePrefsNotifier, UpdatePreferences>(
      UpdatePrefsNotifier.new,
    );

class UpdateService {
  final Ref _ref;
  final _log = AppLogger.scope('UpdateService');

  UpdateService(this._ref);

  Future<GitHubRelease?> checkForUpdate({bool force = false}) async {
    final repo = Env.RELEASE_REPO.trim();
    if (repo.isEmpty) {
      _log.w('Env.RELEASE_REPO is not configured.');
      return null;
    }

    final prefs = _ref.read(updatePrefsProvider);
    final apiUrl = 'https://api.github.com/repos/$repo/releases';

    _log.i(
      'Checking for updates from $apiUrl (includePrerelease: ${prefs.includePrerelease})...',
    );

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ShonenX-App',
        },
      );

      if (response.statusCode != 200) {
        _log.w('Failed to fetch releases. Status code: ${response.statusCode}');
        return null;
      }

      final List<dynamic> data = jsonDecode(response.body);
      final releases = data
          .map((item) => GitHubRelease.fromJson(item as Map<String, dynamic>))
          .where((r) => !r.draft)
          .where((r) => prefs.includePrerelease || !r.prerelease)
          .toList();

      if (releases.isEmpty) {
        _log.i('No suitable releases found on GitHub.');
        return null;
      }

      // Sort releases by Version descending (highest version first), then date, then ID
      releases.sort((a, b) {
        final verA = AppVersion.parse(a.tagName);
        final verB = AppVersion.parse(b.tagName);
        final cmp = verB.compareTo(verA);
        if (cmp != 0) return cmp;
        final dateCmp = b.publishedAt.compareTo(a.publishedAt);
        if (dateCmp != 0) return dateCmp;
        return b.id.compareTo(a.id);
      });
      final latestRelease = releases.first;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersionStr =
          '${packageInfo.version}+${packageInfo.buildNumber}';
      final currentVersion = AppVersion.parse(currentVersionStr);
      final latestVersion = AppVersion.parse(latestRelease.tagName);

      _log.i(
        'Current version: $currentVersionStr ($currentVersion), Latest release tag: ${latestRelease.tagName} ($latestVersion, id: ${latestRelease.id})',
      );

      // Compare versions
      final cmp = latestVersion.compareTo(currentVersion);
      if (cmp > 0) {
        // Tag version is strictly newer
        if (!force && latestRelease.id == prefs.lastDismissedReleaseId) {
          _log.i('Release ${latestRelease.tagName} was previously dismissed.');
          return null;
        }
        return latestRelease;
      } else if (cmp == 0) {
        // Version string matches or couldn't be distinguished by string alone.
        // Compare release ID with stored last seen/installed ID.
        if (prefs.lastSeenReleaseId != null &&
            latestRelease.id != prefs.lastSeenReleaseId &&
            latestRelease.id != prefs.lastDismissedReleaseId &&
            latestRelease.id > prefs.lastSeenReleaseId!) {
          if (!force && latestRelease.id == prefs.lastDismissedReleaseId) {
            return null;
          }
          _log.i(
            'Same tag version but higher release ID (${latestRelease.id} > ${prefs.lastSeenReleaseId}).',
          );
          return latestRelease;
        }
      } else {
        // App version is newer or equal to latest release tag. Record as seen.
        if (prefs.lastSeenReleaseId != latestRelease.id) {
          await _ref
              .read(updatePrefsProvider.notifier)
              .setLastSeenReleaseId(latestRelease.id);
        }
      }
    } catch (e, st) {
      _log.e('Error while checking for updates', e, st);
    }

    return null;
  }

  static int compareVersions(String tag, String currentVersion) {
    return AppVersion.compare(tag, currentVersion);
  }

  Future<List<GitHubRelease>> fetchAllReleases() async {
    final repo = Env.RELEASE_REPO.trim();
    if (repo.isEmpty) return [];
    final apiUrl = 'https://api.github.com/repos/$repo/releases';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ShonenX-App',
        },
      );
      if (response.statusCode != 200) return [];
      final List<dynamic> data = jsonDecode(response.body);
      final releases = data
          .map((item) => GitHubRelease.fromJson(item as Map<String, dynamic>))
          .where((r) => !r.draft)
          .toList();
      releases.sort((a, b) {
        final verA = AppVersion.parse(a.tagName);
        final verB = AppVersion.parse(b.tagName);
        final cmp = verB.compareTo(verA);
        if (cmp != 0) return cmp;
        return b.publishedAt.compareTo(a.publishedAt);
      });
      return releases;
    } catch (e, st) {
      _log.e('Error fetching all releases', e, st);
      return [];
    }
  }
}

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref);
});

final releasesListProvider = FutureProvider<List<GitHubRelease>>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.fetchAllReleases();
});
