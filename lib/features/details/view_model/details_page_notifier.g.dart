// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'details_page_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DetailsPageNotifier)
const detailsPageProvider = DetailsPageNotifierFamily._();

final class DetailsPageNotifierProvider
    extends $NotifierProvider<DetailsPageNotifier, DetailsPageState> {
  const DetailsPageNotifierProvider._({
    required DetailsPageNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'detailsPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$detailsPageNotifierHash();

  @override
  String toString() {
    return r'detailsPageProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DetailsPageNotifier create() => DetailsPageNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DetailsPageState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DetailsPageState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DetailsPageNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$detailsPageNotifierHash() =>
    r'1d8d9b391c96cd762a522d95f33637fb1c300bf7';

final class DetailsPageNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          DetailsPageNotifier,
          DetailsPageState,
          DetailsPageState,
          DetailsPageState,
          String
        > {
  const DetailsPageNotifierFamily._()
    : super(
        retry: null,
        name: r'detailsPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  DetailsPageNotifierProvider call(String animeId) =>
      DetailsPageNotifierProvider._(argument: animeId, from: this);

  @override
  String toString() => r'detailsPageProvider';
}

abstract class _$DetailsPageNotifier extends $Notifier<DetailsPageState> {
  late final _$args = ref.$arg as String;
  String get animeId => _$args;

  DetailsPageState build(String animeId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<DetailsPageState, DetailsPageState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DetailsPageState, DetailsPageState>,
              DetailsPageState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
