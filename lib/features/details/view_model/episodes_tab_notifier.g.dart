// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episodes_tab_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EpisodesTabNotifier)
const episodesTabProvider = EpisodesTabNotifierFamily._();

final class EpisodesTabNotifierProvider
    extends $NotifierProvider<EpisodesTabNotifier, EpisodesTabState> {
  const EpisodesTabNotifierProvider._({
    required EpisodesTabNotifierFamily super.from,
    required UniversalTitle super.argument,
  }) : super(
         retry: null,
         name: r'episodesTabProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$episodesTabNotifierHash();

  @override
  String toString() {
    return r'episodesTabProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  EpisodesTabNotifier create() => EpisodesTabNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EpisodesTabState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EpisodesTabState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodesTabNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$episodesTabNotifierHash() =>
    r'176c6b03aba85f78406ed9b9b25809d6860f444d';

final class EpisodesTabNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          EpisodesTabNotifier,
          EpisodesTabState,
          EpisodesTabState,
          EpisodesTabState,
          UniversalTitle
        > {
  const EpisodesTabNotifierFamily._()
    : super(
        retry: null,
        name: r'episodesTabProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EpisodesTabNotifierProvider call(UniversalTitle mediaTitle) =>
      EpisodesTabNotifierProvider._(argument: mediaTitle, from: this);

  @override
  String toString() => r'episodesTabProvider';
}

abstract class _$EpisodesTabNotifier extends $Notifier<EpisodesTabState> {
  late final _$args = ref.$arg as UniversalTitle;
  UniversalTitle get mediaTitle => _$args;

  EpisodesTabState build(UniversalTitle mediaTitle);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<EpisodesTabState, EpisodesTabState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EpisodesTabState, EpisodesTabState>,
              EpisodesTabState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
