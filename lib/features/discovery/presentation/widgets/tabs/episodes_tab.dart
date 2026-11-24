import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/router/app_navigator.dart';

import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/download_sheet.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_list_panel.dart';

import 'package:shonenx/features/discovery/presentation/widgets/sheets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/providers/history_provider.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_focus_hover.dart';
import 'package:shonenx/shared/widgets/source_selector_list.dart';
import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/core/widgets/cloudflare_webview.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';
import 'package:shonenx/features/comments/presentation/widgets/comments_tab.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';

bool _isReadable(MediaType type) =>
    type == MediaType.MANGA || type == MediaType.NOVEL;

String _formatNumber(num value) =>
    value.toInt() == value ? value.toInt().toString() : value.toString();

class EpisodesTabWidget extends ConsumerStatefulWidget {
  const EpisodesTabWidget({super.key, required this.media});

  final UnifiedMedia media;

  @override
  ConsumerState<EpisodesTabWidget> createState() => _EpisodesTabWidgetState();
}

class _EpisodesTabWidgetState extends ConsumerState<EpisodesTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool get _isReading => _isReadable(widget.media.type);

  String get _unitLabel => _isReading ? 'Chapter' : 'Episode';

  void _onEpisodeTap(UnifiedEpisode episode, SourceInfo sourceInfo) {
    final entries =
        ref.read(historyForMediaProvider(widget.media.id)).value ?? [];
    final entry = entries
        .where((e) => e.itemNumber == episode.number)
        .firstOrNull;

    if (_isReading) {
      final int startPosition;
      if (entry != null &&
          entry.progress > 0 &&
          entry.progress <= entry.total) {
        startPosition = entry.progress.toInt();
      } else {
        startPosition = 1;
      }

      context.pushReader(
        ReaderModeOnline(
          media: widget.media,
          episode: episode,
          sourceInfo: sourceInfo,
          startPosition: startPosition,
        ),
      );
      return;
    }

    final threshold = ref.read(trackingPrefsProvider).syncThreshold;
    final isFinished =
        entry != null &&
        entry.total > 0 &&
        entry.progress >= entry.total * threshold;

    final Duration? startPosition;
    if (entry != null && entry.progress > 0 && !isFinished) {
      startPosition = Duration(milliseconds: entry.progress.toInt());
    } else {
      startPosition = null;
    }

    context.pushPlayer(
      PlayerModeOnline(
        media: widget.media,
        episode: episode,
        sourceInfo: sourceInfo,
        startPosition: startPosition,
      ),
    );
  }

  void _openDiscussion(BuildContext sheetContext, UnifiedEpisode episode) {
    final epNum = episode.number.toInt();
    AppBottomSheet.show(
      context: sheetContext,
      title: '$_unitLabel $epNum Discussion',
      contentPadding: EdgeInsets.zero,
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.78,
        child: CommentsTabWidget(
          media: widget.media,
          initialEpisodeNumber: epNum,
        ),
      ),
    );
  }

  void _openEpisodeMenu(
    BuildContext sheetContext,
    UnifiedEpisode episode,
    List<SourceInfo> sources,
  ) {
    AppBottomSheet.show(
      context: sheetContext,
      title: '$_unitLabel ${_formatNumber(episode.number)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Discussion'),
            leading: const Icon(Icons.forum_rounded),
            onTap: () {
              sheetContext.pop();
              _openDiscussion(sheetContext, episode);
            },
          ),
          if (widget.media.type == MediaType.ANIME)
            ListTile(
              title: const Text('Stream / Download'),
              leading: const Icon(Icons.tune_rounded),
              onTap: () {
                sheetContext.pop();
                DownloadSheet.show(
                  context,
                  episode,
                  ref
                          .read(
                            mediaPreferenceProvider(
                              MediaArgs.fromMedia(widget.media),
                            ),
                          )
                          .value
                          ?.sourceInfo ??
                      sources.first,
                  widget.media,
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final cs = Theme.of(context).colorScheme;
    final sourcesAsync = ref.watch(widget.media.type.availableSourcesProvider);

    if (sourcesAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sources = sourcesAsync.value ?? [];

    if (sources.isEmpty) {
      return _NoExtensionsPlaceholder(mediaType: widget.media.type);
    }

    return Column(
      children: [
        if (widget.media.sourceId == null) ...[
          StaggeredFadeIn(
            index: 0,
            child: _EpisodesHeader(media: widget.media),
          ),
          Container(
            width: double.maxFinite,
            height: 1,
            color: cs.surfaceContainerHighest,
          ),
        ],
        Expanded(
          child: EpisodeListPanel(
            media: widget.media,
            useScrollController: false,
            onEpisodeTap: _onEpisodeTap,
            episodeActionsBuilder:
                (episodeActionsContext, episode, isCurrent, isWatched) {
                  return [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Discussion',
                      onPressed: () =>
                          _openDiscussion(episodeActionsContext, episode),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'More',
                      onPressed: () => _openEpisodeMenu(
                        episodeActionsContext,
                        episode,
                        sources,
                      ),
                      icon: const Icon(Icons.more_horiz_rounded),
                    ),
                  ];
                },
          ),
        ),
      ],
    );
  }
}

class _EpisodesHeader extends ConsumerWidget {
  final UnifiedMedia media;

  const _EpisodesHeader({required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final title = media.title.getPreferedTitle;

    final availableSources =
        ref.watch(media.type.availableSourcesProvider).value ?? [];

    if (availableSources.isEmpty) return const SizedBox.shrink();

    final matchArgs = MediaArgs.fromMedia(media);
    final sourceState = ref.watch(mediaPreferenceProvider(matchArgs)).value;
    final matchedMediaState = ref.watch(matchedMediaProvider(matchArgs));

    final activeSourceInfo =
        sourceState?.sourceInfo ?? matchedMediaState.value?.sourceInfo;
    final sourceName = activeSourceInfo?.name ?? 'Unknown';

    final isMatchingNewSource =
        sourceState != null &&
        matchedMediaState.value != null &&
        matchedMediaState.value!.sourceInfo.id != sourceState.sourceInfo.id;

    final bool hasError = matchedMediaState.hasError;
    final String matchedTitle;

    if (hasError) {
      matchedTitle = 'Failed to match';
    } else if (matchedMediaState.isLoading ||
        isMatchingNewSource ||
        (matchedMediaState.value?.isLoading ?? false)) {
      matchedTitle = 'Searching...';
    } else {
      matchedTitle =
          matchedMediaState.value?.matchedMedia?.title ?? 'No match found';
    }

    final String? sourceIconUrl = activeSourceInfo?.iconUrl;

    Widget fallbackIcon(IconData icon, Color color) =>
        Icon(icon, size: 18, color: color);

    final iconWidget = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: hasError ? cs.errorContainer : cs.secondaryContainer,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasError
          ? fallbackIcon(Icons.error_outline_rounded, cs.onErrorContainer)
          : (sourceIconUrl != null && sourceIconUrl.isNotEmpty)
          ? SmartImage(
              imageUrl: sourceIconUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => fallbackIcon(
                Icons.auto_awesome_rounded,
                cs.onSecondaryContainer,
              ),
            )
          : fallbackIcon(Icons.auto_awesome_rounded, cs.onSecondaryContainer),
    );

    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: hasError ? 'Error' : 'Matched',
                style: TextStyle(
                  color: hasError ? cs.error : cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' on $sourceName',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelMedium,
        ),
        Text(
          matchedTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: hasError ? cs.error : null,
          ),
        ),
      ],
    );

    final buttonsWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Source',
          onTap: () =>
              _showSourceSelector(context, ref, media, sourceState?.sourceInfo),
        ),
        const SizedBox(width: 8),
        if (activeSourceInfo?.baseUrl?.isNotEmpty == true) ...[
          _HeaderButton(
            icon: Icons.security_rounded,
            label: 'CF Bypass',
            onTap: () =>
                CloudflareWebView.open(context, activeSourceInfo!.baseUrl!),
          ),
          const SizedBox(width: 8),
        ],
        _HeaderButton(
          icon: Icons.help_outline_rounded,
          label: 'Fix',
          onTap: () {
            showModalBottomSheet(
              context: context,
              builder: (_) => ManualMatchSheet(
                mediaTitle: title,
                type: media.type,
                matchArgs: matchArgs,
              ),
            );
          },
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return Row(
              children: [
                iconWidget,
                const SizedBox(width: 12),
                Expanded(child: titleWidget),
                const SizedBox(width: 16),
                buttonsWidget,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Expanded(child: titleWidget),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: buttonsWidget,
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSourceSelector(
    BuildContext context,
    WidgetRef ref,
    UnifiedMedia media,
    SourceInfo? currentSource,
  ) {
    final availableSources =
        ref.read(media.type.availableSourcesProvider).value ?? [];

    AppBottomSheet.show(
      context: context,
      title: 'Select Source',
      child: SourceSelectorList(
        availableSources: availableSources,
        currentSource: currentSource,
        mediaType: media.type,
        onSourceSelected: (sheetContext, source) {
          final matchArgs = MediaArgs.fromMedia(media);
          ref
              .read(mediaPreferenceProvider(matchArgs).notifier)
              .updateSource(source);
          Navigator.pop(sheetContext);
        },
        onSettingsClosed: () {
          if (media.sourceId != null) {
            ref.invalidate(
              sourceEpisodesProvider((
                providerId: media.id,
                sourceId: media.sourceId!,
                sourceType: null,
                type: media.type,
              )),
            );
          }
        },
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppFocusHover(
      onTap: onTap,
      scaleFactor: 1.05,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;
        final foreground = active ? cs.onPrimary : cs.onSurfaceVariant;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: ShapeDecoration(
            color: active ? cs.primary : cs.surfaceContainerHighest,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NoExtensionsPlaceholder extends StatelessWidget {
  final MediaType mediaType;
  const _NoExtensionsPlaceholder({required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: cs.primaryContainer,
              ),
              child: Icon(
                Icons.extension_off_rounded,
                size: 30,
                color: cs.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No extensions installed',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isReadable(mediaType)
                  ? 'Install an extension to start reading chapters.'
                  : 'Install an extension to start streaming episodes.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => context.pushSettingsExtensions(),
              icon: const Icon(Icons.extension_rounded),
              label: const Text('Get extensions'),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
