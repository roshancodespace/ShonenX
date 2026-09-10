import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/router/app_router.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/discovery_mode_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/discovery_tracker_error_provider.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class TrackerErrorSheet extends ConsumerWidget {
  final TrackerType? failedTracker;
  final Object? error;

  const TrackerErrorSheet({super.key, this.failedTracker, this.error});

  static Future<T?> show<T>(
    BuildContext context, {
    TrackerType? failedTracker,
    Object? error,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          TrackerErrorSheet(failedTracker: failedTracker, error: error),
    );
  }

  void _popAndNavigate(
    BuildContext context,
    void Function(BuildContext) navigate,
  ) {
    Navigator.of(context, rootNavigator: true).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        navigate(navContext);
      }
    });
  }

  void _switchSource({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onApply,
    required Widget icon,
    required String label,
    required double roundness,
  }) {
    onApply();
    ref.read(discoveryTrackerErrorProvider.notifier).clear();
    ref.invalidate(homeSectionFeedProvider);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text('Switched discovery source to $label'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(roundness),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildQuickChip({
    required BuildContext context,
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    required BorderRadius borderRadius,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: borderRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 7),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String extractErrorMessage(Object? error, String trackerName) {
    if (error == null) {
      return '$trackerName servers are unreachable. Feeds are paused until service is restored.';
    }

    final raw = error.toString();

    final msgMatch = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(raw);
    if (msgMatch != null) {
      final msg = msgMatch.group(1)?.trim();
      if (msg != null && msg.isNotEmpty && !msg.startsWith('HTTP')) {
        return msg;
      }
    }

    if (raw.contains('403')) {
      return '$trackerName API is temporarily disabled or unreachable (HTTP 403).';
    }
    if (raw.contains('502') || raw.contains('503') || raw.contains('504')) {
      return '$trackerName servers are experiencing high load or maintenance.';
    }
    if (raw.contains('timeout') || raw.contains('Timeout')) {
      return 'Connection to $trackerName timed out. Server may be down.';
    }
    if (raw.contains('Cloudflare')) {
      return '$trackerName is currently blocked by a Cloudflare challenge.';
    }

    return '$trackerName servers are unreachable. Pick an alternate discovery source below.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final r = ref.watch(themePrefsProvider.select((s) => s.uiRoundness));
    final cardRadius = BorderRadius.circular(r);
    final innerRadius = BorderRadius.circular(r * 0.75);
    final pillRadius = BorderRadius.circular(r * 0.5);

    final activeMetadataTracker = ref.watch(metadataSourceProvider);
    final trackerType = failedTracker ?? activeMetadataTracker.type;

    final prefs = ref.watch(discoveryPrefsProvider);
    final isAuto = prefs.metadataTrackerId == null;
    final primaryTracker = ref.watch(primaryTrackerProvider);
    final primaryType = primaryTracker.type;

    final otherTrackers = ref
        .watch(availableTrackersProvider)
        .where((t) => t.type != trackerType && t.type != TrackerType.local)
        .toList();

    final isSyncPaused = primaryType == trackerType;
    final isLocal = primaryType == TrackerType.local;
    final effectiveAutoType = isLocal ? TrackerType.anilist : primaryType;

    return AppBottomSheet(
      title: '${trackerType.displayName} Status',
      titleIcon: Icons.cloud_off_rounded,
      contentPadding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: cardRadius,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.4),
                      borderRadius: innerRadius,
                    ),
                    child: Center(
                      child: trackerType.getIconWidget(
                        size: 18,
                        color: cs.error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${trackerType.displayName} Unavailable',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: pillRadius,
                              ),
                              child: Text(
                                isAuto ? 'Auto' : 'Pinned',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          extractErrorMessage(error, trackerType.displayName),
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: cardRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 18,
                              color: cs.error,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.errorContainer.withValues(alpha: 0.7),
                                borderRadius: pillRadius,
                              ),
                              child: Text(
                                'Halted',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: cs.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Feeds Paused',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Trending and seasonal catalogs cannot load.',
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: cardRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              isSyncPaused
                                  ? Icons.pause_circle_outline_rounded
                                  : Icons.shield_outlined,
                              size: 18,
                              color: isSyncPaused ? cs.error : cs.tertiary,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isSyncPaused
                                            ? cs.errorContainer
                                            : cs.tertiaryContainer)
                                        .withValues(alpha: 0.7),
                                borderRadius: pillRadius,
                              ),
                              child: Text(
                                isSyncPaused
                                    ? 'Paused'
                                    : (isLocal ? 'Local Safe' : 'Active'),
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: isSyncPaused
                                      ? cs.onErrorContainer
                                      : cs.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Library Sync',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSyncPaused
                              ? 'Cloud sync paused until server recovers.'
                              : (isLocal
                                    ? 'On-device progress & library are 100% safe.'
                                    : 'Syncing to ${primaryType.displayName} normally.'),
                          style: textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: cardRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'SWITCH SOURCE',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Material(
                        color: Colors.transparent,
                        borderRadius: pillRadius,
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () =>
                              _popAndNavigate(context, DiscoveryModeSheet.show),
                          borderRadius: pillRadius,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 13,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'All Options',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!isAuto)
                        _buildQuickChip(
                          context: context,
                          borderRadius: innerRadius,
                          icon: Icon(
                            Icons.sync_rounded,
                            size: 16,
                            color: cs.primary,
                          ),
                          label: 'Auto (${effectiveAutoType.displayName})',
                          onTap: () => _switchSource(
                            context: context,
                            ref: ref,
                            onApply: () => ref
                                .read(discoveryPrefsProvider.notifier)
                                .setMetadataTrackerId(null),
                            icon: const Icon(
                              Icons.sync_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: 'Auto (${effectiveAutoType.displayName})',
                            roundness: r,
                          ),
                        ),
                      ...otherTrackers.map((t) {
                        final TrackerType type = t.type;
                        return _buildQuickChip(
                          context: context,
                          borderRadius: innerRadius,
                          icon: type.getIconWidget(size: 16, color: cs.primary),
                          label: type.displayName,
                          onTap: () => _switchSource(
                            context: context,
                            ref: ref,
                            onApply: () => ref
                                .read(discoveryPrefsProvider.notifier)
                                .setMetadataTrackerId(type.id),
                            icon: type.getIconWidget(
                              size: 18,
                              color: Colors.white,
                            ),
                            label: type.displayName,
                            roundness: r,
                          ),
                        );
                      }),
                      _buildQuickChip(
                        context: context,
                        borderRadius: innerRadius,
                        icon: Icon(
                          Icons.extension_rounded,
                          size: 16,
                          color: cs.secondary,
                        ),
                        label: 'Extensions',
                        onTap: () => _switchSource(
                          context: context,
                          ref: ref,
                          onApply: () => ref
                              .read(discoveryPrefsProvider.notifier)
                              .setMode(MetadataMode.source),
                          icon: const Icon(
                            Icons.extension_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: 'Extensions',
                          roundness: r,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: cardRadius,
              ),
              child: Row(
                children: [
                  Icon(Icons.sync_alt_rounded, size: 18, color: cs.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'In Auto mode, changing your primary account automatically switches discovery.',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _popAndNavigate(
                      context,
                      (c) => c.pushSettingsTracking(),
                    ),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: innerRadius),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Accounts',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(discoveryTrackerErrorProvider.notifier).clear();
                      ref.invalidate(homeSectionFeedProvider);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry Connection'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: cs.onSurfaceVariant,
                      shape: RoundedRectangleBorder(borderRadius: cardRadius),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: cardRadius),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
