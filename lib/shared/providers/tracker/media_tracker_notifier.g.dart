// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_tracker_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MediaTracker)
const mediaTrackerProvider = MediaTrackerFamily._();

final class MediaTrackerProvider
    extends $NotifierProvider<MediaTracker, TrackerState> {
  const MediaTrackerProvider._({
    required MediaTrackerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mediaTrackerProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mediaTrackerHash();

  @override
  String toString() {
    return r'mediaTrackerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MediaTracker create() => MediaTracker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrackerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrackerState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MediaTrackerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mediaTrackerHash() => r'9350c92684e2946cd67b1760774dd81052490e01';

final class MediaTrackerFamily extends $Family
    with
        $ClassFamilyOverride<
          MediaTracker,
          TrackerState,
          TrackerState,
          TrackerState,
          String
        > {
  const MediaTrackerFamily._()
    : super(
        retry: null,
        name: r'mediaTrackerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  MediaTrackerProvider call(String mediaId) =>
      MediaTrackerProvider._(argument: mediaId, from: this);

  @override
  String toString() => r'mediaTrackerProvider';
}

abstract class _$MediaTracker extends $Notifier<TrackerState> {
  late final _$args = ref.$arg as String;
  String get mediaId => _$args;

  TrackerState build(String mediaId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<TrackerState, TrackerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrackerState, TrackerState>,
              TrackerState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
