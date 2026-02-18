// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_match_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(animeMatchService)
const animeMatchServiceProvider = AnimeMatchServiceProvider._();

final class AnimeMatchServiceProvider
    extends
        $FunctionalProvider<
          AnimeMatchService,
          AnimeMatchService,
          AnimeMatchService
        >
    with $Provider<AnimeMatchService> {
  const AnimeMatchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'animeMatchServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$animeMatchServiceHash();

  @$internal
  @override
  $ProviderElement<AnimeMatchService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AnimeMatchService create(Ref ref) {
    return animeMatchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AnimeMatchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AnimeMatchService>(value),
    );
  }
}

String _$animeMatchServiceHash() => r'82e30054efa530a5a8bd90cb5976cea3ade60b4a';
