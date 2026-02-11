import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/settings/model/sync_settings_model.dart';
import 'package:shonenx/main.dart';

final syncSettingsProvider =
    NotifierProvider<SyncSettingsNotifier, SyncSettingsModel>(
      SyncSettingsNotifier.new,
    );

class SyncSettingsNotifier extends Notifier<SyncSettingsModel> {
  static const _prefsKey = 'sync_settings_data';

  @override
  SyncSettingsModel build() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      return SyncSettingsModel.fromJson(jsonString);
    }

    return _migrateFromLegacyKeys();
  }

  SyncSettingsModel _migrateFromLegacyKeys() {
    final legacyAnilist = sharedPrefs.getBool('tracking_sync_anilist');
    final legacyMal = sharedPrefs.getBool('tracking_sync_mal');
    final legacyAsk = sharedPrefs.getBool('tracking_ask_update_on_start');

    final hasLegacy =
        legacyAnilist != null || legacyMal != null || legacyAsk != null;

    if (!hasLegacy) {
      return _computeSmartDefaults();
    }

    final model = SyncSettingsModel(
      syncAnilist: legacyAnilist ?? true,
      syncMal: legacyMal ?? true,
      askBeforeSync: legacyAsk ?? false,
      localSync: true,
      syncMode: 'realtime',
      backgroundIntervalMinutes: 15,
    );

    sharedPrefs.setString(_prefsKey, model.toJson());

    sharedPrefs.remove('tracking_sync_anilist');
    sharedPrefs.remove('tracking_sync_mal');
    sharedPrefs.remove('tracking_ask_update_on_start');

    return model;
  }

  SyncSettingsModel _computeSmartDefaults() {
    final auth = ref.read(authProvider);

    final isAnilistLoggedIn = auth.isAniListAuthenticated;
    final isMalLoggedIn = auth.isMalAuthenticated;
    final hasCloudService = isAnilistLoggedIn || isMalLoggedIn;

    return SyncSettingsModel(
      syncAnilist: isAnilistLoggedIn,
      syncMal: isMalLoggedIn,
      localSync: !hasCloudService,
      syncMode: 'realtime',
      backgroundIntervalMinutes: 15,
      askBeforeSync: false,
    );
  }

  void updateSettings(SyncSettingsModel Function(SyncSettingsModel) updater) {
    state = updater(state);
    sharedPrefs.setString(_prefsKey, state.toJson());
  }

  bool get shouldSyncAnilist {
    final auth = ref.read(authProvider);
    return state.syncAnilist && auth.isAniListAuthenticated;
  }

  bool get shouldSyncMal {
    final auth = ref.read(authProvider);
    return state.syncMal && auth.isMalAuthenticated;
  }

  bool get shouldSyncLocal => state.localSync;

  bool get isRealtimeSync => state.syncMode == 'realtime';

  bool get isBackgroundSync => state.syncMode == 'background';

  bool get isManualSync => state.syncMode == 'manual';

  bool get hasAnySyncTarget =>
      shouldSyncAnilist || shouldSyncMal || shouldSyncLocal;
}
