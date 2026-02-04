// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_novel_sources.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fetchNovelSourcesList)
const fetchNovelSourcesListProvider = FetchNovelSourcesListFamily._();

final class FetchNovelSourcesListProvider
    extends $FunctionalProvider<AsyncValue<dynamic>, dynamic, FutureOr<dynamic>>
    with $FutureModifier<dynamic>, $FutureProvider<dynamic> {
  const FetchNovelSourcesListProvider._({
    required FetchNovelSourcesListFamily super.from,
    required ({int? id, dynamic reFresh}) super.argument,
  }) : super(
         retry: null,
         name: r'fetchNovelSourcesListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fetchNovelSourcesListHash();

  @override
  String toString() {
    return r'fetchNovelSourcesListProvider'
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
    return fetchNovelSourcesList(
      ref,
      id: argument.id,
      reFresh: argument.reFresh,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FetchNovelSourcesListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fetchNovelSourcesListHash() =>
    r'61c23a61a11d46e20f96d75de29854f11b641c7f';

final class FetchNovelSourcesListFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<dynamic>,
          ({int? id, dynamic reFresh})
        > {
  const FetchNovelSourcesListFamily._()
    : super(
        retry: null,
        name: r'fetchNovelSourcesListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FetchNovelSourcesListProvider call({int? id, required dynamic reFresh}) =>
      FetchNovelSourcesListProvider._(
        argument: (id: id, reFresh: reFresh),
        from: this,
      );

  @override
  String toString() => r'fetchNovelSourcesListProvider';
}
