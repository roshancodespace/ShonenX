// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_anime_sources.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fetchAnimeSourcesList)
const fetchAnimeSourcesListProvider = FetchAnimeSourcesListFamily._();

final class FetchAnimeSourcesListProvider
    extends $FunctionalProvider<AsyncValue<dynamic>, dynamic, FutureOr<dynamic>>
    with $FutureModifier<dynamic>, $FutureProvider<dynamic> {
  const FetchAnimeSourcesListProvider._({
    required FetchAnimeSourcesListFamily super.from,
    required ({int? id, bool reFresh}) super.argument,
  }) : super(
         retry: null,
         name: r'fetchAnimeSourcesListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchAnimeSourcesListHash();

  @override
  String toString() {
    return r'fetchAnimeSourcesListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<dynamic> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<dynamic> create(Ref ref) {
    final argument = this.argument as ({int? id, bool reFresh});
    return fetchAnimeSourcesList(
      ref,
      id: argument.id,
      reFresh: argument.reFresh,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FetchAnimeSourcesListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchAnimeSourcesListHash() =>
    r'51627e2c68f8552af3d62f133896e43d6664dae8';

final class FetchAnimeSourcesListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<dynamic>,
          ({int? id, bool reFresh})
        > {
  const FetchAnimeSourcesListFamily._()
    : super(
        retry: null,
        name: r'fetchAnimeSourcesListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchAnimeSourcesListProvider call({int? id, required bool reFresh}) =>
      FetchAnimeSourcesListProvider._(
        argument: (id: id, reFresh: reFresh),
        from: this,
      );

  @override
  String toString() => r'fetchAnimeSourcesListProvider';
}
