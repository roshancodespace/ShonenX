import 'package:flutter/material.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/widgets/spotlight_card.dart';
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
  bool _isLoading = true;
  // String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      // _error = null;
    });

    try {
      final results = await _animeService.fetchHome();
      if (!mounted) return;

      setState(() {
        _spotlight = results.data.spotlightAnimes;
        _topAiring = results.data.topAiringAnimes;
        _popular = results.data.mostPopularAnimes;
        _completed = results.data.latestCompletedAnimes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        // _error = 'Something went wrong';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animeService.dispose();
    super.dispose();
  }

  Widget _buildHeaderSection(ThemeData theme) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.3,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
            style: TextStyle(color: theme.colorScheme.secondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme, double factor) {
    final screenSize = MediaQuery.of(context).size;

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.primary.withOpacity(0.5),
      highlightColor: theme.colorScheme.secondary,
      child: SizedBox(
        height: screenSize.width * 0.6,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          padding: EdgeInsets.zero,
          itemBuilder: (_, __) => Container(
            height: double.infinity,
            width: screenSize.width * factor,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
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
        Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
      ],
      _isLoading
          ? _buildShimmerLoading(theme, 0.9)
          : SnappingScroller(
              autoScroll: true,
              widthFactor: 1,
              children: animeList
                  .map((anime) => SpotlightCard(
                        anime: anime,
                        tag: tag,
                      ))
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
        Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        _isLoading
            ? _buildShimmerLoading(theme, 0.4)
            : SnappingScroller(
              showIndicators: false,
                widthFactor: 0.48,
                children: animeList
                    .map((anime) => AnimeCard(anime: anime, tag: tag))
                    .toList(),
              ),
      ],
    );
  }

  List<Widget> _buildContentSections(ThemeData theme) {
    final sections = <Widget>[];
    Widget? section;

    // Spotlight Section
    section = _buildSpotlightSection(
      title: "",
      animeList: _spotlight,
      tag: "spotlight",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
      sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
    }

    // Popular Section
    section = _buildContentSection(
      title: "Popular",
      animeList: _popular,
      tag: "popular",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
      sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
    }

    // Top Airing Section
    section = _buildContentSection(
      title: "Top Airing",
      animeList: _topAiring,
      tag: "topairing",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
      sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
    }

    // Latest Completed Section
    section = _buildContentSection(
      title: "Latest Completed",
      animeList: _completed,
      tag: "latestcompleted",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
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
      appBar: AppBar(toolbarHeight: 0),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: HomeScreen._horizontalPadding),
          child: ListView(
            children: [
              _buildHeaderSection(theme),
              ..._buildContentSections(theme),
            ],
          ),
        ),
      ),
    );
  }
}
