// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Details)
const detailsProvider = DetailsFamily._();

final class DetailsProvider
    extends $AsyncNotifierProvider<Details, UniversalMedia> {
  const DetailsProvider._({
    required DetailsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'detailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$detailsHash();

  @override
  String toString() {
    return r'detailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Details create() => Details();

  @override
  bool operator ==(Object other) {
    return other is DetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$detailsHash() => r'6a2c4996b260878659e21b1dbe89b96179c79d1b';

final class DetailsFamily extends $Family
    with
        $ClassFamilyOverride<
          Details,
          AsyncValue<UniversalMedia>,
          UniversalMedia,
          FutureOr<UniversalMedia>,
          int
        > {
  const DetailsFamily._()
    : super(
        retry: null,
        name: r'detailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DetailsProvider call(int animeId) =>
      DetailsProvider._(argument: animeId, from: this);

  @override
  String toString() => r'detailsProvider';
}

abstract class _$Details extends $AsyncNotifier<UniversalMedia> {
  late final _$args = ref.$arg as int;
  int get animeId => _$args;

  FutureOr<UniversalMedia> build(int animeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<UniversalMedia>, UniversalMedia>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UniversalMedia>, UniversalMedia>,
              AsyncValue<UniversalMedia>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
