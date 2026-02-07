// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EpisodeListNotifier)
const episodeListProvider = EpisodeListNotifierProvider._();

final class EpisodeListNotifierProvider
    extends $NotifierProvider<EpisodeListNotifier, EpisodeListState> {
  const EpisodeListNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'episodeListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$episodeListNotifierHash();

  @$internal
  @override
  EpisodeListNotifier create() => EpisodeListNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EpisodeListState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EpisodeListState>(value),
    );
  }
}

String _$episodeListNotifierHash() =>
    r'd278253d8417a63e5f17db2c5011c09cd7527b87';

abstract class _$EpisodeListNotifier extends $Notifier<EpisodeListState> {
  EpisodeListState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<EpisodeListState, EpisodeListState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EpisodeListState, EpisodeListState>,
              EpisodeListState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
