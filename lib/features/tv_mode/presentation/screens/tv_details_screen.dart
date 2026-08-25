import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/providers/details_provider.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/tracking/domain/isar_tracker_link.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_manager_sheet.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/features/tv_mode/presentation/tv_scale.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_episode_shelf.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_smart_image.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/source_selector_list.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

class TvDetailsScreen extends ConsumerStatefulWidget {
  final UnifiedMedia media;
  final String tag;

  const TvDetailsScreen({super.key, required this.media, required this.tag});

  @override
  ConsumerState<TvDetailsScreen> createState() => _TvDetailsScreenState();
}

class _TvDetailsScreenState extends ConsumerState<TvDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLinkPrimaryTracker();
    });
  }

  Future<void> _autoLinkPrimaryTracker() async {
    final prefs = ref.read(trackingPrefsProvider);
    if (!prefs.autoTrackPrimary) return;

    final primaryType = prefs.primaryTracker;
    if (primaryType == TrackerType.local) return;

    final media = widget.media;
    final trackingId = resolveTrackingIdFromMedia(
      trackerType: primaryType,
      media: media,
    );

    if (trackingId == null || trackingId.isEmpty) return;

    final linksMap = await ref.read(trackerLinkProvider(media.id).future);
    if (linksMap.containsKey(primaryType)) return;

    final mapping = TrackerMapping()
      ..trackerId = primaryType.id
      ..trackingId = trackingId
      ..trackingTitle = media.title.availableTitle;

    ref
        .read(trackerLinkProvider(media.id).notifier)
        .saveLink(primaryType, mapping);
  }

  void _openSourceSelector(
    BuildContext context,
    UnifiedMedia media,
    List<SourceInfo> availableSources,
    SourceInfo? currentSource,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Select Source',
      child: SourceSelectorList(
        availableSources: availableSources,
        currentSource: currentSource,
        mediaType: media.type,
        onSourceSelected: (ctx, source) {
          final matchArgs = MediaArgs.fromMedia(media);
          ref
              .read(mediaPreferenceProvider(matchArgs).notifier)
              .updateSource(source);
          ref.invalidate(matchedMediaProvider(matchArgs));
          ref.invalidate(episodesListProvider(matchArgs));
          Navigator.pop(ctx);
        },
        onSettingsClosed: () {
          final matchArgs = MediaArgs.fromMedia(media);
          ref.invalidate(matchedMediaProvider(matchArgs));
          ref.invalidate(episodesListProvider(matchArgs));
        },
      ),
    );
  }

  void _openTrackerManager(BuildContext context, UnifiedMedia media) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackerManagerSheet(media: media),
    );
  }

  void _handlePrimaryPlay(
    BuildContext context,
    UnifiedMedia media,
    WidgetRef ref,
  ) {
    final matchArgs = MediaArgs.fromMedia(media);
    final episodesData = ref.read(episodesListProvider(matchArgs)).value;
    final episodes = episodesData?.episodes ?? [];
    final source = episodesData?.source;

    if (episodes.isEmpty || source == null) return;

    final watchHistoryEntries =
        ref.read(historyEpisodesProvider(media.id)).value ?? [];
    final readHistoryEntries =
        ref.read(historyChaptersProvider(media.id)).value ?? [];

    final currentEpisodeNumber = media.type == MediaType.ANIME
        ? watchHistoryEntries.firstOrNull?.episodeNumber
        : readHistoryEntries.firstOrNull?.chapterNumber;

    final targetEpisode = (currentEpisodeNumber != null
        ? episodes.firstWhere(
            (e) => e.number == currentEpisodeNumber,
            orElse: () => episodes.first,
          )
        : episodes.first);

    if (media.type == MediaType.MANGA || media.type == MediaType.NOVEL) {
      final historyEntry = readHistoryEntries.firstOrNull;

      final startPos =
          (historyEntry != null &&
              historyEntry.positionPage > 0 &&
              historyEntry.positionPage <= historyEntry.totalPages)
          ? historyEntry.positionPage
          : 1;

      context.pushReader(
        ReaderModeOnline(
          media: media,
          episode: targetEpisode,
          sourceInfo: source,
          startPosition: startPos,
        ),
      );
    } else {
      context.pushPlayer(
        PlayerModeOnline(
          media: media,
          episode: targetEpisode,
          sourceInfo: source,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final scale = context.tvScale;
    final size = MediaQuery.sizeOf(context);
    final cardStyle = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    final uiRoundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );
    final isWide = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(cardStyle.name)),
    );
    final sectionHeight = cardStyle.getLayout(isWideMode: isWide).height;

    final detailsArgs = DetailsArgs(
      widget.media.id,
      widget.media.type,
      sourceId: widget.media.sourceId,
      trackerId: widget.media.providerId,
    );

    final detailsAsync = ref.watch(detailsProvider(detailsArgs));
    final media = detailsAsync.value?.merge(widget.media) ?? widget.media;

    final matchArgs = MediaArgs.fromMedia(media);
    final episodesData = ref.watch(episodesListProvider(matchArgs)).value;
    final activeSource = episodesData?.source;
    final availableSources =
        ref.watch(media.type.availableSourcesProvider).value ?? [];

    final primaryTracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(primaryTracker.type, media)),
    );
    final trackerLinksAsync = ref.watch(trackerLinkProvider(media.id));
    final trackerLinks = trackerLinksAsync.value ?? {};
    final trackingId =
        trackerLinks[primaryTracker.type]?.trackingId ??
        resolveTrackingIdFromMedia(
          trackerType: primaryTracker.type,
          media: media,
          links: trackerLinks,
        );
    final isTrackerLinked =
        trackingId != null || primaryTracker.type == TrackerType.local;
    final isAuthenticated = primaryTracker.type.isAuthenticated(ref);
    final listItem = trackingState.value;

    String trackingLabel = 'Add to List';
    IconData trackingIcon = Icons.bookmark_add_outlined;

    if (!isAuthenticated && primaryTracker is RemoteTracker) {
      trackingLabel = 'Login to ${primaryTracker.type.displayName}';
      trackingIcon = Icons.login_rounded;
    } else if (isTrackerLinked) {
      if (listItem != null) {
        final epPrefix = media.type == MediaType.MANGA ? 'Ch' : 'Ep';
        final statusLabel = listItem.status.getLabelForMedia(media.type);
        trackingLabel = '$epPrefix ${listItem.progress.toInt()} • $statusLabel';
        trackingIcon = Icons.bookmark_added_rounded;
      } else {
        trackingLabel = 'Add to ${primaryTracker.type.displayName}';
        trackingIcon = Icons.bookmark_add_outlined;
      }
    } else if (trackerLinks.isNotEmpty) {
      trackingLabel = 'Manage Trackers';
      trackingIcon = Icons.bookmarks_rounded;
    }

    final watchHistoryEntries =
        ref.watch(historyEpisodesProvider(media.id)).value ?? [];
    final readHistoryEntries =
        ref.watch(historyChaptersProvider(media.id)).value ?? [];

    final currentEpisodeNumber = media.type == MediaType.ANIME
        ? watchHistoryEntries.firstOrNull?.episodeNumber
        : readHistoryEntries.firstOrNull?.chapterNumber;

    final backdrop = media.banner ?? media.cover ?? '';
    final poster = media.cover ?? '';
    final title = media.title.availableTitle;
    final score = media.score;
    final format = media.format;
    final year = media.season;
    final status = media.status;
    final description = media.description ?? '';
    final genres = media.genres ?? [];

    final relations = media.relations ?? [];
    final recommendations = media.recommendations ?? [];

    final horizontalPad = (36.0 * scale).clamp(28.0, 68.0);
    final posterWidth = (130.0 * scale).clamp(110.0, 175.0);
    final posterHeight = (195.0 * scale).clamp(165.0, 260.0);

    final posterRadius = BorderRadius.circular(uiRoundness);
    final badgeRadius = BorderRadius.circular(
      (uiRoundness * 0.4).clamp(4.0, 8.0),
    );
    final buttonRadius = BorderRadius.circular(
      (uiRoundness * 0.6).clamp(6.0, 14.0),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (backdrop.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.72,
              child: ClipRect(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.25, 0.60, 0.88, 1.0],
                      colors: [
                        Colors.white,
                        Colors.white,
                        Color(0x66FFFFFF),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.0, 0.35, 0.75, 1.0],
                        colors: [
                          Colors.transparent,
                          Color(0x44FFFFFF),
                          Colors.white,
                          Colors.white,
                        ],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Transform.scale(
                      scale: 1.10,
                      child: TvSmartImage(
                        imageUrl: backdrop,
                        fit: BoxFit.cover,
                        imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        memCacheWidth: 1920,
                        maxWidthDiskCache: 1920,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            top: (24.0 * scale).clamp(18.0, 36.0),
            left: horizontalPad,
            child: _SpatialBackButton(
              borderRadius: buttonRadius,
              scale: scale,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ),

          Positioned.fill(
            top: (72.0 * scale).clamp(64.0, 100.0),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                0,
                horizontalPad,
                (80.0 * scale).clamp(60.0, 120.0),
              ),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (poster.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: posterRadius,
                        child: Container(
                          width: posterWidth,
                          height: posterHeight,
                          decoration: BoxDecoration(
                            borderRadius: posterRadius,
                            border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TvSmartImage(
                            imageUrl: poster,
                            fit: BoxFit.cover,
                            memCacheWidth: 400,
                            memCacheHeight: 600,
                          ),
                        ),
                      ),
                      SizedBox(width: (22.0 * scale).clamp(16.0, 32.0)),
                    ],

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: cs.onSurface,
                              fontSize: (26.0 * scale).clamp(20.0, 38.0),
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              height: 1.18,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 14,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          if (media.title.native != null ||
                              media.title.romaji != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 3, bottom: 6),
                              child: Text(
                                media.title.native ?? media.title.romaji ?? '',
                                style: TextStyle(
                                  color: cs.onSurfaceVariant.withValues(
                                    alpha: 0.8,
                                  ),
                                  fontSize: (14.0 * scale).clamp(12.5, 18.0),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          SizedBox(height: (6.0 * scale).clamp(4.0, 10.0)),

                          Wrap(
                            spacing: (8.0 * scale).clamp(6.0, 12.0),
                            runSpacing: (6.0 * scale).clamp(4.0, 10.0),
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (score != null && score > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (8.0 * scale).clamp(6.0, 12.0),
                                    vertical: (3.0 * scale).clamp(2.0, 6.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB703),
                                    borderRadius: badgeRadius,
                                  ),
                                  child: Text(
                                    '★ ${score.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: (11.5 * scale).clamp(
                                        10.0,
                                        14.5,
                                      ),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              if (format != null && format.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: (8.0 * scale).clamp(6.0, 12.0),
                                    vertical: (3.0 * scale).clamp(2.0, 6.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: cs.secondaryContainer,
                                    borderRadius: badgeRadius,
                                  ),
                                  child: Text(
                                    format.toUpperCase(),
                                    style: TextStyle(
                                      color: cs.onSecondaryContainer,
                                      fontSize: (11.0 * scale).clamp(
                                        10.0,
                                        14.0,
                                      ),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              if (year != null && year.isNotEmpty)
                                Text(
                                  year,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: (12.5 * scale).clamp(11.0, 15.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              if (status != null && status.isNotEmpty)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            status.toLowerCase() == 'releasing'
                                            ? Colors.greenAccent
                                            : cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color:
                                            status.toLowerCase() == 'releasing'
                                            ? Colors.greenAccent
                                            : cs.onSurfaceVariant,
                                        fontSize: (11.0 * scale).clamp(
                                          10.0,
                                          14.0,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              if (media.episodes != null ||
                                  media.chapters != null)
                                Text(
                                  '• ${media.episodes ?? media.chapters} ${media.type == MediaType.MANGA || media.type == MediaType.NOVEL ? "Chapters" : "Episodes"}',
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: (12.5 * scale).clamp(11.0, 15.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: (8.0 * scale).clamp(6.0, 12.0)),

                          if (genres.isNotEmpty)
                            Text(
                              genres.join(' • '),
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: (13.0 * scale).clamp(11.5, 16.0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          SizedBox(height: (10.0 * scale).clamp(8.0, 14.0)),

                          if (description.isNotEmpty)
                            Text(
                              description
                                  .replaceAll(RegExp(r'<[^>]*>'), '')
                                  .trim(),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: (13.5 * scale).clamp(12.0, 17.5),
                                height: 1.42,
                              ),
                            ),
                          SizedBox(height: (18.0 * scale).clamp(14.0, 24.0)),

                          Row(
                            children: [
                              _SpatialDetailButton(
                                icon: Icons.play_arrow_rounded,
                                label: currentEpisodeNumber != null
                                    ? 'Resume E${currentEpisodeNumber.toInt()}'
                                    : 'Play E1',
                                isPrimary: true,
                                borderRadius: buttonRadius,
                                scale: scale,
                                onPressed: () =>
                                    _handlePrimaryPlay(context, media, ref),
                              ),
                              SizedBox(width: (12.0 * scale).clamp(8.0, 16.0)),
                              _SpatialDetailButton(
                                icon: trackingIcon,
                                label: trackingLabel,
                                isPrimary: false,
                                borderRadius: buttonRadius,
                                scale: scale,
                                onPressed: () {
                                  if (primaryTracker is RemoteTracker &&
                                      !isAuthenticated) {
                                    ref
                                        .read(authTokensProvider.notifier)
                                        .login(primaryTracker);
                                    return;
                                  }
                                  _openTrackerManager(context, media);
                                },
                              ),
                              SizedBox(width: (12.0 * scale).clamp(8.0, 16.0)),
                              _SpatialDetailButton(
                                icon: Icons.tune_rounded,
                                label: activeSource != null
                                    ? activeSource.name
                                    : 'Source',
                                isPrimary: false,
                                borderRadius: buttonRadius,
                                scale: scale,
                                onPressed: () => _openSourceSelector(
                                  context,
                                  media,
                                  availableSources,
                                  activeSource,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: (24.0 * scale).clamp(16.0, 32.0)),

                TvEpisodeShelf(
                  media: media,
                  onOpenSourceSelector: () => _openSourceSelector(
                    context,
                    media,
                    availableSources,
                    activeSource,
                  ),
                ),

                if (relations.isNotEmpty) ...[
                  SizedBox(height: (24.0 * scale).clamp(16.0, 32.0)),
                  HorizontalSection<UnifiedMedia>(
                    title: 'Relations & Franchise',
                    height: sectionHeight,
                    gap: 12.0,
                    data: AsyncData(relations),
                    itemBuilder: (context, rel) => MediaCard(
                      tag: 'tv-relation-${rel.id}',
                      title: rel.title.availableTitle,
                      imageUrl: rel.cover ?? rel.banner ?? '',
                      format: rel.format,
                      score: rel.score,
                      year: rel.season,
                      status: rel.status,
                      genres: rel.genres,
                      style: cardStyle,
                      badge: rel.relationType != null
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer.withValues(
                                  alpha: 0.92,
                                ),
                                borderRadius: badgeRadius,
                              ),
                              child: Text(
                                rel.relationType!
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSecondaryContainer,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  fontSize: (9.5 * scale).clamp(8.5, 12.0),
                                ),
                              ),
                            )
                          : null,
                      onTap: () => context.pushDetails(
                        mediaType: rel.type,
                        media: rel,
                        tag: 'tv-relation-${rel.id}',
                      ),
                    ),
                  ),
                ],

                if (recommendations.isNotEmpty) ...[
                  SizedBox(height: (24.0 * scale).clamp(16.0, 32.0)),
                  HorizontalSection<UnifiedMedia>(
                    title: 'More Like This',
                    height: sectionHeight,
                    gap: 12.0,
                    data: AsyncData(recommendations),
                    itemBuilder: (context, rec) => MediaCard(
                      tag: 'tv-rec-${rec.id}',
                      title: rec.title.availableTitle,
                      imageUrl: rec.cover ?? rec.banner ?? '',
                      format: rec.format,
                      score: rec.score,
                      year: rec.season,
                      status: rec.status,
                      genres: rec.genres,
                      style: cardStyle,
                      onTap: () => context.pushDetails(
                        mediaType: rec.type,
                        media: rec,
                        tag: 'tv-rec-${rec.id}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpatialDetailButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isPrimary;
  final BorderRadius borderRadius;
  final double scale;
  final VoidCallback onPressed;

  const _SpatialDetailButton({
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.borderRadius,
    required this.scale,
    required this.onPressed,
  });

  @override
  State<_SpatialDetailButton> createState() => _SpatialDetailButtonState();
}

class _SpatialDetailButtonState extends State<_SpatialDetailButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bgColor = widget.isPrimary
        ? (_isFocused ? cs.primary.withValues(alpha: 0.9) : cs.primary)
        : (_isFocused
              ? cs.surfaceContainerHighest.withValues(alpha: 0.9)
              : cs.surfaceContainerHighest.withValues(alpha: 0.5));

    final fgColor = widget.isPrimary ? cs.onPrimary : cs.onSurface;

    return FocusableActionDetector(
      focusNode: _focusNode,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: InkWell(
          canRequestFocus: false,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            _focusNode.requestFocus();
            widget.onPressed();
          },
          borderRadius: widget.borderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(
              horizontal: (18.0 * widget.scale).clamp(14.0, 24.0),
              vertical: (10.0 * widget.scale).clamp(8.0, 14.0),
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _isFocused
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: widget.isPrimary
                            ? cs.primary.withValues(alpha: 0.45)
                            : cs.onSurface.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: (18.0 * widget.scale).clamp(16.0, 24.0),
                  color: fgColor,
                ),
                SizedBox(width: (7.0 * widget.scale).clamp(5.0, 10.0)),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: fgColor,
                    fontSize: (13.0 * widget.scale).clamp(11.5, 16.0),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpatialBackButton extends StatefulWidget {
  final BorderRadius borderRadius;
  final double scale;
  final VoidCallback onTap;

  const _SpatialBackButton({
    required this.borderRadius,
    required this.scale,
    required this.onTap,
  });

  @override
  State<_SpatialBackButton> createState() => _SpatialBackButtonState();
}

class _SpatialBackButtonState extends State<_SpatialBackButton> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FocusableActionDetector(
      focusNode: _focusNode,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: AnimatedScale(
        scale: _isFocused ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 140),
        child: InkWell(
          canRequestFocus: false,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () {
            _focusNode.requestFocus();
            widget.onTap();
          },
          borderRadius: widget.borderRadius,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: (14.0 * widget.scale).clamp(10.0, 18.0),
              vertical: (8.0 * widget.scale).clamp(6.0, 12.0),
            ),
            decoration: BoxDecoration(
              color: _isFocused
                  ? cs.primary
                  : cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _isFocused
                    ? cs.primary
                    : cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  color: _isFocused ? cs.onPrimary : cs.onSurface,
                  size: (18.0 * widget.scale).clamp(16.0, 24.0),
                ),
                SizedBox(width: (6.0 * widget.scale).clamp(4.0, 8.0)),
                Text(
                  'Back',
                  style: TextStyle(
                    color: _isFocused ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: (13.0 * widget.scale).clamp(11.5, 16.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
