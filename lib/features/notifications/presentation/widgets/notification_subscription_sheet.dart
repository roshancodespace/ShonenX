import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/features/discovery/presentation/widgets/sheets/manual_tracker_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/notifications/domain/models/airing_schedule.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/notifications/providers/airing_data_repository_provider.dart';
import 'package:shonenx/features/notifications/providers/notification_subscriptions_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

final _sheetScheduleProvider = FutureProvider.autoDispose
    .family<List<AiringSchedule>, UnifiedMedia>((ref, media) async {
      final args = MatchArgs(
        mediaTitle: media.title.availableTitle,
        type: media.type,
      );
      final prefs = await ref.watch(mediaPreferenceProvider(args).future);
      final discoveryPrefs = ref.read(discoveryPrefsProvider);
      final metadataSourceId =
          discoveryPrefs.metadataTrackerId ??
          ref.read(primaryTrackerProvider).type.id;
      final fallbackTrackerType =
          TrackerType.tryFromId(metadataSourceId) ?? TrackerType.anilist;

      final targetTrackerType =
          prefs.preferredAiringTracker ?? fallbackTrackerType;

      String targetId = media.id;
      final primaryTrackerType = ref.read(primaryTrackerProvider).type;

      if (prefs.manualAiringTrackerId != null) {
        targetId = prefs.manualAiringTrackerId!;
      } else if (targetTrackerType != primaryTrackerType) {
        if (targetTrackerType == TrackerType.myanimelist &&
            media.idMal != null) {
          targetId = media.idMal!;
        } else {
          final targetTrackerService = targetTrackerType.getTracker(ref);
          if (targetTrackerService is RemoteTracker) {
            try {
              final results = await targetTrackerService.searchMedia(
                media.title.availableTitle,
                type: media.type,
              );
              if (results.isNotEmpty) targetId = results.first.id;
            } catch (_) {}
          }
        }
      }

      final repo = ref.read(airingDataRepositoryProvider(targetTrackerType));
      try {
        final schedules = await repo.getAiringSchedule(targetId);
        return schedules
            .where((s) => s.airingAt.isAfter(DateTime.now()))
            .toList();
      } catch (_) {
        return [];
      }
    });

class NotificationSubscriptionSheet extends ConsumerStatefulWidget {
  final UnifiedMedia media;

  const NotificationSubscriptionSheet({super.key, required this.media});

  @override
  ConsumerState<NotificationSubscriptionSheet> createState() =>
      _NotificationSubscriptionSheetState();
}

class _NotificationSubscriptionSheetState
    extends ConsumerState<NotificationSubscriptionSheet> {
  late bool _isEnabled;
  late SubscriptionMode _mode;
  late int _offsetMinutes;
  AiringSchedule? _targetEpisode;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    final subType = widget.media.type == MediaType.MANGA
        ? SubscriptionType.mangaChapter
        : SubscriptionType.animeAiring;
    final subscription = ref
        .read(notificationSubscriptionsProvider.notifier)
        .getSubscription(subType, widget.media.id);

    _isEnabled = subscription?.isEnabled ?? false;
    _mode = subscription?.mode ?? SubscriptionMode.nextOnly;
    _offsetMinutes = subscription?.offsetMinutes ?? 0;

    if (_mode == SubscriptionMode.targetEpisode &&
        subscription?.upcomingIdentifier != null &&
        subscription?.upcomingTime != null) {
      final epString = subscription!.upcomingIdentifier!.replaceFirst(
        'ep_',
        '',
      );
      _targetEpisode = AiringSchedule(
        episode: int.tryParse(epString) ?? 0,
        airingAt: subscription.upcomingTime!,
      );
    }
  }

  void _save() {
    final provider = ref.read(notificationSubscriptionsProvider.notifier);

    final airingAt = widget.media.airingAt;
    final nextEpisode = widget.media.nextEpisode;
    final int? episodeNumber = nextEpisode is int ? nextEpisode : (null);

    final subType = widget.media.type == MediaType.MANGA
        ? SubscriptionType.mangaChapter
        : SubscriptionType.animeAiring;
    final existingSub = provider.getSubscription(subType, widget.media.id);

    final sub = NotificationSubscription()
      ..type = subType
      ..referenceId = widget.media.id
      ..title = widget.media.title.availableTitle
      ..image = widget.media.cover ?? widget.media.banner ?? ''
      ..isEnabled = _isEnabled
      ..mode = _mode
      ..offsetMinutes = _offsetMinutes
      ..upcomingIdentifier =
          _mode == SubscriptionMode.targetEpisode && _targetEpisode != null
          ? 'ep_${_targetEpisode!.episode}'
          : episodeNumber != null
          ? 'ep_$episodeNumber'
          : null
      ..upcomingTime =
          _mode == SubscriptionMode.targetEpisode && _targetEpisode != null
          ? _targetEpisode!.airingAt
          : airingAt;

    if (existingSub != null) {
      sub.id = existingSub.id;
      sub.createdAt = existingSub.createdAt;
    }

    provider.saveSubscription(sub);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAiringData =
        widget.media.airingAt != null && widget.media.nextEpisode != null;

    DateTime? getScheduledTime() {
      if (_mode == SubscriptionMode.targetEpisode && _targetEpisode != null) {
        return _targetEpisode!.airingAt.subtract(
          Duration(minutes: _offsetMinutes),
        );
      } else if (widget.media.airingAt != null) {
        return widget.media.airingAt!.subtract(
          Duration(minutes: _offsetMinutes),
        );
      }
      return null;
    }

    final scheduledTime = getScheduledTime();

    return AppBottomSheet(
      title: 'Notifications',
      actions: [
        Switch(
          value: _isEnabled,
          onChanged: (val) {
            setState(() => _isEnabled = val);
          },
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAiringData) ...[
            const SizedBox(height: 8),
            Text(
              'No upcoming release data found. If this is currently airing, your selected metadata source may not provide schedule data.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 16),

          Opacity(
            opacity: _isEnabled ? 1.0 : 0.5,
            child: IgnorePointer(
              ignoring: !_isEnabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription Mode',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<SubscriptionMode>(
                      segments: const [
                        ButtonSegment(
                          value: SubscriptionMode.nextOnly,
                          label: Text('Next'),
                          icon: Icon(Icons.skip_next),
                        ),
                        ButtonSegment(
                          value: SubscriptionMode.targetEpisode,
                          label: Text('Target'),
                          icon: Icon(Icons.my_location),
                        ),
                        ButtonSegment(
                          value: SubscriptionMode.entireSeason,
                          label: Text('Season'),
                          icon: Icon(Icons.all_inclusive),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (set) {
                        setState(() => _mode = set.first);
                      },
                      style: SegmentedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mode == SubscriptionMode.nextOnly
                        ? 'Reminds you only for the immediate next episode.'
                        : _mode == SubscriptionMode.targetEpisode
                        ? 'Stack up episodes and get notified when your target drops.'
                        : 'Reminds you whenever any new episode is announced.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  if (_mode == SubscriptionMode.targetEpisode) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Select Target',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 64,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final schedulesAsync = ref.watch(
                            _sheetScheduleProvider(widget.media),
                          );
                          return schedulesAsync.when(
                            data: (schedules) {
                              if (schedules.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No future schedules found',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                );
                              }
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: schedules.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final schedule = schedules[index];
                                  final isSelected =
                                      _targetEpisode?.episode ==
                                      schedule.episode;
                                  final daysUntil = schedule.airingAt
                                      .difference(DateTime.now())
                                      .inDays;

                                  return InkWell(
                                    onTap: () => setState(
                                      () => _targetEpisode = schedule,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withAlpha(100),
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Episode ${schedule.episode}',
                                            style: theme.textTheme.labelLarge
                                                ?.copyWith(
                                                  color: isSelected
                                                      ? theme
                                                            .colorScheme
                                                            .onPrimary
                                                      : theme
                                                            .colorScheme
                                                            .onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            daysUntil == 0
                                                ? 'Today'
                                                : 'in $daysUntil days',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: isSelected
                                                      ? theme
                                                            .colorScheme
                                                            .onPrimary
                                                            .withAlpha(200)
                                                      : theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, st) => Center(
                              child: Text(
                                'Failed to load schedules',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text(
                    'Reminder Timing',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('At airing time'),
                        selected: _offsetMinutes == 0,
                        onSelected: (val) {
                          if (val) setState(() => _offsetMinutes = 0);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('15m before'),
                        selected: _offsetMinutes == 15,
                        onSelected: (val) {
                          if (val) setState(() => _offsetMinutes = 15);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('1h before'),
                        selected: _offsetMinutes == 60,
                        onSelected: (val) {
                          if (val) setState(() => _offsetMinutes = 60);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Advanced Settings',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showAdvanced ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_showAdvanced) ...[
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, child) {
                final args = MatchArgs(
                  mediaTitle: widget.media.title.availableTitle,
                  type: widget.media.type,
                );
                final prefsAsync = ref.watch(mediaPreferenceProvider(args));
                final discoveryPrefs = ref.watch(discoveryPrefsProvider);
                final primaryTracker = ref.watch(primaryTrackerProvider);
                final metadataSourceId =
                    discoveryPrefs.metadataTrackerId ?? primaryTracker.type.id;
                final fallbackTracker =
                    TrackerType.tryFromId(metadataSourceId) ??
                    TrackerType.anilist;

                final tracker =
                    prefsAsync.value?.preferredAiringTracker ?? fallbackTracker;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<TrackerType>(
                      initialValue: tracker,
                      decoration: InputDecoration(
                        labelText: 'Airing Schedule Provider',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: TrackerType.anilist,
                          child: Text('AniList (Accurate)'),
                        ),
                        DropdownMenuItem(
                          value: TrackerType.myanimelist,
                          child: Text('MyAnimeList (Fallback)'),
                        ),
                        DropdownMenuItem(
                          value: TrackerType.kitsu,
                          child: Text('Kitsu'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref
                              .read(mediaPreferenceProvider(args).notifier)
                              .setPreferredAiringTracker(val);
                        }
                      },
                    ),
                    if (tracker != fallbackTracker) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            useRootNavigator: true,
                            builder: (_) => ManualTrackerMatchSheet(
                              mediaTitle: widget.media.title.availableTitle,
                              type: widget.media.type,
                              targetTracker: tracker,
                            ),
                          );
                        },
                        icon: const Icon(Icons.link),
                        label: const Text('Fix Match / Manually Match'),
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],

          if (_isEnabled && scheduledTime != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Next reminder scheduled for:\n${formatDateWithTime(scheduledTime)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed:
                  (_mode == SubscriptionMode.targetEpisode &&
                      _targetEpisode == null)
                  ? null
                  : _save,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  String formatDateWithTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
