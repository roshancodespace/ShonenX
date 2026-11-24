import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/rows/horizontal_section.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/characters_sheet.dart';
import 'package:shonenx/features/notifications/domain/models/notification_subscription.dart';
import 'package:shonenx/features/notifications/presentation/widgets/notification_subscription_sheet.dart';
import 'package:shonenx/features/notifications/providers/notification_subscriptions_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

abstract final class _Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

const double _innerRadius = 6;
const double _segmentGap = 2;
const double _characterImageWidth = 56;
const double _characterImageHeight = 92;
const double _characterCardPadding = 6;
const double _characterCardWidth = 208;

const StadiumBorder _stadium = StadiumBorder();

double _largeRadius(double uiRoundness) =>
    uiRoundness.clamp(16.0, 28.0).toDouble();

bool _hasText(String? value) => value != null && value.isNotEmpty;

String _sentenceCase(String value) {
  final text = value.replaceAll('_', ' ').trim().toLowerCase();
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

String _compactNumber(int number) {
  String trim(double value) {
    final fixed = value.toStringAsFixed(1);
    return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
  }

  if (number >= 1000000) return '${trim(number / 1000000)}M';
  if (number >= 1000) return '${trim(number / 1000)}k';
  return number.toString();
}

List<_DetailPair> _detailPairs(BuildContext context, UnifiedMedia media) {
  final l10n = context.l10n;
  return [
    if (media.studios != null && media.studios!.isNotEmpty)
      _DetailPair(l10n.detailsStudio, media.studios!.join(', ')),
    if (_hasText(media.source))
      _DetailPair('Source', _sentenceCase(media.source!)),
    if ((media.duration ?? 0) > 0)
      _DetailPair(l10n.detailsDuration, l10n.detailsMinutes(media.duration!)),
    if ((media.volumes ?? 0) > 0)
      _DetailPair(l10n.detailsVolumes, '${media.volumes}'),
    if ((media.favourites ?? 0) > 0)
      _DetailPair(l10n.detailsFavorites, _compactNumber(media.favourites!)),
    if ((media.popularity ?? 0) > 0)
      _DetailPair(l10n.detailsPopularity, '#${media.popularity}'),
  ];
}

class AboutTabWidget extends ConsumerStatefulWidget {
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
  ConsumerState<AboutTabWidget> createState() => _AboutTabWidgetState();
}

class _AboutTabWidgetState extends ConsumerState<AboutTabWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final media = widget.media;
    final radius = _largeRadius(widget.uiRoundness);

    final hasTags = media.tags != null && media.tags!.isNotEmpty;
    final hasGenres = media.genres != null && media.genres!.isNotEmpty;
    final hasRelations = media.relations != null && media.relations!.isNotEmpty;
    final hasRecommendations =
        media.recommendations != null && media.recommendations!.isNotEmpty;
    final hasCharacters =
        (media.characters != null && media.characters!.isNotEmpty) ||
        media.id.isNotEmpty;
    final hasLinks =
        media.externalLinks != null && media.externalLinks!.isNotEmpty;
    final hasAlternativeTitles =
        _hasText(media.title.english) ||
        _hasText(media.title.romaji) ||
        _hasText(media.title.native) ||
        (media.synonyms != null && media.synonyms!.isNotEmpty);
    final details = _detailPairs(context, media);

    final items = <Widget>[
      if (media.airingAt != null)
        _AiringBanner(
          media: media,
          onEpisodesTabRequested: widget.onEpisodesTabRequested,
          radius: radius,
        ),
      if (_hasText(media.description))
        Synopsis(description: media.description!),
      if (details.isNotEmpty)
        _MediaDetailsSection(details: details, radius: radius),
      if (hasAlternativeTitles)
        _AlternativeTitlesTile(
          title: media.title,
          synonyms: media.synonyms ?? [],
          radius: radius,
        ),
      if (hasGenres || hasTags)
        _GenresAndTagsSection(
          genres: media.genres ?? [],
          tags: media.tags ?? [],
          mediaType: media.type,
        ),
      if (hasCharacters)
        _CharactersList(
          mediaId: media.id,
          mediaType: media.type,
          mediaTitle: media.title.getPreferedTitle,
          characters: media.characters ?? [],
          radius: radius,
        ),
      if (hasLinks) _ExternalLinksList(links: media.externalLinks!),
      if (hasRelations)
        _RelationsList(relations: media.relations!, parentType: media.type),
      if (hasRecommendations)
        _RecommendationsList(recommendations: media.recommendations!),
    ];

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        _Space.lg,
        _Space.md,
        _Space.lg,
        _Space.xxl,
      ),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: _Space.xxl),
      itemBuilder: (context, index) {
        return StaggeredFadeIn(index: index, child: items[index]);
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 36),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(onTap: onTap, customBorder: _stadium, child: row);
  }
}

class _SubLabel extends StatelessWidget {
  final String text;

  const _SubLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TonalCircle extends StatelessWidget {
  final Widget child;

  const _TonalCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class _DetailPair {
  final String label;
  final String value;
  const _DetailPair(this.label, this.value);
}

class _SegmentedRows extends StatelessWidget {
  final List<_DetailPair> rows;
  final double radius;

  const _SegmentedRows({required this.rows, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : _segmentGap),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: _Space.lg,
                vertical: _Space.md + 2,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainer,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(i == 0 ? radius : _innerRadius),
                  bottom: Radius.circular(
                    i == rows.length - 1 ? radius : _innerRadius,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      rows[i].label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].value,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _MediaDetailsSection extends StatelessWidget {
  final List<_DetailPair> details;
  final double radius;

  const _MediaDetailsSection({required this.details, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: context.l10n.detailsInformation),
        const SizedBox(height: _Space.md),
        _SegmentedRows(rows: details, radius: radius),
      ],
    );
  }
}

class _AlternativeTitlesTile extends StatefulWidget {
  final MediaTitle title;
  final List<String> synonyms;
  final double radius;

  const _AlternativeTitlesTile({
    required this.title,
    required this.synonyms,
    required this.radius,
  });

  @override
  State<_AlternativeTitlesTile> createState() => _AlternativeTitlesTileState();
}

class _AlternativeTitlesTileState extends State<_AlternativeTitlesTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final title = widget.title;
    final hasSynonyms = widget.synonyms.isNotEmpty;

    final rows = <_DetailPair>[
      if (_hasText(title.english))
        _DetailPair(l10n.detailsEnglish, title.english!),
      if (_hasText(title.romaji))
        _DetailPair(l10n.detailsRomaji, title.romaji!),
      if (_hasText(title.native))
        _DetailPair(l10n.detailsNative, title.native!),
      if (_expanded && hasSynonyms)
        _DetailPair(l10n.detailsSynonyms, widget.synonyms.join(', ')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: l10n.detailsAlternativeTitles,
          onTap: hasSynonyms
              ? () => setState(() => _expanded = !_expanded)
              : null,
          trailing: hasSynonyms
              ? _TonalCircle(
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : null,
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: rows.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: _Space.md),
                  child: _SegmentedRows(rows: rows, radius: widget.radius),
                ),
        ),
      ],
    );
  }
}

class _MediaChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color background;
  final Color foreground;
  final FontWeight weight;
  final IconData? icon;

  const _MediaChip({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    this.weight = FontWeight.w600,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: 0,
      pressElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: _stadium,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: _Space.sm),
      labelPadding: const EdgeInsets.symmetric(horizontal: _Space.xs),
      backgroundColor: background,
      avatar: icon == null ? null : Icon(icon, size: 16, color: foreground),
      label: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: weight, color: foreground),
      ),
      onPressed: onPressed,
    );
  }
}

class _GenresAndTagsSection extends StatelessWidget {
  final List<String> genres;
  final List<MediaTag> tags;
  final MediaType? mediaType;

  const _GenresAndTagsSection({
    required this.genres,
    required this.tags,
    this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (genres.isNotEmpty) ...[
          const _SectionHeader(title: 'Genres'),
          const SizedBox(height: _Space.md),
          Wrap(
            spacing: _Space.sm,
            runSpacing: _Space.sm,
            children: [
              for (final genre in genres)
                _MediaChip(
                  label: genre,
                  background: cs.secondaryContainer,
                  foreground: cs.onSecondaryContainer,
                  onPressed: () =>
                      context.goDiscover(genres: [genre], type: mediaType),
                ),
            ],
          ),
        ],
        if (genres.isNotEmpty && tags.isNotEmpty)
          const SizedBox(height: _Space.xl),
        if (tags.isNotEmpty) ...[
          const _SubLabel('Tags'),
          const SizedBox(height: _Space.sm),
          Wrap(
            spacing: _Space.sm,
            runSpacing: _Space.sm,
            children: [
              for (final tag in tags)
                _MediaChip(
                  label: tag.name,
                  background: cs.surfaceContainerHigh,
                  foreground: cs.onSurfaceVariant,
                  weight: FontWeight.w500,
                  onPressed: () =>
                      context.goDiscover(tags: [tag.name], type: mediaType),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CharactersList extends ConsumerStatefulWidget {
  final String mediaId;
  final MediaType mediaType;
  final String mediaTitle;
  final List<MediaCharacter> characters;
  final double radius;

  const _CharactersList({
    required this.mediaId,
    required this.mediaType,
    required this.mediaTitle,
    required this.characters,
    required this.radius,
  });

  @override
  ConsumerState<_CharactersList> createState() => _CharactersListState();
}

class _CharactersListState extends ConsumerState<_CharactersList> {
  List<MediaCharacter> _list = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _list = List.from(widget.characters);
    if (_list.isEmpty && widget.mediaId.isNotEmpty) {
      _fetchInitialCharacters();
    }
  }

  Future<void> _fetchInitialCharacters() async {
    setState(() => _isLoading = true);
    try {
      final tracker = ref.read(metadataSourceProvider);
      final res = await tracker.getCharacters(
        widget.mediaId,
        page: 1,
        perPage: 15,
        type: widget.mediaType,
      );
      if (mounted) {
        setState(() {
          _list = res.items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAll() {
    CharactersSheet.show(
      context,
      mediaId: widget.mediaId,
      mediaType: widget.mediaType,
      mediaTitle: widget.mediaTitle,
      initialCharacters: widget.characters,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_list.isEmpty && !_isLoading) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    const height = _characterImageHeight + _characterCardPadding * 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Characters & cast',
          onTap: _openAll,
          trailing: _TonalCircle(
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: _Space.md),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _isLoading ? 4 : _list.length,
            separatorBuilder: (_, __) => const SizedBox(width: _Space.sm),
            itemBuilder: (context, index) {
              if (_isLoading) {
                return _CharacterSkeleton(radius: widget.radius);
              }
              return _CharacterCard(
                character: _list[index],
                radius: widget.radius,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CharacterImage extends StatelessWidget {
  final String? url;
  final double radius;

  const _CharacterImage({required this.url, required this.radius});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(radius);

    Widget placeholder() => Container(
      width: _characterImageWidth,
      height: _characterImageHeight,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
      child: Icon(Icons.person_rounded, size: 24, color: cs.onSurfaceVariant),
    );

    if (url == null || url!.isEmpty) return placeholder();

    return ClipRRect(
      borderRadius: borderRadius,
      child: SmartImage(
        imageUrl: url!,
        width: _characterImageWidth,
        height: _characterImageHeight,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => placeholder(),
      ),
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final MediaCharacter character;
  final double radius;

  const _CharacterCard({required this.character, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final imageRadius = (radius - _characterCardPadding)
        .clamp(8.0, 28.0)
        .toDouble();

    return Material(
      color: cs.surfaceContainer,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => CharactersSheet.showDetails(context, character),
        child: SizedBox(
          width: _characterCardWidth,
          child: Padding(
            padding: const EdgeInsets.all(_characterCardPadding),
            child: Row(
              children: [
                _CharacterImage(url: character.image, radius: imageRadius),
                const SizedBox(width: _Space.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        character.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (_hasText(character.role)) ...[
                        const SizedBox(height: 2),
                        Text(
                          _sentenceCase(character.role!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (_hasText(character.voiceActorName)) ...[
                        const SizedBox(height: _Space.xs),
                        Text(
                          character.voiceActorName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
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

class _CharacterSkeleton extends StatelessWidget {
  final double radius;

  const _CharacterSkeleton({required this.radius});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final block = cs.surfaceContainerHighest.withValues(alpha: 0.6);
    final imageRadius = (radius - _characterCardPadding)
        .clamp(8.0, 28.0)
        .toDouble();

    Widget line(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: block,
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );

    return Container(
      width: _characterCardWidth,
      padding: const EdgeInsets.all(_characterCardPadding),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Container(
            width: _characterImageWidth,
            height: _characterImageHeight,
            decoration: BoxDecoration(
              color: block,
              borderRadius: BorderRadius.circular(imageRadius),
            ),
          ),
          const SizedBox(width: _Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                line(84, 12),
                const SizedBox(height: _Space.sm),
                line(52, 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalLinksList extends StatelessWidget {
  final List<MediaExternalLink> links;

  const _ExternalLinksList({required this.links});

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: context.l10n.detailsExternalLinks),
        const SizedBox(height: _Space.md),
        Wrap(
          spacing: _Space.sm,
          runSpacing: _Space.sm,
          children: [
            for (final link in links)
              _MediaChip(
                label: link.site,
                background: cs.surfaceContainerHigh,
                foreground: cs.onSurface,
                icon: Icons.open_in_new_rounded,
                onPressed: () => _open(link.url),
              ),
          ],
        ),
      ],
    );
  }
}

class _AiringBanner extends ConsumerWidget {
  final UnifiedMedia media;
  final double radius;
  final VoidCallback? onEpisodesTabRequested;

  const _AiringBanner({
    required this.media,
    this.onEpisodesTabRequested,
    required this.radius,
  });

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    SubscriptionType subType,
    String itemText,
    int number,
  ) async {
    final notifier = ref.read(notificationSubscriptionsProvider.notifier);
    await notifier.toggleSubscription(media);
    final sub = notifier.getSubscription(subType, media.id);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sub != null && sub.isEnabled
              ? 'Subscribed to $itemText $number. You will be notified when it drops.'
              : 'Notifications disabled.',
        ),
      ),
    );
  }

  void _openTab(BuildContext context, String tabText) {
    if (onEpisodesTabRequested != null) {
      onEpisodesTabRequested!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Please check the $tabText tab for the latest release.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final airingAt = media.airingAt!;
    final nextEpisode = media.nextEpisode;
    final number = nextEpisode is int ? nextEpisode : 1;
    final isManga = media.type == MediaType.MANGA;
    final itemText = isManga ? 'Chapter' : 'Episode';
    final tabText = isManga ? 'Chapters' : 'Episodes';
    final subType = isManga
        ? SubscriptionType.mangaChapter
        : SubscriptionType.animeAiring;

    final subscription = ref.watch(
      notificationSubscriptionsProvider,
    )['${subType.name}_${media.id}'];
    final isSubscribed = subscription?.isEnabled == true;
    final isMissed =
        subscription != null &&
        subscription.isEnabled &&
        subscription.upcomingTime != null &&
        subscription.upcomingTime!.isBefore(DateTime.now());
    final supportsNotifications =
        Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

    final background = isMissed ? cs.errorContainer : cs.primaryContainer;
    final foreground = isMissed ? cs.onErrorContainer : cs.onPrimaryContainer;
    final accent = isMissed ? cs.error : cs.primary;
    final onAccent = isMissed ? cs.onError : cs.onPrimary;

    return Container(
      padding: const EdgeInsets.all(_Space.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Icon(
              isMissed ? Icons.history_rounded : Icons.timer_outlined,
              size: 24,
              color: onAccent,
            ),
          ),
          const SizedBox(width: _Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemText $number',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                if (isMissed) ...[
                  Text(
                    'You missed the notification for $itemText $number',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openTab(context, tabText),
                    style: TextButton.styleFrom(
                      foregroundColor: foreground,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: Text('Open $tabText tab'),
                  ),
                ] else
                  Text.rich(
                    TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: foreground,
                      ),
                      children: [
                        const TextSpan(text: 'Airing in '),
                        TextSpan(
                          text: formatCountdown(airingAt),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (supportsNotifications) ...[
            const SizedBox(width: _Space.sm),
            Semantics(
              button: true,
              label: isSubscribed
                  ? 'Notifications enabled'
                  : 'Enable notifications',
              child: Material(
                color: isSubscribed
                    ? accent
                    : foreground.withValues(alpha: 0.1),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _toggle(context, ref, subType, itemText, number),
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          NotificationSubscriptionSheet(media: media),
                    );
                  },
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      isSubscribed
                          ? (subscription!.mode == SubscriptionMode.entireSeason
                                ? Icons.notifications_active
                                : Icons.notifications)
                          : Icons.notifications_outlined,
                      color: isSubscribed ? onAccent : foreground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
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
    final isWide = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
    );
    final cardHeight = style.getLayout(isWideMode: isWide).height;

    final grouped = <String, List<UnifiedMedia>>{};
    for (final relation in relations) {
      if (relation.type != parentType) continue;
      final label = _sentenceCase(relation.relationType ?? 'Other');
      grouped.putIfAbsent(label, () => []).add(relation);
    }

    if (grouped.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: context.l10n.detailsRelations),
        const SizedBox(height: _Space.sm),
        for (final entry in grouped.entries) ...[
          _SubLabel(entry.key),
          const SizedBox(height: _Space.sm),
          HorizontalSection<UnifiedMedia>(
            headerPadding: EdgeInsets.zero,
            listPadding: EdgeInsets.zero,
            data: AsyncValue.data(entry.value),
            height: cardHeight,
            gap: _Space.md,
            itemBuilder: (context, relation) {
              return MediaCard(
                media: relation,
                tag: 'details-${relation.id}',
                onTap: () => context.pushReplacementDetails(
                  mediaType: relation.type,
                  media: relation,
                  tag: 'details-${relation.id}',
                ),
                style: style,
              );
            },
          ),
          if (entry.key != grouped.keys.last) const SizedBox(height: _Space.xl),
        ],
      ],
    );
  }
}

class _RecommendationsList extends ConsumerWidget {
  final List<UnifiedMedia> recommendations;

  const _RecommendationsList({required this.recommendations});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(uiPrefsProvider.select((s) => s.cardStyle));
    final isWide = ref.watch(
      uiPrefsProvider.select((s) => s.isMediaCardWide(style.name)),
    );
    final cardHeight = style.getLayout(isWideMode: isWide).height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: context.l10n.detailsRecommendations),
        const SizedBox(height: _Space.md),
        HorizontalSection<UnifiedMedia>(
          data: AsyncValue.data(recommendations),
          height: cardHeight,
          gap: _Space.md,
          listPadding: EdgeInsets.zero,
          itemBuilder: (context, rec) {
            return MediaCard(
              media: rec,
              tag: 'details-rec-${rec.id}',
              onTap: () => context.pushReplacementDetails(
                mediaType: rec.type,
                media: rec,
                tag: 'details-rec-${rec.id}',
              ),
              style: style,
            );
          },
        ),
      ],
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

class _SynopsisState extends State<Synopsis> {
  bool _isExpanded = false;

  static final _lineBreak = RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false);
  static final _openTag = RegExp(r'<\s*(b|i)\s*>', caseSensitive: false);
  static final _closeTag = RegExp(r'<\s*/\s*(b|i)\s*>', caseSensitive: false);
  static final _styled = RegExp(r'<(b|i)>(.*?)</\1>', dotAll: true);
  static final _otherTags = RegExp(r'<[^>]+>');

  String _plain(String value) => value.replaceAll(_otherTags, '');

  List<InlineSpan> _spans(String text) {
    final normalized = text
        .replaceAll(_lineBreak, '\n')
        .replaceAllMapped(_openTag, (m) => '<${m[1]!.toLowerCase()}>')
        .replaceAllMapped(_closeTag, (m) => '</${m[1]!.toLowerCase()}>');

    final spans = <InlineSpan>[];
    var last = 0;

    for (final match in _styled.allMatches(normalized)) {
      if (match.start > last) {
        spans.add(
          TextSpan(text: _plain(normalized.substring(last, match.start))),
        );
      }
      final isBold = match[1] == 'b';
      spans.add(
        TextSpan(
          text: _plain(match[2]!),
          style: isBold
              ? const TextStyle(fontWeight: FontWeight.w700)
              : const TextStyle(fontStyle: FontStyle.italic),
        ),
      );
      last = match.end;
    }

    if (last < normalized.length) {
      spans.add(TextSpan(text: _plain(normalized.substring(last))));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1.55,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Synopsis'),
        const SizedBox(height: _Space.sm),
        if (widget.isLoading)
          const _SynopsisSkeleton()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final span = TextSpan(
                style: textStyle,
                children: _spans(widget.description),
              );
              final painter = TextPainter(
                text: span,
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout(maxWidth: constraints.maxWidth);
              final collapsible = painter.height > widget.collapsedHeight;
              painter.dispose();
              final collapsed = collapsible && !_isExpanded;

              Widget body = ConstrainedBox(
                constraints: collapsed
                    ? BoxConstraints(maxHeight: widget.collapsedHeight)
                    : const BoxConstraints(),
                child: Text.rich(span),
              );

              if (collapsed) {
                body = ShaderMask(
                  blendMode: BlendMode.dstOut,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0.0, 0.4],
                  ).createShader(bounds),
                  child: body,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: body,
                  ),
                  if (collapsible) ...[
                    const SizedBox(height: _Space.sm),
                    FilledButton.tonalIcon(
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      style: FilledButton.styleFrom(
                        shape: _stadium,
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(
                          horizontal: _Space.lg,
                          vertical: _Space.sm,
                        ),
                      ),
                      icon: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                        ),
                      ),
                      iconAlignment: IconAlignment.end,
                      label: Text(_isExpanded ? 'Show less' : 'Read more'),
                    ),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

class _SynopsisSkeleton extends StatelessWidget {
  const _SynopsisSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.surfaceContainerHigh.withValues(alpha: 0.5);

    Widget line(double width) => Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        line(double.infinity),
        const SizedBox(height: _Space.sm),
        line(double.infinity),
        const SizedBox(height: _Space.sm),
        line(MediaQuery.sizeOf(context).width * 0.6),
      ],
    );
  }
}
