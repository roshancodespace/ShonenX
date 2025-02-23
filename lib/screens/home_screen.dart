import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/api/models/anilist/anilist_user.dart';
import 'package:shonenx/api/models/anime/page_model.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';
import 'package:shonenx/providers/homepage_provider.dart';
import 'package:shonenx/utils/greeting_methods.dart';
import 'package:shonenx/widgets/anime/anime_card_v2.dart';
import 'package:shonenx/widgets/anime/anime_spotlight_card.dart';
import 'package:shonenx/widgets/anime/continue_watching_view.dart';
import 'package:shonenx/widgets/ui/slide_indicator.dart';
import 'package:uuid/uuid.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isBoxInitialized = false;
  late final AnimeWatchProgressBox _animeWatchProgressBox;
  late final SettingsBox _settingsBox;
  late final UISettingsModel _uiSettings;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    _animeWatchProgressBox = AnimeWatchProgressBox();
    _settingsBox = SettingsBox();
    await _animeWatchProgressBox.init();
    await _settingsBox.init();
    _uiSettings = _settingsBox.getUISettings();
    isBoxInitialized = true;
    if (mounted) setState(() {});
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    setState(() => _isScrolled = offset > 20);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    final theme = Theme.of(context);
    if (!isBoxInitialized) return const SizedBox.shrink();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final homePageAsync = ref.watch(homePageProvider);
            return homePageAsync.when(
              data: (homePage) => ValueListenableBuilder(
                valueListenable: _settingsBox.settingsBoxListenable,
                builder: (context, box, child) {
                  final uiSettings = _settingsBox.getUISettings();
                  return _HomeContent(
                    animeWatchProgressBox:
                        isBoxInitialized ? _animeWatchProgressBox : null,
                    homePage: homePage,
                    isDesktop: isDesktop,
                    uiSettings: uiSettings,
                  );
                },
              ),
              error: (error, stack) => _HomeContent(
                animeWatchProgressBox:
                    isBoxInitialized ? _animeWatchProgressBox : null,
                homePage: null,
                isDesktop: isDesktop,
                uiSettings: _uiSettings,
              ),
              loading: () => _HomeContent(
                animeWatchProgressBox:
                    isBoxInitialized ? _animeWatchProgressBox : null,
                homePage: null,
                isDesktop: isDesktop,
                isLoading: true,
                uiSettings: _uiSettings,
              ),
            );
          },
        ),
      ),
      floatingActionButton:
          isDesktop ? _buildFloatingActionButton(theme) : null,
    );
  }

  FloatingActionButton _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton.extended(
      backgroundColor: theme.colorScheme.primaryContainer,
      onPressed: () => _toggleSearchBar(context),
      label: Text(
        'Search anime...',
        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
      ),
      icon: Icon(
        Iconsax.search_normal,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }

  void _toggleSearchBar(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _buildSearchDialog(context),
    );
  }

  AlertDialog _buildSearchDialog(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      backgroundColor: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      content: SearchBar(
        padding: WidgetStatePropertyAll(EdgeInsets.only(left: 15)),
        leading:
            Icon(Iconsax.search_normal, color: theme.colorScheme.onSurface),
        autoFocus: true,
        hintText: 'Search for anime...',
        onSubmitted: (value) {
          Navigator.pop(context);
          context.go('/browse?keyword=$value');
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final HomePage? homePage;
  final AnimeWatchProgressBox? animeWatchProgressBox;
  final bool isDesktop;
  final bool isLoading;
  final UISettingsModel uiSettings;

  const _HomeContent({
    required this.homePage,
    required this.uiSettings,
    required this.animeWatchProgressBox,
    required this.isDesktop,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(homePageProvider);
      },
      child: ListView(
        children: [
          _HeaderSection(isDesktop: isDesktop),
          _SpotlightSection(homePage: homePage, isLoading: isLoading),
          const SizedBox(height: 30),
          if (animeWatchProgressBox != null)
            ContinueWatchingView(animeWatchProgressBox: animeWatchProgressBox!),
          _HorizontalAnimeSection(
            title: 'Popular',
            animes: homePage?.popularAnime,
            uiSettings: uiSettings,
          ),
          _HorizontalAnimeSection(
            title: 'Trending',
            animes: homePage?.trendingAnime,
            uiSettings: uiSettings,
          ),
          _HorizontalAnimeSection(
            title: 'Recently Updated',
            animes: homePage?.recentlyUpdated,
            uiSettings: uiSettings,
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _HeaderSection extends ConsumerWidget {
  final bool isDesktop;

  const _HeaderSection({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: UserProfileCard(user: user),
              ),
              const SizedBox(width: 16),
              ActionPanel(isDesktop: isDesktop),
            ],
          ),
          const SizedBox(height: 24),
          const DiscoverCard(),
        ],
      ),
    );
  }
}

class UserProfileCard extends StatelessWidget {
  final User? user;

  const UserProfileCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getGreeting(),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Guest',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);

    if (user == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Iconsax.user,
          size: 24,
          color: theme.colorScheme.primary,
        ),
      );
    }

    return Hero(
      tag: 'user-avatar',
      child: Material(
        elevation: 2,
        shadowColor: theme.shadowColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => context.push('/settings/profile'),
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: user!.avatar ?? '',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.errorContainer,
                child: Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActionPanel extends StatelessWidget {
  final bool isDesktop;

  const ActionPanel({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isDesktop) ...[
          _ActionButton(
            icon: Iconsax.search_normal,
            onTap: () => _showSearch(context),
          ),
          const SizedBox(width: 12),
        ],
        _ActionButton(
          icon: Iconsax.setting_2,
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }

  void _showSearch(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Search",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: animation,
          child: AlertDialog(
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SearchBar(
                padding: const MaterialStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
                leading: const Icon(Icons.search),
                hintText: 'Search anime...',
                onSubmitted: (value) {
                  Navigator.pop(context);
                  context.go('/browse?keyword=$value');
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: theme.colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

class DiscoverCard extends StatelessWidget {
  const DiscoverCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () => context.go('/browse'),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.15),
                theme.colorScheme.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.explore,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Discover Anime',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find your next favorite series',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightSection extends StatelessWidget {
  final HomePage? homePage;
  final bool isLoading;

  const _SpotlightSection({
    required this.homePage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final trendingAnimes = isLoading
        ? List<Media?>.filled(9, null)
        : homePage?.trendingAnime ?? List<Media?>.filled(9, null);
    final carouselHeight =
        MediaQuery.sizeOf(context).width > 900 ? 500.0 : 260.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SpotlightHeader(homePage: homePage),
        FlutterCarousel(
          options: FlutterCarouselOptions(
            height: carouselHeight,
            showIndicator: true,
            autoPlay: true,
            enlargeCenterPage: true,
            floatingIndicator: false,
            autoPlayInterval: const Duration(seconds: 5),
            enableInfiniteScroll: true,
            slideIndicator: CustomSlideIndicator(context),
            viewportFraction:
                MediaQuery.sizeOf(context).width > 900 ? 0.75 : 0.9,
          ),
          items: trendingAnimes
              .map((anime) => _SpotlightCard(anime: anime))
              .toList(),
        ),
      ],
    );
  }
}

class _SpotlightHeader extends StatelessWidget {
  final HomePage? homePage;

  const _SpotlightHeader({required this.homePage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.star5,
                    size: 18, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'Trending ${homePage?.trendingAnime.length ?? 0}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.tertiary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  final Media? anime;

  const _SpotlightCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimeSpotlightCard(
          onTap: (media) => anime?.id != null
              ? navigateToDetail(context, media, anime!.id.toString())
              : null,
          anime: anime,
          heroTag: anime?.id.toString() ?? 'loading',
        ),
      ),
    );
  }
}

class _HorizontalAnimeSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Media>? animes;
  final VoidCallback? onViewAll;
  final UISettingsModel uiSettings;

  const _HorizontalAnimeSection({
    super.key,
    required this.title,
    required this.animes,
    required this.uiSettings,
    this.subtitle,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final String cardStyle = uiSettings.cardStyle;
        final double cardHeight = cardStyle == 'Minimal'
            ? 240
            : cardStyle == 'Compact'
                ? 200
                : 280; // Adjust card height based on width

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onViewAll != null)
                    IconButton.filledTonal(
                      onPressed: onViewAll,
                      icon: const Icon(Iconsax.arrow_right_3),
                      tooltip: 'View all',
                    ),
                ],
              ),
            ),
            SizedBox(
              height: cardHeight, // Use dynamic height based on card size
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: animes?.length ?? 10,
                itemBuilder: (context, index) {
                  final anime = animes?[index];
                  final tag = const Uuid().v4();
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AnimatedAnimeCard(
                      anime: anime,
                      tag: tag,
                      mode: uiSettings.cardStyle,
                      onTap: () => anime != null
                          ? navigateToDetail(context, anime, tag)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
