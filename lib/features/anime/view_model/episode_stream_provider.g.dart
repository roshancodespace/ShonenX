// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_stream_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EpisodeData)
const episodeDataProvider = EpisodeDataProvider._();

final class EpisodeDataProvider
    extends $NotifierProvider<EpisodeData, EpisodeDataState> {
  const EpisodeDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'episodeDataProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$episodeDataHash();

  @$internal
  @override
  EpisodeData create() => EpisodeData();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EpisodeDataState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EpisodeDataState>(value),
    );
  }
}

String _$episodeDataHash() => r'b3c733ddc0dce3dd1f9b1d28f97b63bd364d1750';

abstract class _$EpisodeData extends $Notifier<EpisodeDataState> {
  EpisodeDataState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<EpisodeDataState, EpisodeDataState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EpisodeDataState, EpisodeDataState>,
              EpisodeDataState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
