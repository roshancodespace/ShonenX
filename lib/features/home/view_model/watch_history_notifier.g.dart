// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_history_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(WatchHistoryNotifier)
const watchHistoryProvider = WatchHistoryNotifierProvider._();

final class WatchHistoryNotifierProvider
    extends $NotifierProvider<WatchHistoryNotifier, WatchHistoryState> {
  const WatchHistoryNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'watchHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$watchHistoryNotifierHash();

  @$internal
  @override
  WatchHistoryNotifier create() => WatchHistoryNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WatchHistoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WatchHistoryState>(value),
    );
  }
}

String _$watchHistoryNotifierHash() =>
    r'e6a8555adfd534a9368f6d1a9f64b8ea57efa530';

abstract class _$WatchHistoryNotifier extends $Notifier<WatchHistoryState> {
  WatchHistoryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<WatchHistoryState, WatchHistoryState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<WatchHistoryState, WatchHistoryState>,
              WatchHistoryState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(AnimeHistoryDetailNotifier)
const animeHistoryDetailProvider = AnimeHistoryDetailNotifierFamily._();

final class AnimeHistoryDetailNotifierProvider
    extends
        $NotifierProvider<AnimeHistoryDetailNotifier, AnimeHistoryDetailState> {
  const AnimeHistoryDetailNotifierProvider._({
    required AnimeHistoryDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'animeHistoryDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$animeHistoryDetailNotifierHash();

  @override
  String toString() {
    return r'animeHistoryDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AnimeHistoryDetailNotifier create() => AnimeHistoryDetailNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnimeHistoryDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnimeHistoryDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AnimeHistoryDetailNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$animeHistoryDetailNotifierHash() =>
    r'b8d8c9808ed4ac33ea977fc45c2bc28736a7781d';

final class AnimeHistoryDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          AnimeHistoryDetailNotifier,
          AnimeHistoryDetailState,
          AnimeHistoryDetailState,
          AnimeHistoryDetailState,
          String
        > {
  const AnimeHistoryDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'animeHistoryDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AnimeHistoryDetailNotifierProvider call(String animeId) =>
      AnimeHistoryDetailNotifierProvider._(argument: animeId, from: this);

  @override
  String toString() => r'animeHistoryDetailProvider';
}

abstract class _$AnimeHistoryDetailNotifier
    extends $Notifier<AnimeHistoryDetailState> {
  late final _$args = ref.$arg as String;
  String get animeId => _$args;

  AnimeHistoryDetailState build(String animeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref as $Ref<AnimeHistoryDetailState, AnimeHistoryDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnimeHistoryDetailState, AnimeHistoryDetailState>,
              AnimeHistoryDetailState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
