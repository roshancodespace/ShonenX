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
import 'package:shonenx/helpers/provider.dart';
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
  late final AnimeWatchProgressBox _animeWatchProgressBox;
  late final SettingsBox _settingsBox;
  late UISettingsModel _uiSettings;
  bool _isBoxInitialized = false;
  // bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeBoxes();
  }

  Future<void> _initializeBoxes() async {
    _animeWatchProgressBox = AnimeWatchProgressBox();
    _settingsBox = SettingsBox();
    await Future.wait([
      _animeWatchProgressBox.init(),
      _settingsBox.init(),
    ]);
    _uiSettings = _settingsBox.getUISettings();
    _isBoxInitialized = true;
    if (mounted) setState(() {});
  }

  void _onScroll() {
    // _isScrolled = _scrollController.offset > 20;
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    getAnimeProvider(ref); // Initialized here for now will change later
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    final theme = Theme.of(context);

    if (!_isBoxInitialized) return const SizedBox.shrink();

    return Scaffold(
      extendBodyBehindAppBar: true,
      floatingActionButton: isDesktop ? _buildFAB(theme) : null,
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, _) => ref.watch(homePageProvider).when(
                data: (homePage) => _HomeContent(
                  animeWatchProgressBox: _animeWatchProgressBox,
                  settingsBox: _settingsBox,
                  homePage: homePage,
                  isDesktop: isDesktop,
                  uiSettings: _uiSettings,
                  onRefresh: () => ref.refresh(homePageProvider),
                ),
                error: (_, __) => _HomeContent(
                  animeWatchProgressBox: _animeWatchProgressBox,
                  settingsBox: _settingsBox,
                  homePage: null,
                  isDesktop: isDesktop,
                  uiSettings: _uiSettings,
                  onRefresh: () => ref.refresh(homePageProvider),
                ),
                loading: () => const _HomeContentLoading(),
              ),
        ),
      ),
    );
  }

  FloatingActionButton _buildFAB(ThemeData theme) =>
      FloatingActionButton.extended(
        backgroundColor: theme.colorScheme.primaryContainer,
        onPressed: () => _showSearchDialog(context),
        label: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.3,
          child: Text('Search anime...',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
        ),
        icon: Icon(Iconsax.search_normal,
            color: theme.colorScheme.onPrimaryContainer),
      );

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _SearchDialog(),
    );
  }
}

class _SearchDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      backgroundColor: theme.colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
      content: SearchBar(
        padding: const WidgetStatePropertyAll(EdgeInsets.only(left: 15)),
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

class _HomeContent extends StatelessWidget {
  final HomePage? homePage;
  final AnimeWatchProgressBox animeWatchProgressBox;
  final SettingsBox settingsBox;
  final bool isDesktop;
  final UISettingsModel uiSettings;
  final VoidCallback onRefresh;

  const _HomeContent({
    required this.homePage,
    required this.animeWatchProgressBox,
    required this.settingsBox,
    required this.isDesktop,
    required this.uiSettings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _HeaderSection(isDesktop: isDesktop)),
          SliverToBoxAdapter(child: _SpotlightSection(homePage: homePage)),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
          SliverToBoxAdapter(
              child: ContinueWatchingView(
                  animeWatchProgressBox: animeWatchProgressBox)),
          _HorizontalAnimeSection(
              settingsBox: settingsBox,
              title: 'Popular',
              animes: homePage?.popularAnime,
              uiSettings: uiSettings),
          _HorizontalAnimeSection(
              settingsBox: settingsBox,
              title: 'Trending',
              animes: homePage?.trendingAnime,
              uiSettings: uiSettings),
          _HorizontalAnimeSection(
              settingsBox: settingsBox,
              title: 'Recently Updated',
              animes: homePage?.recentlyUpdated,
              uiSettings: uiSettings),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _HomeContentLoading extends StatelessWidget {
  const _HomeContentLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _HeaderSection extends ConsumerWidget {
  final bool isDesktop;

  const _HeaderSection({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final theme = Theme.of(context);
    final user = ref.watch(userProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: UserProfileCard(user: user)),
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
        side:
            BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
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
                  Text(getGreeting(),
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7))),
                  const SizedBox(height: 4),
                  Text(
                    user?.name ?? 'Guest',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
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
    return user == null
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16)),
            child:
                Icon(Iconsax.user, size: 24, color: theme.colorScheme.primary),
          )
        : Hero(
            tag: 'user-avatar',
            child: Material(
              elevation: 2,
              shadowColor: theme.shadowColor.withValues(alpha: 0.2),
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
                    placeholder: (_, __) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.person_outline,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.errorContainer,
                      child: Icon(Icons.error_outline,
                          color: theme.colorScheme.error),
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
          const _ActionButton(icon: Iconsax.search_normal, route: null),
          const SizedBox(width: 12),
        ],
        const _ActionButton(icon: Iconsax.setting_2, route: '/settings'),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? route;

  const _ActionButton({required this.icon, this.route});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: route != null
            ? () => context.push(route!)
            : () => _showSearch(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: theme.colorScheme.secondary),
        ),
      ),
    );
  }

  void _showSearch(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Search",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, animation, __) => ScaleTransition(
        scale: animation,
        child: _SearchDialog(),
      ),
    );
  }
}

class DiscoverCard extends StatelessWidget {
  const DiscoverCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => context.go('/browse'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.15),
              theme.colorScheme.primary.withValues(alpha: 0.05)
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.explore,
                  color: theme.colorScheme.primary, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover Anime',
                      style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                  const SizedBox(height: 4),
                  Text('Find your next favorite series',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: theme.colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SpotlightSection extends StatelessWidget {
  final HomePage? homePage;

  const _SpotlightSection({required this.homePage});

  @override
  Widget build(BuildContext context) {
    final trendingAnimes =
        homePage?.trendingAnime ?? List<Media?>.filled(9, null);
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
            autoPlayInterval: const Duration(seconds: 5),
            enlargeStrategy: CenterPageEnlargeStrategy.height,
            enableInfiniteScroll: true,
            floatingIndicator: false,
            slideIndicator: CustomSlideIndicator(context),
            viewportFraction:
                MediaQuery.sizeOf(context).width > 900 ? 0.9 : 0.9,
            pageSnapping: true,
          ),
          items: trendingAnimes
              .map((anime) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                    child: AnimeSpotlightCard(
                      onTap: (media) => anime?.id != null
                          ? navigateToDetail(
                              context, media, anime!.id.toString())
                          : null,
                      anime: anime,
                      heroTag: anime?.id.toString() ?? 'loading',
                    ),
                  ))
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.star5, size: 18, color: theme.colorScheme.tertiary),
            const SizedBox(width: 8),
            Text(
              'Trending ${homePage?.trendingAnime.length ?? 0}',
              style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalAnimeSection extends SliverToBoxAdapter {
  final String title;
  final SettingsBox settingsBox;
  final List<Media>? animes;
  final UISettingsModel uiSettings;

  const _HorizontalAnimeSection({
    required this.title,
    required this.animes,
    required this.uiSettings,
    required this.settingsBox,
  });

  double _getCardWidth(BuildContext context, String mode) {
    final screenWidth = MediaQuery.of(context).size.width;
    return switch (mode) {
      'Card' => screenWidth < 600 ? 140.0 : 160.0,
      'Compact' => screenWidth < 600 ? 100.0 : 120.0,
      'Poster' => screenWidth < 600 ? 160.0 : 180.0,
      'Glass' => screenWidth < 600 ? 150.0 : 170.0,
      'Neon' => screenWidth < 600 ? 140.0 : 160.0,
      'Minimal' => screenWidth < 600 ? 130.0 : 150.0,
      'Cinematic' => screenWidth < 600 ? 200.0 : 240.0,
      _ => screenWidth < 600 ? 140.0 : 160.0, // Default to Card
    };
  }

  double _getCardHeight(BuildContext context, String mode) {
    final screenWidth = MediaQuery.of(context).size.width;
    return switch (mode) {
      'Card' => screenWidth < 600 ? 200.0 : 240.0,
      'Compact' => screenWidth < 600 ? 150.0 : 180.0,
      'Poster' => screenWidth < 600 ? 260.0 : 300.0,
      'Glass' => screenWidth < 600 ? 220.0 : 260.0,
      'Neon' => screenWidth < 600 ? 200.0 : 240.0,
      'Minimal' => screenWidth < 600 ? 180.0 : 220.0,
      'Cinematic' => screenWidth < 600 ? 100.0 : 160.0,
      _ => screenWidth < 600 ? 200.0 : 240.0, // Default to Card
    };
  }

  @override
  Widget get child {
    return Builder(
      builder: (context) {
        final cardStyle = uiSettings.cardStyle;
        final cardWidth = _getCardWidth(context, cardStyle);
        final cardHeight = _getCardHeight(context, cardStyle);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            SizedBox(
              height: cardHeight,
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: animes?.length ?? 10,
                itemBuilder: (context, index) {
                  final anime = animes?[index];
                  final tag = const Uuid().v4();
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: ValueListenableBuilder(
                      valueListenable: settingsBox.settingsBoxListenable,
                      builder: (context, value, child) {
                        final cardMode = settingsBox.getUISettings().cardStyle;
                        return SizedBox(
                          width: cardWidth,
                          child: AnimatedAnimeCard(
                            anime: anime,
                            tag: tag,
                            mode: cardMode,
                            onTap: () => anime != null
                                ? navigateToDetail(context, anime, tag)
                                : null,
                          ),
                        );
                      },
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
