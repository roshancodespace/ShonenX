import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/discord/providers/discord_rpc_provider.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/characters_sheet.dart';
import 'package:shonenx/features/discovery/providers/details_provider.dart';
import 'package:shonenx/features/discovery/providers/episodes_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/providers/read_history_provider.dart';
import 'package:shonenx/features/history/providers/watch_history_provider.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/reader/domain/reader_mode.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/presentation/widgets/edit_tracker_sheet.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_manager_sheet.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_link_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_episode_shelf.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_focusable.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_media_card.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_source_dialog.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

class TvDetailsScreen extends ConsumerStatefulWidget {
  final UnifiedMedia media;
  final String tag;

  const TvDetailsScreen({super.key, required this.media, required this.tag});

  @override
  ConsumerState<TvDetailsScreen> createState() => _TvDetailsScreenState();
}

class _TvDetailsScreenState extends ConsumerState<TvDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _episodesShelfKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discordRpcProvider.notifier).updateMediaPresence(widget.media);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToEpisodes() {
    final context = _episodesShelfKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _showSynopsisDialog(
    BuildContext context,
    String title,
    String description,
  ) {
    AppDialog.show(
      context: context,
      title: 'Synopsis • $title',
      icon: const Icon(Icons.description_outlined),
      maxWidth: 700,
      child: MarkdownBody(
        data: description.replaceAll('<br>', '\n'),
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.9),
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ),
    );
  }

  void _shareMedia(UnifiedMedia media) {
    final providerId = media.providerId ?? 'anilist';
    final id = media.id;
    final type = media.type == MediaType.ANIME ? 'anime' : 'manga';
    String url;
    if (providerId == 'myanimelist' || providerId == 'mal') {
      url = 'https://myanimelist.net/$type/$id';
    } else if (providerId == 'kitsu') {
      url = 'https://kitsu.io/$type/$id';
    } else {
      url = 'https://anilist.co/$type/$id';
    }
    SharePlus.instance.share(ShareParams(uri: Uri.parse(url)));
  }

  Future<void> _playTrailer(String? trailer) async {
    if (trailer == null || trailer.isEmpty) return;
    final trailerUrl = trailer.startsWith('http')
        ? trailer
        : 'https://www.youtube.com/watch?v=$trailer';
    final uri = Uri.tryParse(trailerUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;

    final detailsArgs = DetailsArgs(
      widget.media.id,
      widget.media.type,
      sourceId: widget.media.sourceId,
      trackerId: widget.media.providerId,
    );

    final detailsAsync = ref.watch(detailsProvider(detailsArgs));
    final displayMedia =
        detailsAsync.value?.merge(widget.media) ?? widget.media;

    final mediaArgs = MediaArgs.fromMedia(displayMedia);
    final preferenceState = ref.watch(mediaPreferenceProvider(mediaArgs)).value;
    final currentSource = preferenceState?.sourceInfo;

    final episodesState = ref.watch(episodesListProvider(mediaArgs)).value;
    final watchHistory =
        ref.watch(historyEpisodesProvider(displayMedia.id)).value ?? [];
    final readHistory =
        ref.watch(historyChaptersProvider(displayMedia.id)).value ?? [];

    final tracker = ref.watch(primaryTrackerProvider);
    final trackingState = ref.watch(
      mediaTrackingProvider(TrackingQuery(tracker.type, displayMedia)),
    );
    final trackerLinks =
        ref.watch(trackerLinkProvider(displayMedia.id)).value ?? {};

    final backdropImage = (displayMedia.banner?.isNotEmpty == true)
        ? displayMedia.banner!
        : (displayMedia.cover ?? '');

    final isManga =
        displayMedia.type == MediaType.MANGA ||
        displayMedia.type == MediaType.NOVEL;

    final nextTarget = _resolveNextTarget(
      isManga: isManga,
      episodes: episodesState?.episodes ?? [],
      watchHistory: watchHistory,
      readHistory: readHistory,
      trackedProgress: trackingState.value?.progress.toDouble() ?? 0,
    );

    return AppScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (backdropImage.isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.82,
              child: Opacity(
                opacity: 0.55,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.35, 0.85],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          Color(0x55000000),
                          Colors.black,
                        ],
                        stops: [0.0, 0.35, 0.85],
                      ).createShader(rect);
                    },
                    blendMode: BlendMode.dstIn,
                    child: ClipRect(
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 8,
                          sigmaY: 8,
                          tileMode: TileMode.decal,
                        ),
                        child: CachedNetworkImage(
                          imageUrl: backdropImage,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: Container(
              color: backdropImage.isEmpty
                  ? const Color(0xFF0D0E11)
                  : Colors.transparent,
            ),
          ),
          SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(48, 16, 48, 48),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildTopBar(context, displayMedia, radius),
                const SizedBox(height: 18),
                _buildHeroCinematic(
                  context,
                  displayMedia,
                  nextTarget,
                  currentSource,
                  episodesState?.source,
                  isManga,
                  radius,
                  cs,
                  tracker,
                  trackingState,
                  trackerLinks,
                ),
                const SizedBox(height: 36),
                Container(
                  key: _episodesShelfKey,
                  child: TvEpisodeShelf(
                    media: displayMedia,
                    onOpenSourceSelector: () => TvSourceDialog.show(
                      context,
                      media: displayMedia,
                      currentSource: currentSource ?? episodesState?.source,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                if (displayMedia.characters != null &&
                    displayMedia.characters!.isNotEmpty)
                  _buildCharactersSection(context, displayMedia, radius),
                const SizedBox(height: 36),
                _buildInformationSection(context, displayMedia, radius),
                const SizedBox(height: 36),
                if (displayMedia.relations != null &&
                    displayMedia.relations!.isNotEmpty)
                  _buildRelationsSection(context, displayMedia),
                const SizedBox(height: 36),
                if (displayMedia.recommendations != null &&
                    displayMedia.recommendations!.isNotEmpty)
                  _buildRecommendationsSection(context, displayMedia),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, UnifiedMedia media, double radius) {
    return Row(
      children: [
        TvFocusable(
          onTap: () => context.pop(),
          builder: (context, isFocused, isHovered) {
            final active = isFocused || isHovered;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 13,
                    color: active ? Colors.black : Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: active ? Colors.black : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Spacer(),
        TvFocusable(
          onTap: () => _shareMedia(media),
          builder: (context, isFocused, isHovered) {
            final active = isFocused || isHovered;
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Icon(
                Icons.share_rounded,
                size: 16,
                color: active ? Colors.black : Colors.white70,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeroCinematic(
    BuildContext context,
    UnifiedMedia media,
    _PlaybackTarget? nextTarget,
    SourceInfo? currentSource,
    SourceInfo? activeSource,
    bool isManga,
    double radius,
    ColorScheme cs,
    TrackingService tracker,
    AsyncValue<TrackedListItem?> trackingState,
    Map<TrackerType, dynamic> trackerLinks,
  ) {
    final posterUrl = media.cover ?? media.banner ?? '';
    final effectiveSource = currentSource ?? activeSource;
    final cleanSynopsis = (media.description ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('\n', ' ')
        .trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (posterUrl.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Hero(
              tag: widget.tag,
              child: CachedNetworkImage(
                imageUrl: posterUrl,
                width: 170,
                height: 245,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 170,
                  height: 245,
                  color: Colors.white10,
                  child: const Icon(Icons.movie_rounded, color: Colors.white24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                media.title.availableTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                  letterSpacing: -0.6,
                ),
              ),
              if (media.title.romaji != null || media.title.native != null) ...[
                const SizedBox(height: 4),
                Text(
                  media.title.romaji ?? media.title.native!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (media.score != null && media.score! > 0) ...[
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: Colors.amberAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      media.score!.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    _buildDot(),
                  ],
                  if (media.year != null || media.season != null) ...[
                    Text(
                      [
                        if (media.season != null) media.season!.toUpperCase(),
                        if (media.year != null) media.year.toString(),
                      ].join(' '),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _buildDot(),
                  ],
                  if (media.format != null && media.format!.isNotEmpty) ...[
                    Text(
                      media.format!.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    _buildDot(),
                  ],
                  Text(
                    isManga
                        ? '${media.chapters ?? '?'} Chapters'
                        : '${media.episodes ?? '?'} Episodes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (media.duration != null && media.duration! > 0) ...[
                    _buildDot(),
                    Text(
                      '${media.duration}m',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (media.status != null && media.status!.isNotEmpty) ...[
                    _buildDot(),
                    _buildCleanStatusDot(media.status!),
                    const SizedBox(width: 5),
                    Text(
                      media.status!.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              if (media.genres != null && media.genres!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  media.genres!.take(5).join('  ·  '),
                  style: TextStyle(
                    color: cs.primary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              if (cleanSynopsis.isNotEmpty)
                TvFocusable(
                  scaleFactor: 1.0,
                  onTap: () => _showSynopsisDialog(
                    context,
                    media.title.availableTitle,
                    media.description!,
                  ),
                  builder: (context, isFocused, isHovered) {
                    final active = isFocused || isHovered;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(radius),
                        border: Border.all(
                          color: active
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        cleanSynopsis,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: active
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TvFocusable(
                    autofocus: true,
                    onTap: () {
                      if (nextTarget != null && effectiveSource != null) {
                        _launchTargetPlayback(
                          context,
                          media,
                          nextTarget,
                          effectiveSource,
                          isManga,
                        );
                      } else {
                        _scrollToEpisodes();
                      }
                    },
                    builder: (context, isFocused, isHovered) {
                      final active = isFocused || isHovered;
                      final String playButtonLabel;
                      if (nextTarget != null) {
                        playButtonLabel = nextTarget.buttonLabel;
                      } else if (trackingState.value != null &&
                          trackingState.value!.progress > 0) {
                        final p = trackingState.value!.progress;
                        final numStr = p % 1 == 0
                            ? (p.toInt() + 1).toString()
                            : (p + 1).toString();
                        playButtonLabel = isManga
                            ? 'Read Ch $numStr'
                            : 'Play Ep $numStr';
                      } else {
                        playButtonLabel = isManga
                            ? 'Start Reading'
                            : 'Start Watching';
                      }

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: active ? Colors.white : cs.primary,
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isManga
                                  ? Icons.menu_book_rounded
                                  : Icons.play_arrow_rounded,
                              size: 19,
                              color: active ? Colors.black : Colors.white,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              playButtonLabel,
                              style: TextStyle(
                                color: active ? Colors.black : Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (effectiveSource != null)
                    TvFocusable(
                      onTap: () => TvSourceDialog.show(
                        context,
                        media: media,
                        currentSource: effectiveSource,
                      ),
                      builder: (context, isFocused, isHovered) {
                        final active = isFocused || isHovered;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(radius),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 14,
                                color: active ? Colors.black : cs.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                effectiveSource.name,
                                style: TextStyle(
                                  color: active ? Colors.black : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  TvFocusable(
                    onTap: () {
                      if (tracker is RemoteTracker &&
                          !tracker.type.isAuthenticated(ref)) {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => TrackerManagerSheet(media: media),
                        );
                        return;
                      }
                      final item = trackingState.value;
                      if (item != null) {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => EditTrackerSheet(
                            media: media,
                            initialItem: item,
                            tracker: tracker,
                          ),
                        );
                      } else {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => TrackerManagerSheet(media: media),
                        );
                      }
                    },
                    builder: (context, isFocused, isHovered) {
                      final active = isFocused || isHovered;
                      final item = trackingState.value;
                      final label = item != null
                          ? '${isManga ? "Ch" : "Ep"} ${item.progress.toInt()} • ${item.status.getLabelForMedia(media.type)}'
                          : 'Add to Library';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : item != null
                              ? cs.primary.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item != null
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_add_outlined,
                              size: 15,
                              color: active
                                  ? Colors.black
                                  : item != null
                                  ? cs.primary
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: TextStyle(
                                color: active
                                    ? Colors.black
                                    : item != null
                                    ? cs.primary
                                    : Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (media.trailer != null && media.trailer!.isNotEmpty)
                    TvFocusable(
                      onTap: () => _playTrailer(media.trailer),
                      builder: (context, isFocused, isHovered) {
                        final active = isFocused || isHovered;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(radius),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                size: 16,
                                color: active ? Colors.black : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Trailer',
                                style: TextStyle(
                                  color: active ? Colors.black : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        '•',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCleanStatusDot(String status) {
    final clean = status.toLowerCase();
    final isReleasing = clean == 'releasing' || clean == 'airing';
    final isFinished = clean == 'finished' || clean == 'completed';

    final color = isReleasing
        ? Colors.greenAccent
        : isFinished
        ? Colors.lightBlueAccent
        : Colors.amberAccent;

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildCharactersSection(
    BuildContext context,
    UnifiedMedia media,
    double radius,
  ) {
    final characters = media.characters ?? [];

    return HorizontalSection<MediaCharacter>(
      titleWidget: const Text(
        'Characters & Cast',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      headerTrailing: TvFocusable(
        onTap: () => CharactersSheet.show(
          context,
          mediaId: media.id,
          mediaType: media.type,
          mediaTitle: media.title.availableTitle,
          initialCharacters: characters,
        ),
        builder: (context, isFocused, isHovered) {
          final active = isFocused || isHovered;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View All',
                  style: TextStyle(
                    color: active ? Colors.black : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: active ? Colors.black : Colors.white70,
                ),
              ],
            ),
          );
        },
      ),
      data: AsyncValue.data(characters),
      height: 140,
      gap: 16,
      headerPadding: const EdgeInsets.only(bottom: 14),
      listPadding: EdgeInsets.zero,
      itemBuilder: (context, character) {
        return TvFocusable(
          onTap: () => CharactersSheet.showDetails(context, character),
          scaleFactor: 1.05,
          builder: (context, isFocused, isHovered) {
            final active = isFocused || isHovered;
            return SizedBox(
              width: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? Colors.white : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: character.image ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.white10,
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    character.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (character.voiceActorName != null &&
                      character.voiceActorName!.isNotEmpty)
                    Text(
                      character.voiceActorName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.5,
                      ),
                    )
                  else if (character.role != null && character.role!.isNotEmpty)
                    Text(
                      character.role!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInformationSection(
    BuildContext context,
    UnifiedMedia media,
    double radius,
  ) {
    final infoItems = <({String label, String value})>[];

    if (media.studios != null && media.studios!.isNotEmpty) {
      infoItems.add((label: 'STUDIO', value: media.studios!.join(', ')));
    }
    if (media.source != null && media.source!.isNotEmpty) {
      infoItems.add((
        label: 'SOURCE MATERIAL',
        value: media.source!.toUpperCase().replaceAll('_', ' '),
      ));
    }
    if (media.airingAt != null) {
      infoItems.add((
        label: 'NEXT AIRING',
        value: 'In ${formatCountdown(media.airingAt!)}',
      ));
    }
    if (media.favourites != null && media.favourites! > 0) {
      infoItems.add((label: 'FAVORITES', value: '${media.favourites}'));
    }
    if (media.popularity != null && media.popularity! > 0) {
      infoItems.add((label: 'POPULARITY RANK', value: '#${media.popularity}'));
    }

    if (infoItems.isEmpty &&
        (media.externalLinks == null || media.externalLinks!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Information & Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 36,
          runSpacing: 18,
          children: infoItems.map((item) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        if (media.externalLinks != null && media.externalLinks!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: media.externalLinks!.take(4).map((link) {
              return TvFocusable(
                onTap: () async {
                  final uri = Uri.tryParse(link.url);
                  if (uri != null && await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                builder: (context, isFocused, isHovered) {
                  final active = isFocused || isHovered;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: active ? Colors.black : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          link.site,
                          style: TextStyle(
                            color: active ? Colors.black : Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRelationsSection(BuildContext context, UnifiedMedia media) {
    final relations = media.relations ?? [];
    if (relations.isEmpty) return const SizedBox.shrink();

    final Map<String, List<UnifiedMedia>> grouped = {};
    for (final rel in relations) {
      final type = rel.relationType ?? 'Related';
      final formattedType = type
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (s) => s.isEmpty
                ? ''
                : s[0].toUpperCase() + s.substring(1).toLowerCase(),
          )
          .join(' ');
      grouped.putIfAbsent(formattedType, () => []).add(rel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: HorizontalSection<UnifiedMedia>(
            titleWidget: Text(
              'Relations • ${entry.key}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            data: AsyncValue.data(entry.value),
            height: 220,
            gap: 16,
            headerPadding: const EdgeInsets.only(bottom: 14),
            listPadding: EdgeInsets.zero,
            itemBuilder: (context, item) {
              return TvMediaCard(
                title: item.title.availableTitle,
                cover: item.cover ?? '',
                banner: item.banner,
                score: item.score,
                description: item.description,
                genres: item.genres,
                year: item.year,
                onTap: () => context.pushDetails(
                  mediaType: item.type,
                  media: item,
                  tag: 'tv-rel-${item.id}',
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationsSection(
    BuildContext context,
    UnifiedMedia media,
  ) {
    final recommendations = media.recommendations ?? [];
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return HorizontalSection<UnifiedMedia>(
      titleWidget: const Text(
        'More Like This',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      data: AsyncValue.data(recommendations),
      height: 220,
      gap: 16,
      headerPadding: const EdgeInsets.only(bottom: 14),
      listPadding: EdgeInsets.zero,
      itemBuilder: (context, item) {
        return TvMediaCard(
          title: item.title.availableTitle,
          cover: item.cover ?? '',
          banner: item.banner,
          score: item.score,
          description: item.description,
          genres: item.genres,
          year: item.year,
          onTap: () => context.pushDetails(
            mediaType: item.type,
            media: item,
            tag: 'tv-rec-${item.id}',
          ),
        );
      },
    );
  }

  _PlaybackTarget? _resolveNextTarget({
    required bool isManga,
    required List<UnifiedEpisode> episodes,
    required List<WatchHistoryEntry> watchHistory,
    required List<ReadHistoryEntry> readHistory,
    required double trackedProgress,
  }) {
    if (episodes.isEmpty) return null;

    final sortedEps = List<UnifiedEpisode>.from(episodes)
      ..sort((a, b) => a.number.compareTo(b.number));

    String fmtNum(num n) => n % 1 == 0 ? n.toInt().toString() : n.toString();

    if (isManga) {
      final latestRead = readHistory.firstOrNull;
      if (latestRead != null) {
        final currentEp = sortedEps
            .where((e) => (e.number - latestRead.chapterNumber).abs() < 0.01)
            .firstOrNull;
        if (currentEp != null) {
          final isFinished = latestRead.positionPage >= latestRead.totalPages;
          if (!isFinished && latestRead.positionPage > 0) {
            return _PlaybackTarget(
              episode: currentEp,
              buttonLabel:
                  'Resume Ch ${fmtNum(currentEp.number)} (p. ${latestRead.positionPage})',
              startPositionPage: latestRead.positionPage,
            );
          } else {
            final nextEp = sortedEps
                .where((e) => e.number > currentEp.number)
                .firstOrNull;
            if (nextEp != null) {
              return _PlaybackTarget(
                episode: nextEp,
                buttonLabel: 'Read Ch ${fmtNum(nextEp.number)}',
                startPositionPage: 1,
              );
            } else {
              return _PlaybackTarget(
                episode: currentEp,
                buttonLabel: 'Re-read Ch ${fmtNum(currentEp.number)}',
                startPositionPage: 1,
              );
            }
          }
        }
      }
      if (trackedProgress > 0) {
        final nextTracked = sortedEps
            .where((e) => e.number > trackedProgress)
            .firstOrNull;
        if (nextTracked != null) {
          return _PlaybackTarget(
            episode: nextTracked,
            buttonLabel: 'Read Ch ${fmtNum(nextTracked.number)}',
            startPositionPage: 1,
          );
        }

        final exactTracked = sortedEps
            .where((e) => (e.number - trackedProgress).abs() < 0.01)
            .firstOrNull;
        if (exactTracked != null) {
          return _PlaybackTarget(
            episode: exactTracked,
            buttonLabel: 'Read Ch ${fmtNum(exactTracked.number)}',
            startPositionPage: 1,
          );
        }

        final lastAvailable = sortedEps.lastOrNull;
        if (lastAvailable != null) {
          return _PlaybackTarget(
            episode: lastAvailable,
            buttonLabel: 'Read Ch ${fmtNum(lastAvailable.number)}',
            startPositionPage: 1,
          );
        }
      }
    } else {
      final latestWatch = watchHistory.firstOrNull;
      if (latestWatch != null) {
        final currentEp = sortedEps
            .where((e) => (e.number - latestWatch.episodeNumber).abs() < 0.01)
            .firstOrNull;
        if (currentEp != null) {
          final isFinished =
              latestWatch.durationInMilliseconds > 0 &&
              latestWatch.positionInMilliseconds >=
                  latestWatch.durationInMilliseconds * 0.9;

          if (!isFinished && latestWatch.positionInMilliseconds > 0) {
            final remainingMins =
                latestWatch.durationInMilliseconds >
                    latestWatch.positionInMilliseconds
                ? ((latestWatch.durationInMilliseconds -
                              latestWatch.positionInMilliseconds) /
                          60000)
                      .ceil()
                : 0;
            return _PlaybackTarget(
              episode: currentEp,
              buttonLabel: remainingMins > 0
                  ? 'Resume Ep ${fmtNum(currentEp.number)} (${remainingMins}m left)'
                  : 'Resume Ep ${fmtNum(currentEp.number)}',
              startPositionDuration: Duration(
                milliseconds: latestWatch.positionInMilliseconds,
              ),
            );
          } else {
            final nextEp = sortedEps
                .where((e) => e.number > currentEp.number)
                .firstOrNull;
            if (nextEp != null) {
              return _PlaybackTarget(
                episode: nextEp,
                buttonLabel: 'Play Ep ${fmtNum(nextEp.number)}',
              );
            } else {
              return _PlaybackTarget(
                episode: currentEp,
                buttonLabel: 'Replay Ep ${fmtNum(currentEp.number)}',
              );
            }
          }
        }
      }
      if (trackedProgress > 0) {
        final nextTracked = sortedEps
            .where((e) => e.number > trackedProgress)
            .firstOrNull;
        if (nextTracked != null) {
          return _PlaybackTarget(
            episode: nextTracked,
            buttonLabel: 'Play Ep ${fmtNum(nextTracked.number)}',
          );
        }

        final exactTracked = sortedEps
            .where((e) => (e.number - trackedProgress).abs() < 0.01)
            .firstOrNull;
        if (exactTracked != null) {
          return _PlaybackTarget(
            episode: exactTracked,
            buttonLabel: 'Play Ep ${fmtNum(exactTracked.number)}',
          );
        }

        final lastAvailable = sortedEps.lastOrNull;
        if (lastAvailable != null) {
          return _PlaybackTarget(
            episode: lastAvailable,
            buttonLabel: 'Play Ep ${fmtNum(lastAvailable.number)}',
          );
        }
      }
    }

    final firstEp = sortedEps.first;
    return _PlaybackTarget(
      episode: firstEp,
      buttonLabel: isManga
          ? 'Read Ch ${fmtNum(firstEp.number)}'
          : 'Play Ep ${fmtNum(firstEp.number)}',
      startPositionPage: 1,
    );
  }

  void _launchTargetPlayback(
    BuildContext context,
    UnifiedMedia media,
    _PlaybackTarget target,
    SourceInfo sourceInfo,
    bool isManga,
  ) {
    if (isManga) {
      context.pushReader(
        ReaderModeOnline(
          media: media,
          episode: target.episode,
          sourceInfo: sourceInfo,
          startPosition: target.startPositionPage ?? 1,
        ),
      );
    } else {
      context.pushPlayer(
        PlayerModeOnline(
          media: media,
          episode: target.episode,
          sourceInfo: sourceInfo,
          startPosition: target.startPositionDuration,
        ),
      );
    }
  }
}

class _PlaybackTarget {
  final UnifiedEpisode episode;
  final String buttonLabel;
  final int? startPositionPage;
  final Duration? startPositionDuration;

  const _PlaybackTarget({
    required this.episode,
    required this.buttonLabel,
    this.startPositionPage,
    this.startPositionDuration,
  });
}
