import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shonenx/features/home/model/home_section.dart';
import 'package:shonenx/main.dart';

final homeLayoutProvider =
    NotifierProvider<HomeLayoutNotifier, List<HomeSection>>(
      HomeLayoutNotifier.new,
    );

class HomeLayoutNotifier extends Notifier<List<HomeSection>> {
  static const _boxName = 'home_layout';
  static const _hiveKey = 'settings';
  static const _prefsKey = 'home_layout_data';

  @override
  List<HomeSection> build() {
    return _load() ?? _defaults();
  }

  List<HomeSection>? _load() {
    final jsonString = sharedPrefs.getString(_prefsKey);
    if (jsonString != null) {
      try {
        final List<dynamic> list = json.decode(jsonString);
        return list.map((e) => HomeSection.fromJson(e)).toList();
      } catch (_) {}
    }

    if (Hive.isBoxOpen(_boxName)) {
      try {
        final box = Hive.box(_boxName);
        final List<dynamic>? data = box.get(_hiveKey);
        if (data != null) {
          final migrated = data
              .map((e) => HomeSection.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          _saveList(migrated);
          return migrated;
        }
      } catch (_) {}
    }
    return null;
  }

  void _save() {
    _saveList(state);
  }

  void _saveList(List<HomeSection> sections) {
    final data = sections.map((e) => e.toJson()).toList();
    sharedPrefs.setString(_prefsKey, json.encode(data));
  }

  void move(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = state.removeAt(oldIndex);
    state.insert(newIndex, item);
    state = [...state];
    _save();
  }

  void toggle(int index) {
    final item = state[index];
    final updated = item.copyWith(enabled: !item.enabled);
    state[index] = updated;
    state = [...state];
    _save();
  }

  void addWatchlistRow(String status) {
    final id = 'watchlist_${status.toLowerCase()}';
    if (state.any((e) => e.id == id)) return;

    final newSection = HomeSection(
      id: id,
      title: _formatStatus(status),
      type: HomeSectionType.watchlist,
      dataId: status,
    );
    state = [...state, newSection];
    _save();
  }

  void delete(int index) {
    state.removeAt(index);
    state = [...state];
    _save();
  }

  void reset() {
    state = _defaults();
    _save();
  }

  String _formatStatus(String status) {
    if (status.length <= 1) return status;
    return status[0].toUpperCase() +
        status.substring(1).toLowerCase().replaceAll('_', ' ');
  }

  List<HomeSection> _defaults() {
    return [
      const HomeSection(
        id: 'spotlight',
        title: 'Spotlight',
        type: HomeSectionType.spotlight,
      ),
      const HomeSection(
        id: 'continue_watching',
        title: 'Continue Watching',
        type: HomeSectionType.continueWatching,
      ),
      const HomeSection(
        id: 'trending',
        title: 'Trending Anime',
        type: HomeSectionType.standard,
        dataId: 'trending',
      ),
      const HomeSection(
        id: 'popular',
        title: 'Popular Anime',
        type: HomeSectionType.standard,
        dataId: 'popular',
      ),
      const HomeSection(
        id: 'most_favorite',
        title: 'Most Favorite',
        type: HomeSectionType.standard,
        dataId: 'most_favorite',
      ),
      const HomeSection(
        id: 'most_watched',
        title: 'Most Watched',
        type: HomeSectionType.standard,
        dataId: 'most_watched',
      ),
      const HomeSection(
        id: 'top_rated',
        title: 'Top Rated',
        type: HomeSectionType.standard,
        dataId: 'top_rated',
      ),
      const HomeSection(
        id: 'recently_updated',
        title: 'Recently Updated',
        type: HomeSectionType.standard,
        dataId: 'recently_updated',
      ),
      const HomeSection(
        id: 'upcoming',
        title: 'Upcoming',
        type: HomeSectionType.standard,
        dataId: 'upcoming',
      ),
    ];
  }
}
