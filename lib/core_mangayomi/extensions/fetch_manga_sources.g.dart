// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_manga_sources.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fetchMangaSourcesList)
const fetchMangaSourcesListProvider = FetchMangaSourcesListFamily._();

final class FetchMangaSourcesListProvider
    extends $FunctionalProvider<AsyncValue<dynamic>, dynamic, FutureOr<dynamic>>
    with $FutureModifier<dynamic>, $FutureProvider<dynamic> {
  const FetchMangaSourcesListProvider._({
    required FetchMangaSourcesListFamily super.from,
    required ({int? id, dynamic reFresh}) super.argument,
  }) : super(
         retry: null,
         name: r'fetchMangaSourcesListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchMangaSourcesListHash();

  @override
  String toString() {
    return r'fetchMangaSourcesListProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<dynamic> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<dynamic> create(Ref ref) {
    final argument = this.argument as ({int? id, dynamic reFresh});
    return fetchMangaSourcesList(
      ref,
      id: argument.id,
      reFresh: argument.reFresh,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FetchMangaSourcesListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchMangaSourcesListHash() =>
    r'54d62588a16e6912345a61c3574d807690acbc7c';

final class FetchMangaSourcesListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<dynamic>,
          ({int? id, dynamic reFresh})
        > {
  const FetchMangaSourcesListFamily._()
    : super(
        retry: null,
        name: r'fetchMangaSourcesListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchMangaSourcesListProvider call({int? id, required dynamic reFresh}) =>
      FetchMangaSourcesListProvider._(
        argument: (id: id, reFresh: reFresh),
        from: this,
      );

  @override
  String toString() => r'fetchMangaSourcesListProvider';
}
