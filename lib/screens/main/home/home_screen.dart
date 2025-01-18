import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/settings/settings_screen.dart';
import 'package:nekoflow/widgets/spotlight_card.dart';
import 'package:nekoflow/widgets/trending_animes.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nekoflow/data/models/anime_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/widgets/anime_card.dart';
import 'package:nekoflow/widgets/snapping_scroll.dart';

class HomeScreen extends StatefulWidget {
  static const double _horizontalPadding = 20.0;
  static const double _sectionSpacing = 50.0;

  final String name;

  const HomeScreen({super.key, this.name = 'Guest'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnimeService _animeService = AnimeService();

  List<TopAiringAnime> _topAiring = [];
  List<LatestCompletedAnime> _completed = [];
  List<MostPopularAnime> _popular = [];
  List<SpotlightAnime> _spotlight = [];
  List<LatestEpisodeAnime> _latestEpisode = [];
  List<MostFavoriteAnime> _mostFavourite = [];
  List<UpcomingAnime> _upcoming = [];
  List<TrendingAnime> _trending = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final results = await _animeService.fetchHome();
      if (!mounted) return;

      setState(() {
        _spotlight = results.data.spotlightAnimes;
        _topAiring = results.data.topAiringAnimes;
        _popular = results.data.mostPopularAnimes;
        _completed = results.data.latestCompletedAnimes;
        _latestEpisode = results.data.latestEpisodeAnimes;
        _mostFavourite = results.data.mostFavoriteAnimes;
        _upcoming = results.data.topUpcomingAnimes;
        _trending = results.data.trendingAnimes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _animeService.dispose();
    super.dispose();
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "Hello ${widget.name}, What's on your mind today?",
            style: theme.textTheme.headlineLarge
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Find your favourite anime and \nwatch it right away",
            style: TextStyle(color: theme.colorScheme.primary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme, double factor) {
    final width = MediaQuery.of(context).size.width;
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.primaryContainer,
      highlightColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
      child: Padding(
        padding: EdgeInsets.only(bottom: factor > 0.8 ? 20 : 0),
        child: SizedBox(
          height: width * 0.64,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            padding: EdgeInsets.zero,
            itemBuilder: (_, __) => Card(
              child: Container(
                height: double.infinity,
                width: width * factor,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSpotlightSection({
    required String title,
    required List<SpotlightAnime> animeList,
    required String tag,
    required ThemeData theme,
  }) {
    if (animeList.isEmpty && !_isLoading) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 10),
        ],
        _isLoading
            ? Column(
              children: [
                _buildShimmerLoading(theme, 0.9),
                SizedBox(height: 8,),
              ],
            )
            : SnappingScroller(
                autoScroll: true,
                widthFactor: 1,
                children: animeList
                    .map((anime) => SpotlightCard(anime: anime, tag: tag))
                    .toList(),
              ),
      ],
    );
  }

  Widget? _buildContentSection({
    required String title,
    required List<BaseAnimeCard> animeList,
    required String tag,
    required ThemeData theme,
  }) {
    if (animeList.isEmpty && !_isLoading) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        _isLoading
            ? _buildShimmerLoading(theme, 0.42)
            : SnappingScroller(
                showIndicators: false,
                widthFactor: 0.47,
                autoScroll: false,
                children: animeList
                    .map((anime) => AnimeCard(anime: anime, tag: tag))
                    .toList(),
              ),
      ],
    );
  }

  List<Widget> _buildContentSections(ThemeData theme) {
    final sections = <Widget>[];

    // Spotlight Section
    final spotlightSection = _buildSpotlightSection(
      title: "",
      animeList: _spotlight,
      tag: "spotlight",
      theme: theme,
    );
    if (spotlightSection != null) {
      sections.add(spotlightSection);
      sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
    }

    // Content Sections
    final contentSections = [
      {"title": "Popular", "animeList": _popular, "tag": "popular"},
      {"title": "Top Airing", "animeList": _topAiring, "tag": "topairing"},
      {
        "title": "Most Favourite",
        "animeList": _mostFavourite,
        "tag": "mostFavourite"
      },
      {
        "title": "Latest Completed",
        "animeList": _completed,
        "tag": "latestcompleted"
      },
      {"title": "Top Upcoming", "animeList": _upcoming, "tag": "upcoming"},
      {
        "title": "Latest Episodes",
        "animeList": _latestEpisode,
        "tag": "latestEpisodes"
      },
    ];

    for (var section in contentSections) {
      final contentSection = _buildContentSection(
        title: section['title'] as String,
        animeList: section['animeList'] as List<BaseAnimeCard>,
        tag: section['tag'] as String,
        theme: theme,
      );
      if (contentSection != null) {
        sections.add(contentSection);
        sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
      }
    }

    // Remove last spacing if it exists
    if (sections.isNotEmpty && sections.last is SizedBox) {
      sections.removeLast();
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                CupertinoPageRoute(builder: (context) => SettingsScreen())),
            icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSettings01,
                color: theme.colorScheme.onSurface),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: HomeScreen._horizontalPadding),
          child: ListView(
            children: [
              _buildHeaderSection(theme),
              ..._buildContentSections(theme),
              const SizedBox(height: 50),
              Text("Trending Anime", style: theme.textTheme.headlineMedium),
              const SizedBox(height: 10),
              TrendingAnimes(trendingAnimes: _trending),
            ],
          ),
        ),
      ),
    );
  }
}
