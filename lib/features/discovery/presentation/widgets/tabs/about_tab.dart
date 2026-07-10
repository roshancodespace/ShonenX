import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/notifications/presentation/widgets/notification_subscription_sheet.dart';
import 'package:shonenx/features/notifications/providers/notification_subscriptions_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';

class AboutTabWidget extends ConsumerWidget {
  final UnifiedMedia media;
  final VoidCallback? onEpisodesTabRequested;
  final double uiRoundness;

  const AboutTabWidget({
    super.key,
    required this.media,
    this.onEpisodesTabRequested,
    required this.uiRoundness,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final hasTags = media.tags != null && media.tags!.isNotEmpty;
    final hasRelations = media.relations != null && media.relations!.isNotEmpty;
    final hasRecommendations =
        media.recommendations != null && media.recommendations!.isNotEmpty;

    final items = <Widget>[];

    if (media.airingAt != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _AiringBanner(
            media: media,
            onEpisodesTabRequested: onEpisodesTabRequested,
            uiRoundness: uiRoundness,
          ),
        ),
      );
    }

    items.add(Synopsis(description: media.description ?? ''));

    if (hasTags) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tags', style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 4.0,
                runSpacing: 4.0,
                children: media.tags!
                    .map((tag) => _TagChip(label: tag.name))
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }

    if (hasRelations) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Relations', style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              _RelationsList(
                relations: media.relations!,
                parentType: media.type,
              ),
            ],
          ),
        ),
      );
    }

    if (hasRecommendations) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommendations', style: textTheme.headlineSmall),
              const SizedBox(height: 12),
              _RecommendationsList(recommendations: media.recommendations!),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return StaggeredFadeIn(index: index, child: items[index]);
      },
    );
  }
}

class _AiringBanner extends ConsumerWidget {
  final UnifiedMedia media;
  final double uiRoundness;
  final VoidCallback? onEpisodesTabRequested;

  const _AiringBanner({
    required this.media,
    this.onEpisodesTabRequested,
    required this.uiRoundness,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final airingAt = media.airingAt!;
    final nextEpisode = media.nextEpisode;
    final episodeNum = nextEpisode is int ? nextEpisode : (1);
    final theme = Theme.of(context);

    final subType = media.type == MediaType.MANGA
        ? SubscriptionType.mangaChapter
        : SubscriptionType.animeAiring;

    final map = ref.watch(notificationSubscriptionsProvider);
    final subscription = map['${subType.name}_${media.id}'];

    final bool isMissed =
        subscription != null &&
        subscription.isEnabled &&
        subscription.upcomingTime != null &&
        subscription.upcomingTime!.isBefore(DateTime.now());

    final isManga = media.type == MediaType.MANGA;
    final itemText = isManga ? 'Chapter' : 'Episode';
    final tabText = isManga ? 'Chapters' : 'Episodes';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(uiRoundness),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.timer_outlined,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${itemText.toUpperCase()} $episodeNum',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (isMissed) ...[
                  Text(
                    'You missed the notification for $itemText $episodeNum',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      if (onEpisodesTabRequested != null) {
                        onEpisodesTabRequested!();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please check the $tabText tab for the latest release.',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Open $tabText tab →',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ] else ...[
                  RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      children: [
                        const TextSpan(text: 'Airing in '),
                        TextSpan(
                          text: formatCountdown(airingAt),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
            InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                final notifier = ref.read(
                  notificationSubscriptionsProvider.notifier,
                );
                await notifier.toggleSubscription(media);
                final sub = notifier.getSubscription(subType, media.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  if (sub != null && sub.isEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Subscribed to ${itemText} $episodeNum. You will be notified when it drops.',
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications disabled.')),
                    );
                  }
                }
              },
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      NotificationSubscriptionSheet(media: media),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  subscription?.isEnabled == true
                      ? (subscription!.mode == SubscriptionMode.entireSeason
                            ? Icons.notifications_active
                            : Icons.notifications)
                      : Icons.notifications_outlined,
                  color: subscription?.isEnabled == true
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ActionChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      labelPadding: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      label: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      onPressed: () {
        context.go('/discover?tags=${Uri.encodeComponent(label)}');
      },
    );
  }
}

class _RelationsList extends ConsumerWidget {
  final List<UnifiedMedia> relations;
  final MediaType parentType;

  const _RelationsList({required this.relations, required this.parentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    final Map<String, List<UnifiedMedia>> grouped = {};
    for (final relation in relations) {
      if (relation.type != parentType) continue;

      final type = relation.relationType ?? 'Other';
      final formattedType = type
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (s) => s.isEmpty
                ? ''
                : s[0].toUpperCase() + s.substring(1).toLowerCase(),
          )
          .join(' ');

      grouped.putIfAbsent(formattedType, () => []).add(relation);
    }

    if (grouped.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: style.layout.height,
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: entry.value.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final relation = entry.value[index];
                    return MediaCard(
                      tag: 'details-${relation.id}',
                      title: relation.title.availableTitle,
                      format: relation.format,
                      imageUrl: relation.cover ?? relation.banner ?? '',
                      onTap: () => context.pushReplacement(
                        '/details/${relation.type.id}?tag=details-${relation.id}',
                        extra: relation,
                      ),
                      style: style,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _RecommendationsList extends ConsumerWidget {
  final List<UnifiedMedia> recommendations;

  const _RecommendationsList({required this.recommendations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));

    return SizedBox(
      height: style.layout.height,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: recommendations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return MediaCard(
            tag: 'details-rec-${rec.id}',
            title: rec.title.availableTitle,
            format: rec.format,
            imageUrl: rec.cover ?? rec.banner ?? '',
            onTap: () => context.pushReplacement(
              '/details/${rec.type.id}?tag=details-rec-${rec.id}',
              extra: rec,
            ),
            style: style,
          );
        },
      ),
    );
  }
}

class Synopsis extends StatefulWidget {
  final String description;
  final double collapsedHeight;
  final bool isLoading;

  const Synopsis({
    super.key,
    required this.description,
    this.collapsedHeight = 150,
    this.isLoading = false,
  });

  @override
  State<Synopsis> createState() => _SynopsisState();
}

class _SynopsisState extends State<Synopsis>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  static final _brRegex = RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false);
  static final _bOpenRegex = RegExp(r'<\s*b\s*>', caseSensitive: false);
  static final _bCloseRegex = RegExp(r'<\s*/\s*b\s*>', caseSensitive: false);
  static final _boldTagRegex = RegExp(r'<b>(.*?)</b>', dotAll: true);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Synopsis', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (widget.isLoading)
          const _SynopsisSkeleton()
        else ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  _isExpanded
                      ? Colors.transparent
                      : theme.scaffoldBackgroundColor,
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ).createShader(bounds),
              blendMode: BlendMode.dstOut,
              child: ConstrainedBox(
                constraints: _isExpanded
                    ? const BoxConstraints()
                    : BoxConstraints(maxHeight: widget.collapsedHeight),
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.5,
                      overflow: TextOverflow.fade,
                    ),
                    children: _descriptionSpans(widget.description, context),
                  ),
                ),
              ),
            ),
          ),
          if (widget.description.length > 200)
            TextButton(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(_isExpanded ? 'Show Less' : 'Read More'),
            ),
        ],
      ],
    );
  }

  List<TextSpan> _descriptionSpans(String text, BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium!;
    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.bold);

    final spans = <TextSpan>[];

    String cleanText = text
        .replaceAll(_brRegex, '\n')
        .replaceAll(_bOpenRegex, '<b>')
        .replaceAll(_bCloseRegex, '</b>');

    int lastIndex = 0;

    for (final match in _boldTagRegex.allMatches(cleanText)) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: cleanText.substring(lastIndex, match.start),
            style: baseStyle,
          ),
        );
      }

      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      lastIndex = match.end;
    }

    if (lastIndex < cleanText.length) {
      spans.add(
        TextSpan(text: cleanText.substring(lastIndex), style: baseStyle),
      );
    }

    return spans;
  }
}

class _SynopsisSkeleton extends StatelessWidget {
  const _SynopsisSkeleton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final skeletonColor = colorScheme.surfaceContainerHigh.withValues(
      alpha: 0.5,
    );

    Widget buildLine(double width) => Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: skeletonColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildLine(double.infinity),
        const SizedBox(height: 8),
        buildLine(double.infinity),
        const SizedBox(height: 8),
        buildLine(MediaQuery.sizeOf(context).width * 0.6),
      ],
    );
  }
}
