// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(animeNewsNetworkService)
const animeNewsNetworkServiceProvider = AnimeNewsNetworkServiceProvider._();

final class AnimeNewsNetworkServiceProvider
    extends
        $FunctionalProvider<
          AnimeNewsNetworkService,
          AnimeNewsNetworkService,
          AnimeNewsNetworkService
        >
    with $Provider<AnimeNewsNetworkService> {
  const AnimeNewsNetworkServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'animeNewsNetworkServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$animeNewsNetworkServiceHash();

  @$internal
  @override
  $ProviderElement<AnimeNewsNetworkService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnimeNewsNetworkService create(Ref ref) {
    return animeNewsNetworkService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnimeNewsNetworkService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnimeNewsNetworkService>(value),
    );
  }
}

String _$animeNewsNetworkServiceHash() =>
    r'ffde2c859e43a69771620bbfd86b9ed4b19fd864';

@ProviderFor(News)
const newsProvider = NewsProvider._();

final class NewsProvider
    extends $AsyncNotifierProvider<News, List<UniversalNews>> {
  const NewsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'newsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$newsHash();

  @$internal
  @override
  News create() => News();
}

String _$newsHash() => r'8676bded78cf35661a68a18550e7396c0823efa1';

abstract class _$News extends $AsyncNotifier<List<UniversalNews>> {
  FutureOr<List<UniversalNews>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<List<UniversalNews>>, List<UniversalNews>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<UniversalNews>>, List<UniversalNews>>,
              AsyncValue<List<UniversalNews>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
