import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/discord/models/discord_rpc_custom_settings.dart';
import 'package:shonenx/features/discord/providers/discord_provider.dart';
import 'package:shonenx/features/discord/services/discord_rpc_service.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class DiscordRpcState {
  final bool isEnabled;
  final bool isConnected;
  final DiscordRpcCustomSettings customSettings;

  const DiscordRpcState({
    this.isEnabled = true,
    this.isConnected = false,
    this.customSettings = const DiscordRpcCustomSettings(),
  });

  DiscordRpcState copyWith({
    bool? isEnabled,
    bool? isConnected,
    DiscordRpcCustomSettings? customSettings,
  }) {
    return DiscordRpcState(
      isEnabled: isEnabled ?? this.isEnabled,
      isConnected: isConnected ?? this.isConnected,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

final discordRpcProvider =
    NotifierProvider<DiscordRpcNotifier, DiscordRpcState>(
      DiscordRpcNotifier.new,
    );

class DiscordRpcNotifier extends Notifier<DiscordRpcState>
    with WidgetsBindingObserver {
  static const _enabledKey = 'discord_rpc_enabled';
  static const _customSettingsKey = 'discord_rpc_custom_settings';

  final _log = AppLogger.scope(DiscordRpcNotifier);
  final _rpcService = DiscordRpcService();

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  DiscordRpcState build() {
    WidgetsBinding.instance.addObserver(this);

    ref.listen<DiscordState>(discordProvider, (previous, next) {
      if (next.isLoggedIn && state.isEnabled) {
        _log.i('Discord user logged in, initiating RPC connection');
        _connect(next.token!);
      } else if (!next.isLoggedIn) {
        _log.i('Discord user logged out, disconnecting RPC');
        _rpcService.disconnect();
        state = state.copyWith(isConnected: false);
      }
    });

    final isEnabled = _prefs.getBool(_enabledKey) ?? true;
    final rawCustomSettings = _prefs.getString(_customSettingsKey);
    DiscordRpcCustomSettings customSettings = const DiscordRpcCustomSettings();

    if (rawCustomSettings != null) {
      try {
        customSettings = DiscordRpcCustomSettings.fromJson(
          jsonDecode(rawCustomSettings) as Map<String, dynamic>,
        );
      } catch (e, s) {
        _log.w('Failed to parse custom RPC settings', e, s);
      }
    }

    _initConnection(isEnabled);

    return DiscordRpcState(
      isEnabled: isEnabled,
      customSettings: customSettings,
    );
  }

  Future<void> _initConnection(bool enabled) async {
    if (!enabled) return;
    _rpcService.resetPresenceState();
    final discordState = ref.read(discordProvider);
    if (discordState.isLoggedIn && discordState.token != null) {
      await _connect(discordState.token!);
      await updateBrowsingPresence();
    }
  }

  Future<void> _connect(String token) async {
    await _rpcService.connect(token);
    state = state.copyWith(isConnected: _rpcService.isConnected);
  }

  Future<void> _ensureConnected() async {
    if (_rpcService.isConnected) return;
    final discordState = ref.read(discordProvider);
    if (discordState.isLoggedIn && discordState.token != null) {
      await _connect(discordState.token!);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (!state.isEnabled) return;
    final discordState = ref.read(discordProvider);
    if (!discordState.isLoggedIn || discordState.token == null) return;

    if (appState == AppLifecycleState.resumed && !_rpcService.isConnected) {
      _log.i('App resumed, reconnecting Discord RPC');
      _connect(discordState.token!);
    }
  }

  Future<void> toggleEnabled(bool value) async {
    _log.i('Toggled Discord RPC enabled: $value');
    await _prefs.setBool(_enabledKey, value);
    state = state.copyWith(isEnabled: value);

    if (value) {
      final discordState = ref.read(discordProvider);
      if (discordState.isLoggedIn && discordState.token != null) {
        await _connect(discordState.token!);
      }
    } else {
      await _rpcService.clearPresence();
      await _rpcService.disconnect();
      state = state.copyWith(isConnected: false);
    }
  }

  Future<void> updateCustomSettings(
    DiscordRpcCustomSettings newSettings,
  ) async {
    _log.i('Updating custom RPC settings');
    state = state.copyWith(customSettings: newSettings);
    await _prefs.setString(
      _customSettingsKey,
      jsonEncode(newSettings.toJson()),
    );
    if (state.isConnected) {
      await updateBrowsingPresence();
    }
  }

  Future<void> updateBrowsingPresence({
    String? activity,
    String? details,
  }) async {
    if (!state.isEnabled) return;
    await _ensureConnected();
    await _rpcService.updateBrowsingPresence(
      activity: activity ?? state.customSettings.idleActivity,
      details: details ?? state.customSettings.idleDetails,
    );
    state = state.copyWith(isConnected: _rpcService.isConnected);
  }

  Future<void> updateMediaPresence(UnifiedMedia media) async {
    if (!state.isEnabled) return;
    if (!state.customSettings.enableDetailsPresence) return;
    await _ensureConnected();
    await _rpcService.updateMediaPresence(media: media);
    state = state.copyWith(isConnected: _rpcService.isConnected);
  }

  Future<void> updateAnimePresence({
    required UnifiedMedia anime,
    required int episodeNumber,
    String? episodeTitle,
    int? timeStampMs,
    int? durationMs,
    int? totalEpisodes,
  }) async {
    if (!state.isEnabled) return;
    if (!state.customSettings.enablePlayerPresence) return;
    await _ensureConnected();
    await _rpcService.updateAnimePresence(
      anime: anime,
      episodeNumber: episodeNumber,
      episodeTitle: episodeTitle,
      timeStampMs: timeStampMs,
      durationMs: durationMs,
      totalEpisodes: totalEpisodes,
    );
    state = state.copyWith(isConnected: _rpcService.isConnected);
  }

  Future<void> updateAnimePresencePaused({
    required UnifiedMedia anime,
    required int episodeNumber,
    int? timeStampMs,
    int? durationMs,
  }) async {
    if (!state.isEnabled) return;
    if (!state.customSettings.enablePlayerPresence) return;
    await _ensureConnected();
    await _rpcService.updateAnimePresencePaused(
      anime: anime,
      episodeNumber: episodeNumber,
      timeStampMs: timeStampMs,
      durationMs: durationMs,
    );
    state = state.copyWith(isConnected: _rpcService.isConnected);
  }

  Future<void> updateMangaPresence({
    required UnifiedMedia manga,
    int? chapterNumber,
    String? chapterTitle,
    int? currentPage,
    int? totalPages,
    int? totalChapters,
  }) async {
    if (!state.isEnabled) return;
    if (!state.customSettings.enableReaderPresence) return;
    await _ensureConnected();
    await _rpcService.updateMangaPresence(
      manga: manga,
      chapterNumber: chapterNumber,
      chapterTitle: chapterTitle,
      currentPage: currentPage,
      totalPages: totalPages,
      totalChapters: totalChapters,
    );
    state = state.copyWith(isConnected: _rpcService.isConnected);
  }

  Future<void> clearPresence() async {
    await _rpcService.clearPresence();
  }
}
