import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/discovery/presentation/widgets/media_card.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/notification_toggle.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';

class AboutTabWidget extends ConsumerWidget {
  final UnifiedMedia media;

  const AboutTabWidget({super.key, required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final hasTags = media.tags != null && media.tags!.isNotEmpty;
    final hasRelations = media.relations != null && media.relations!.isNotEmpty;

    final items = <Widget>[];

    if (media.airingAt != null) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _AiringBanner(
            mediaId: media.id,
            mediaTitle: media.title.availableTitle,
            airingAt: media.airingAt!,
            nextEpisode: media.nextEpisode,
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
              _RelationsList(relations: media.relations!),
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

class _AiringBanner extends StatelessWidget {
  final DateTime airingAt;
  final dynamic nextEpisode;
  final String mediaId;
  final String mediaTitle;

  const _AiringBanner({
    required this.airingAt,
    required this.nextEpisode,
    required this.mediaId,
    required this.mediaTitle,
  });

  @override
  Widget build(BuildContext context) {
    final episodeNum = nextEpisode is int ? nextEpisode : 1;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
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
                  'EPISODE $episodeNum',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
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
            ),
          ),
          if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
            NotificationToggle(
              type: 'airing',
              refId: mediaId,
              variant: 'ep_$episodeNum',
              title: mediaTitle,
              body: 'Episode $episodeNum airs soon!',
              scheduleTime: airingAt.subtract(const Duration(minutes: 15)),
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
    return Chip(
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
    );
  }
}

class _RelationsList extends ConsumerWidget {
  final List<UnifiedMedia> relations;

  const _RelationsList({required this.relations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    relations.removeWhere((e) => e.type != MediaType.ANIME);

    return SizedBox(
      height: style.layout.height,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: relations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final relation = relations[index];
          return MediaCard(
            tag: 'details-${relation.id}',
            title: relation.title.availableTitle,
            imageUrl: relation.cover ?? relation.banner ?? '',
            onTap: () => context.pushReplacement(
              '/details/${relation.type.id}?tag=details-${relation.id}',
              extra: relation,
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
