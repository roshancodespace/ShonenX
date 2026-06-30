import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

final updatePrefsProvider = NotifierProvider<UpdatePrefsNotifier, UpdatePreferences>(
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

    _log.i('Checking for updates from $apiUrl (includePrerelease: ${prefs.includePrerelease})...');

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

      // Sort releases by published date descending (newest first)
      releases.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
      final latestRelease = releases.first;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      _log.i('Current version: $currentVersion, Latest release tag: ${latestRelease.tagName} (id: ${latestRelease.id})');

      // Compare versions
      final cmp = _compareVersions(latestRelease.tagName, currentVersion);
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
          _log.i('Same tag version but higher release ID (${latestRelease.id} > ${prefs.lastSeenReleaseId}).');
          return latestRelease;
        }
      } else {
        // App version is newer or equal to latest release tag. Record as seen.
        if (prefs.lastSeenReleaseId != latestRelease.id) {
          await _ref.read(updatePrefsProvider.notifier).setLastSeenReleaseId(latestRelease.id);
        }
      }
    } catch (e, st) {
      _log.e('Error while checking for updates', e, st);
    }

    return null;
  }

  int _compareVersions(String tag, String currentVersion) {
    final cleanTag = tag.trim().replaceFirst(RegExp(r'^v', caseSensitive: false), '');
    final cleanCurrent = currentVersion.trim().replaceFirst(RegExp(r'^v', caseSensitive: false), '');

    final tagParts = cleanTag.split('-');
    final currentParts = cleanCurrent.split('-');

    final tagMainAndBuild = tagParts[0].split('+');
    final currentMainAndBuild = currentParts[0].split('+');

    final tagNums = tagMainAndBuild[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentNums = currentMainAndBuild[0].split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      final a = i < tagNums.length ? tagNums[i] : 0;
      final b = i < currentNums.length ? currentNums[i] : 0;
      if (a > b) return 1;
      if (a < b) return -1;
    }

    // Main versions are equal. Check pre-release tags.
    final tagPre = tagParts.length > 1 ? tagParts.sublist(1).join('-').split('+')[0] : '';
    final currentPre = currentParts.length > 1 ? currentParts.sublist(1).join('-').split('+')[0] : '';

    if (tagPre.isEmpty && currentPre.isNotEmpty) return 1; // 2.0.0 > 2.0.0-alpha
    if (tagPre.isNotEmpty && currentPre.isEmpty) return -1; // 2.0.0-alpha < 2.0.0

    if (tagPre != currentPre) {
      final tagSegments = tagPre.split('.');
      final currentSegments = currentPre.split('.');
      final len = tagSegments.length > currentSegments.length ? tagSegments.length : currentSegments.length;
      for (var i = 0; i < len; i++) {
        final segA = i < tagSegments.length ? tagSegments[i] : '';
        final segB = i < currentSegments.length ? currentSegments[i] : '';
        final numA = int.tryParse(segA);
        final numB = int.tryParse(segB);
        if (numA != null && numB != null) {
          if (numA > numB) return 1;
          if (numA < numB) return -1;
        } else {
          final cmp = segA.compareTo(segB);
          if (cmp != 0) return cmp;
        }
      }
    }

    // Check build number (+number)
    final tagBuildStr = tag.contains('+') ? tag.split('+').last : (tagMainAndBuild.length > 1 ? tagMainAndBuild[1] : '');
    final currentBuildStr = currentVersion.contains('+') ? currentVersion.split('+').last : (currentMainAndBuild.length > 1 ? currentMainAndBuild[1] : '');
    final tagBuild = int.tryParse(tagBuildStr) ?? 0;
    final currentBuild = int.tryParse(currentBuildStr) ?? 0;
    if (tagBuild > currentBuild) return 1;
    if (tagBuild < currentBuild) return -1;

    return 0;
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
      releases.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
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

