import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';

enum ReaderDirection {
  webtoon,
  ltr,
  rtl;

  String get displayName {
    switch (this) {
      case ReaderDirection.webtoon:
        return 'Webtoon (Vertical)';
      case ReaderDirection.ltr:
        return 'Left to Right';
      case ReaderDirection.rtl:
        return 'Right to Left';
    }
  }
}

enum ReaderBackgroundColor {
  black,
  darkGrey,
  white;

  String get displayName {
    switch (this) {
      case ReaderBackgroundColor.black:
        return 'Black';
      case ReaderBackgroundColor.darkGrey:
        return 'Dark Grey';
      case ReaderBackgroundColor.white:
        return 'White';
    }
  }
}

enum ReaderScaleType {
  fitWidth,
  fitHeight,
  original;

  String get displayName {
    switch (this) {
      case ReaderScaleType.fitWidth:
        return 'Fit Width';
      case ReaderScaleType.fitHeight:
        return 'Fit Height';
      case ReaderScaleType.original:
        return 'Original Size';
    }
  }
}

enum ReaderTransition {
  slide,
  pageTurn;

  String get displayName {
    switch (this) {
      case ReaderTransition.slide:
        return 'Slide';
      case ReaderTransition.pageTurn:
        return 'Page Turn (Curl)';
    }
  }
}

class ReaderPrefState {
  final ReaderDirection direction;
  final ReaderBackgroundColor backgroundColor;
  final ReaderScaleType scaleType;
  final ReaderTransition transition;
  final bool showMiniStatus;
  final bool keepScreenOn;
  final bool tapToTurnPage;
  final double autoScrollSpeed;

  const ReaderPrefState({
    this.direction = ReaderDirection.webtoon,
    this.backgroundColor = ReaderBackgroundColor.black,
    this.scaleType = ReaderScaleType.fitWidth,
    this.transition = ReaderTransition.slide,
    this.showMiniStatus = true,
    this.keepScreenOn = true,
    this.tapToTurnPage = true,
    this.autoScrollSpeed = 1.0,
  });

  ReaderPrefState copyWith({
    ReaderDirection? direction,
    ReaderBackgroundColor? backgroundColor,
    ReaderScaleType? scaleType,
    ReaderTransition? transition,
    bool? showMiniStatus,
    bool? keepScreenOn,
    bool? tapToTurnPage,
    double? autoScrollSpeed,
  }) {
    return ReaderPrefState(
      direction: direction ?? this.direction,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      scaleType: scaleType ?? this.scaleType,
      transition: transition ?? this.transition,
      showMiniStatus: showMiniStatus ?? this.showMiniStatus,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      tapToTurnPage: tapToTurnPage ?? this.tapToTurnPage,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
    );
  }

  Map<String, dynamic> toJson() => {
    'direction': direction.name,
    'backgroundColor': backgroundColor.name,
    'scaleType': scaleType.name,
    'transition': transition.name,
    'showMiniStatus': showMiniStatus,
    'keepScreenOn': keepScreenOn,
    'tapToTurnPage': tapToTurnPage,
    'autoScrollSpeed': autoScrollSpeed,
  };

  factory ReaderPrefState.fromJson(Map<String, dynamic> json) {
    return ReaderPrefState(
      direction: ReaderDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => ReaderDirection.webtoon,
      ),
      backgroundColor: ReaderBackgroundColor.values.firstWhere(
        (e) => e.name == json['backgroundColor'],
        orElse: () => ReaderBackgroundColor.black,
      ),
      scaleType: ReaderScaleType.values.firstWhere(
        (e) => e.name == json['scaleType'],
        orElse: () => ReaderScaleType.fitWidth,
      ),
      transition: ReaderTransition.values.firstWhere(
        (e) => e.name == json['transition'],
        orElse: () => ReaderTransition.slide,
      ),
      showMiniStatus: json['showMiniStatus'] as bool? ?? true,
      keepScreenOn: json['keepScreenOn'] as bool? ?? true,
      tapToTurnPage: json['tapToTurnPage'] as bool? ?? true,
      autoScrollSpeed: (json['autoScrollSpeed'] as num?)?.toDouble() ?? 1.0,
    );
  }
}

class ReaderPrefsNotifier extends Notifier<ReaderPrefState> {
  static const _key = 'reader_preferences';
  Timer? _debounce;

  SharedPreferences get _storage => ref.read(sharedPreferencesProvider);

  @override
  ReaderPrefState build() {
    final json = _storage.getString(_key);
    if (json != null) {
      try {
        return ReaderPrefState.fromJson(jsonDecode(json));
      } catch (_) {}
    }
    return const ReaderPrefState();
  }

  void updateDirection(ReaderDirection direction) {
    state = state.copyWith(direction: direction);
    _saveDb();
  }

  void updateBackgroundColor(ReaderBackgroundColor color) {
    state = state.copyWith(backgroundColor: color);
    _saveDb();
  }

  void updateScaleType(ReaderScaleType type) {
    state = state.copyWith(scaleType: type);
    _saveDb();
  }

  void updateTransition(ReaderTransition transition) {
    state = state.copyWith(transition: transition);
    _saveDb();
  }

  void updateShowMiniStatus(bool show) {
    state = state.copyWith(showMiniStatus: show);
    _saveDb();
  }

  void updateKeepScreenOn(bool keep) {
    state = state.copyWith(keepScreenOn: keep);
    _saveDb();
  }

  void updateTapToTurnPage(bool tap) {
    state = state.copyWith(tapToTurnPage: tap);
    _saveDb();
  }

  void updateAutoScrollSpeed(double speed) {
    state = state.copyWith(autoScrollSpeed: speed);
    _saveDb();
  }

  void reset() {
    _storage.remove(_key);
    state = const ReaderPrefState();
  }

  void _saveDb() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final newValue = jsonEncode(state.toJson());
      if (_storage.getString(_key) != newValue) {
        _storage.setString(_key, newValue);
      }
    });
  }
}

final readerPrefsProvider =
    NotifierProvider<ReaderPrefsNotifier, ReaderPrefState>(
      ReaderPrefsNotifier.new,
    );
