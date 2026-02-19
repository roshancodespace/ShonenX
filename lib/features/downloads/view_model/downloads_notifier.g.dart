// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'downloads_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DownloadsNotifier)
const downloadsProvider = DownloadsNotifierProvider._();

final class DownloadsNotifierProvider
    extends $NotifierProvider<DownloadsNotifier, DownloadsState> {
  const DownloadsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadsNotifierHash();

  @$internal
  @override
  DownloadsNotifier create() => DownloadsNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadsState>(value),
    );
  }
}

String _$downloadsNotifierHash() => r'f8c2867c04fdbde74324da7e3466eea56a542440';

abstract class _$DownloadsNotifier extends $Notifier<DownloadsState> {
  DownloadsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<DownloadsState, DownloadsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DownloadsState, DownloadsState>,
              DownloadsState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
