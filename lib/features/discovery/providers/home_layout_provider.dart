import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/core/providers/storage_provider.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';

class UserHomeLayoutNotifier extends Notifier<List<HomeSection>> {
  static const _dataKey = 'home_layout_data';
  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  List<HomeSection> build() {
    final json = _storage.getStringList(_dataKey);

    if (json != null && json.isNotEmpty) {
      return json.map((e) => HomeSection.fromJson(e)).toList();
    }

    return const [
      HomeSection(
        id: '1',
        title: 'Trending Now',
        type: HomeSectionType.trending,
      ),
      HomeSection(
        id: '2',
        title: 'Continue Watching',
        type: HomeSectionType.continueWatching,
      ),
    ];
  }

  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    final list = [...state];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    state = list;
    _saveDb();
  }

  void addSection(HomeSection section) {
    state = [...state, section];
    _saveDb();
  }

  void removeSection(String id) {
    state = state.where((e) => e.id != id).toList();
    _saveDb();
  }

  void updateSection(HomeSection updated) {
    state = [
      for (final s in state)
        if (s.id == updated.id) updated else s,
    ];
    _saveDb();
  }

  void reset() {
    _storage.remove(_dataKey);
    state = build();
  }

  void _saveDb() {
    _storage.setStringList(_dataKey, state.map((e) => e.toJson()).toList());
  }
}

final userHomeLayoutProvider =
    NotifierProvider<UserHomeLayoutNotifier, List<HomeSection>>(
      UserHomeLayoutNotifier.new,
      name: 'userHomeLayoutProvider',
    );
