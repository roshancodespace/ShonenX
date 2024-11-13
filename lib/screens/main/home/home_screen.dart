import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nekoflow/data/models/anime_interface.dart';
import 'package:nekoflow/data/models/anime_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/widgets/anime_card.dart';
import 'package:nekoflow/widgets/snapping_scroll.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  const HomeScreen({super.key, this.userName = 'Guest'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnimeService _animeService = AnimeService();
  List<TopAiringAnime> _topAiring = [];
  List<LatestCompletedAnime> _completed = [];
  List<MostPopularAnime> _popular = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _animeService.fetchHome();
      if (mounted) {
        setState(() {
          _topAiring = results.data.topAiringAnimes;
          _popular = results.data.mostPopularAnimes;
          _completed = results.data.latestCompletedAnimes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animeService.dispose();
    super.dispose();
  }

  Widget _buildHeaderSection() {
    ThemeData themeData =
        Theme.of(context); // Use the ThemeManager to get the theme data
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.3,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hello ${widget.userName}, What's on your mind today?",
              style: themeData.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold), // Use the theme data
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Find your favourite anime and \nwatch it right away",
              style: TextStyle(
                  color: themeData.colorScheme.secondary), // Use the theme data
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final screenSize = MediaQuery.of(context).size;
    ThemeData themeData =
        Theme.of(context); // Use the ThemeManager to get the theme data
    return Shimmer.fromColors(
      baseColor:
          themeData.colorScheme.surface.withOpacity(0.5), // Use the theme data
      highlightColor: themeData.colorScheme.onSurface
          .withOpacity(0.2), // Use the theme data
      child: SizedBox(
        height: screenSize.height * 0.25,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 5,
          itemBuilder: (_, __) => Container(
            height: double.infinity,
            width: screenSize.width * 0.4,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: themeData.colorScheme.surface, // Use the theme data
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection({
    required String title,
    required List<Anime> animeList,
    required String tag,
  }) {
    ThemeData themeData =
        Theme.of(context); // Use the ThemeManager to get the theme data
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
            title, themeData), // Pass the theme data to the section title
        const SizedBox(height: 10),
        _isLoading
            ? _buildShimmerLoading()
            : SnappingScroller(
                widthFactor: 0.48,
                children: animeList
                    .map((anime) => AnimeCard(anime: anime, tag: tag))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData themeData) {
    return Text(
      title,
      style: themeData.textTheme.headlineMedium, // Use the theme data
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(toolbarHeight: 0),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: ListView(
            children: [
              _buildHeaderSection(),
              _buildContentSection(
                title: "Recommended",
                animeList: _popular,
                tag: "recommended",
              ),
              const SizedBox(height: 50),
              _buildContentSection(
                title: "Top Airing",
                animeList: _topAiring,
                tag: "topairing",
              ),
              const SizedBox(height: 50),
              _buildContentSection(
                title: "Latest Completed",
                animeList: _completed,
                tag: "latestcompleted",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
