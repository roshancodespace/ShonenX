// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AutomaticUpdates)
const automaticUpdatesProvider = AutomaticUpdatesProvider._();

final class AutomaticUpdatesProvider
    extends $NotifierProvider<AutomaticUpdates, bool> {
  const AutomaticUpdatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'automaticUpdatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$automaticUpdatesHash();

  @$internal
  @override
  AutomaticUpdates create() => AutomaticUpdates();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$automaticUpdatesHash() => r'c76382a89f587ce5a658cb18872162518d6a95a8';

abstract class _$AutomaticUpdates extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
