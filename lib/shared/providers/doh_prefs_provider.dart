import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/doh/doh_provider.dart';
import 'package:shonenx/core/network/doh/doh_resolver.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

class DohPrefs {
  final DohProvider provider;

  const DohPrefs({this.provider = DohProvider.cloudflare});

  Map<String, dynamic> toJson() {
    return {'provider': provider.name};
  }

  factory DohPrefs.fromJson(Map<String, dynamic> json) {
    return DohPrefs(
      provider: DohProvider.values.firstWhere(
        (e) => e.name == json['provider'],
        orElse: () => DohProvider.cloudflare,
      ),
    );
  }

  DohPrefs copyWith({DohProvider? provider}) {
    return DohPrefs(provider: provider ?? this.provider);
  }
}

class DohPrefsNotifier extends Notifier<DohPrefs> {
  static const _keyPrefs = 'doh_prefs';

  @override
  DohPrefs build() {
    final storage = ref.watch(sharedPreferencesProvider);
    final jsonStr = storage.getString(_keyPrefs);
    DohPrefs prefs = const DohPrefs();

    if (jsonStr != null) {
      try {
        prefs = DohPrefs.fromJson(jsonDecode(jsonStr));
      } catch (_) {}
    }

    DohResolver.instance.setProvider(prefs.provider);

    return prefs;
  }

  Future<void> setProvider(DohProvider provider) async {
    state = state.copyWith(provider: provider);
    DohResolver.instance.setProvider(provider);
    await ref
        .read(sharedPreferencesProvider)
        .setString(_keyPrefs, jsonEncode(state.toJson()));
  }
}

final dohPrefsProvider = NotifierProvider<DohPrefsNotifier, DohPrefs>(
  () => DohPrefsNotifier(),
);
