import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart';
import 'package:shonenx/api/models/anilist/anilist_user.dart';
import 'package:shonenx/api/models/anime/page_model.dart';
import 'package:shonenx/data/hive/boxes/continue_watching_box.dart';
import 'package:shonenx/helpers/navigation.dart';
import 'package:shonenx/providers/anilist/anilist_user_provider.dart';
import 'package:shonenx/providers/homepage_provider.dart';
import 'package:shonenx/utils/greeting_methods.dart';
import 'package:shonenx/widgets/anime/anime_card.dart';
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
  final ContinueWatchingBox continueWatchingBox = ContinueWatchingBox();
  bool _isBoxInitialized = false;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeContinueWatchingBox();
  }

  Future<void> _initializeContinueWatchingBox() async {
    await continueWatchingBox.init();
    if (mounted) {
      setState(() {
        _isBoxInitialized = true;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.offset > 20 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 20 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 900;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Consumer(
          builder: (context, ref, child) {
            final homePageAsync = ref.watch(homePageProvider);
            return homePageAsync.when(
              data: (homePage) => _HomeContent(
                continueWatchingBox:
                    _isBoxInitialized ? continueWatchingBox : null,
                homePage: homePage,
                isDesktop: isDesktop,
              ),
              error: (error, stack) => _HomeContent(
                continueWatchingBox:
                    _isBoxInitialized ? continueWatchingBox : null,
                homePage: null,
                isDesktop: isDesktop,
              ),
              loading: () => _HomeContent(
                continueWatchingBox:
                    _isBoxInitialized ? continueWatchingBox : null,
                homePage: null,
                isDesktop: isDesktop,
                isLoading: true,
              ),
            );
          },
        ),
      ),
      floatingActionButton: isDesktop
          ? FloatingActionButton.extended(
              onPressed: () => _toggleSearchBar(context),
              label: const Text('Search anime...'),
              icon: Icon(
                Iconsax.search_normal,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }

  void _toggleSearchBar(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return AlertDialog(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          content: SearchBar(
            padding: WidgetStateProperty.all(const EdgeInsets.only(left: 15)),
            leading: Icon(
              Iconsax.search_normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            autoFocus: true,
            hintText: 'Search for anime...',
            onSubmitted: (value) {
              Navigator.pop(context);
              context.go('/browse?keyword=$value');
            },
          ),
        );
      },
    );
  }
}

class _HomeContent extends ConsumerWidget {
  final HomePage? homePage;
  final ContinueWatchingBox? continueWatchingBox;
  final bool isDesktop;
  final bool isLoading;

  const _HomeContent({
    required this.homePage,
    required this.isDesktop,
    required this.continueWatchingBox,
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
          _SpotlightSection(
            homePage: homePage,
            isLoading: isLoading,
          ),
          const SizedBox(height: 30),
          if (continueWatchingBox != null)
            ContinueWatchingView(
              continueWatchingBox: continueWatchingBox!,
            ),
          _HorizontalAnimeSection(
            title: 'Popular',
            animes: homePage?.popularAnime,
          ),
          _HorizontalAnimeSection(
            title: 'Trending',
            animes: homePage?.trendingAnime,
          ),
          _HorizontalAnimeSection(
            title: 'Recently Updated',
            animes: homePage?.recentlyUpdated,
          ),
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
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface,
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _UserInfo(user: user)),
              _ActionButtons(isDesktop: isDesktop),
            ],
          ),
          const SizedBox(height: 24),
          _DiscoverAnimeButton(),
        ],
      ),
    );
  }
}

class _UserInfo extends StatelessWidget {
  final User? user;

  const _UserInfo({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            user == null ? _GuestIcon() : _UserAvatar(user: user!),
            const SizedBox(width: 12),
            Text(
              getGreeting(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user?.name ?? 'Guest',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _GuestIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Iconsax.user,
        color: theme.colorScheme.primary,
        size: 20,
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final User user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: () => context.push('/settings/profile'),
        child: CachedNetworkImage(
          imageUrl: user.avatar ?? '',
          fit: BoxFit.cover,
          height: 42,
          width: 42,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
          ),
          errorWidget: (context, url, error) => const Icon(Iconsax.user),
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isDesktop;

  const _ActionButtons({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        if (!isDesktop) ...[
          IconButton(
            onPressed: () => _toggleSearchBar(context),
            icon: Icon(
              Iconsax.search_normal,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 8),
        ],
        InkWell(
          onTap: () => context.push('/settings'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Iconsax.setting_2,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }

  void _toggleSearchBar(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return AlertDialog(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          content: SearchBar(
            padding: WidgetStateProperty.all(const EdgeInsets.only(left: 15)),
            leading: Icon(
              Iconsax.search_normal,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            autoFocus: true,
            hintText: 'Search for anime...',
            onSubmitted: (value) {
              Navigator.pop(context);
              context.go('/browse?keyword=$value');
            },
          ),
        );
      },
    );
  }
}

class _DiscoverAnimeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.go('/browse'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.3),
              theme.colorScheme.primary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Iconsax.discover_1,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Anime',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore your next favorite series',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Iconsax.arrow_right_3,
              color: theme.colorScheme.primary,
            ),
          ],
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
        ? List.filled(9, null)
        : homePage?.trendingAnime ?? List.filled(9, Media(id: null));
    // final theme = Theme.of(context);
    final carouselHeight =
        MediaQuery.sizeOf(context).width > 900 ? 500.0 : 230.0;

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
            enlargeStrategy: CenterPageEnlargeStrategy.height,
            autoPlayInterval: const Duration(seconds: 5),
            enableInfiniteScroll: true,
            slideIndicator: CustomSlideIndicator(context),
            viewportFraction:
                MediaQuery.sizeOf(context).width > 900 ? 0.7 : 0.85,
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
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
                Icon(
                  Iconsax.star5,
                  size: 18,
                  color: theme.colorScheme.tertiary,
                ),
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimeSpotlightCard(
          onTap: (media) => navigateToDetail(
            context,
            media,
            anime?.id.toString() ?? 'loading',
          ),
          anime: anime,
          heroTag: anime?.id.toString() ?? 'loading',
        ),
      ),
    );
  }
}

class _HorizontalAnimeSection extends StatelessWidget {
  final String title;
  final List<Media>? animes;

  const _HorizontalAnimeSection({
    required this.title,
    required this.animes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: animes?.length ?? 10,
              itemBuilder: (context, index) {
                final anime = animes?[index];
                final tag = const Uuid().v4();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => navigateToDetail(context, anime!, tag),
                    child: AnimeCard(
                      anime: anime,
                      tag: tag,
                      mode: AnimeCardMode.card,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
