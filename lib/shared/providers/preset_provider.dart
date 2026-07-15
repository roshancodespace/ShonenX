import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/models/app_theme_preset.dart';
import 'package:shonenx/shared/models/built_in_presets.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class PresetState {
  final List<AppThemePreset> customPresets;
  final String? activePresetId;

  const PresetState({this.customPresets = const [], this.activePresetId});

  List<AppThemePreset> get allPresets => [
    ...BuiltInPresets.all,
    ...customPresets,
  ];

  AppThemePreset? get activePreset {
    if (activePresetId == null) return null;
    try {
      return allPresets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }

  PresetState copyWith({
    List<AppThemePreset>? customPresets,
    String? activePresetId,
    bool clearActivePresetId = false,
  }) {
    return PresetState(
      customPresets: customPresets ?? this.customPresets,
      activePresetId: clearActivePresetId
          ? null
          : (activePresetId ?? this.activePresetId),
    );
  }
}

class PresetNotifier extends Notifier<PresetState> {
  static const _presetsKey = 'app_custom_presets_list';

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  PresetState build() {
    final prefsJson = _storage.getString(_presetsKey);

    List<AppThemePreset> loaded = [];
    if (prefsJson != null) {
      try {
        final List<dynamic> list = jsonDecode(prefsJson) as List<dynamic>;
        loaded = list
            .map((item) => AppThemePreset.fromMap(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    return PresetState(customPresets: loaded, activePresetId: null);
  }

  void applyPreset(AppThemePreset preset) {
    // Apply to Theme preferences
    final themeNotifier = ref.read(themePrefsProvider.notifier);
    themeNotifier.updateTheme((current) => preset.applyToThemePrefs(current));

    // Apply to UI & Widget preferences including wide mode
    final uiNotifier = ref.read(uiPrefsProvider.notifier);
    uiNotifier.updateUiPrefs((current) => preset.applyToUiPrefs(current));

    // No tracking of active preset per user request (pure preset loader)
    state = state.copyWith(clearActivePresetId: true);
    _saveDb();
  }

  AppThemePreset saveCustomPreset({
    required String name,
    required String author,
    required String description,
    required List<int> previewColors,
  }) {
    final themePrefs = ref.read(themePrefsProvider);
    final uiPrefs = ref.read(uiPrefsProvider);

    final id = 'custom_theme_${DateTime.now().millisecondsSinceEpoch}';
    final newPreset = AppThemePreset.fromStates(
      id: id,
      name: name,
      description: description,
      author: author,
      previewColors: previewColors,
      themePrefs: themePrefs,
      uiPrefs: uiPrefs,
    );

    final updatedList = [...state.customPresets, newPreset];
    state = state.copyWith(
      customPresets: updatedList,
      clearActivePresetId: true,
    );
    _saveDb();
    return newPreset;
  }

  AppThemePreset importPresetFromJson(String jsonString, {bool apply = true}) {
    final preset = AppThemePreset.fromJsonString(jsonString);
    // Check if a preset with same ID exists, if so replace or generate new ID
    final existingIndex = state.customPresets.indexWhere(
      (p) => p.id == preset.id,
    );
    List<AppThemePreset> updatedList;
    if (existingIndex >= 0) {
      updatedList = [...state.customPresets];
      updatedList[existingIndex] = preset;
    } else {
      updatedList = [...state.customPresets, preset];
    }

    state = state.copyWith(customPresets: updatedList);
    if (apply) {
      applyPreset(preset);
    } else {
      _saveDb();
    }
    return preset;
  }

  void deleteCustomPreset(String id) {
    final updatedList = state.customPresets.where((p) => p.id != id).toList();
    state = state.copyWith(
      customPresets: updatedList,
      clearActivePresetId: state.activePresetId == id,
    );
    _saveDb();
  }

  void clearActivePresetMark() {
    if (state.activePresetId != null) {
      state = state.copyWith(clearActivePresetId: true);
    }
  }

  void _saveDb() {
    final jsonList = state.customPresets.map((p) => p.toMap()).toList();
    _storage.setString(_presetsKey, jsonEncode(jsonList));
    _storage.remove('app_active_preset_id');
  }
}

final presetProvider = NotifierProvider<PresetNotifier, PresetState>(
  PresetNotifier.new,
);
