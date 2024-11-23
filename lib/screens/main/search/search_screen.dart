import 'package:flutter/material.dart';
import 'package:nekoflow/data/models/search_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/widgets/result_card.dart';
import 'package:nekoflow/widgets/search_bar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AnimeService _animeService = AnimeService();
  SearchModel? _searchResult;
  bool _isLoading = false;
  String? _error;

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _animeService.fetchByQuery(
        query: _searchController.text,
        page: 1,
      );
      setState(() {
        _searchResult = result;
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred. Please try again.';
      });
    } finally {
      setState(
        () {
          _isLoading = false;
        },
      );
    }
  }

  Widget _buildResultSection() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null) {
      return Expanded(
        child: Center(
          child: Text(_error!),
        ),
      );
    }
    if (_searchResult == null) {
      return const Expanded(
        child: Center(
          child: Text("Search it up"),
        ),
      );
    }
    return Expanded(
      child: ListView.builder(
        itemCount: _searchResult!.animes.length,
        itemBuilder: (context, index) =>
            ResultCard(anime: _searchResult!.animes[index]),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Searchbar(
              controller: _searchController,
              onSearch: _performSearch,
            ),
            const SizedBox(height: 15),
            _buildResultSection(),
          ],
        ),
      ),
    );
  }
}
