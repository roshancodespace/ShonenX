import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class DiscoveryTrackerErrorInfo {
  final TrackerType trackerType;
  final Object error;
  final DateTime timestamp;
  final bool isAuto;
  final TrackerType? primaryTrackerType;

  const DiscoveryTrackerErrorInfo({
    required this.trackerType,
    required this.error,
    required this.timestamp,
    required this.isAuto,
    this.primaryTrackerType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveryTrackerErrorInfo &&
          runtimeType == other.runtimeType &&
          trackerType == other.trackerType &&
          isAuto == other.isAuto &&
          primaryTrackerType == other.primaryTrackerType;

  @override
  int get hashCode => Object.hash(trackerType, isAuto, primaryTrackerType);
}

class DiscoveryTrackerErrorNotifier
    extends Notifier<DiscoveryTrackerErrorInfo?> {
  @override
  DiscoveryTrackerErrorInfo? build() {
    // Reset tracker error whenever metadata source changes (e.g. user switches source)
    ref.listen(metadataSourceProvider, (previous, next) {
      if (previous?.type != next.type) {
        state = null;
      }
    });

    return null;
  }

  void reportError({
    required TrackerType trackerType,
    required Object error,
    required bool isAuto,
    TrackerType? primaryTrackerType,
  }) {
    if (state?.trackerType != trackerType || state?.isAuto != isAuto) {
      state = DiscoveryTrackerErrorInfo(
        trackerType: trackerType,
        error: error,
        timestamp: DateTime.now(),
        isAuto: isAuto,
        primaryTrackerType: primaryTrackerType,
      );
    }
  }

  void clear() {
    if (state != null) {
      state = null;
    }
  }
}

final discoveryTrackerErrorProvider =
    NotifierProvider<DiscoveryTrackerErrorNotifier, DiscoveryTrackerErrorInfo?>(
      DiscoveryTrackerErrorNotifier.new,
      name: 'discoveryTrackerErrorProvider',
    );
