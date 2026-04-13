// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_search_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AnimeSearchNotifier)
const animeSearchProvider = AnimeSearchNotifierProvider._();

final class AnimeSearchNotifierProvider
    extends $NotifierProvider<AnimeSearchNotifier, AnimeSearchState> {
  const AnimeSearchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'animeSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$animeSearchNotifierHash();

  @$internal
  @override
  AnimeSearchNotifier create() => AnimeSearchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnimeSearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnimeSearchState>(value),
    );
  }
}

String _$animeSearchNotifierHash() =>
    r'abec0420f97798877f5e5a2c399c8f489117cc06';

abstract class _$AnimeSearchNotifier extends $Notifier<AnimeSearchState> {
  AnimeSearchState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AnimeSearchState, AnimeSearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AnimeSearchState, AnimeSearchState>,
              AnimeSearchState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
