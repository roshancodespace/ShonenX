import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/media_switcher_overlay.dart';
import 'package:shonenx/shared/widgets/unified_search_bar.dart';
import 'package:shonenx/shared/providers/navbar_action_provider.dart';
import 'package:shonenx/features/discovery/providers/metadata_tags_provider.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/advanced_search_sheet.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/source_registry.dart';

import 'widgets/discover/discover_tab_feed.dart';

class SearchDiscoverScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final MediaType type;
  final List<String> initialGenres;
  final List<String> initialTags;
  final String? source;

  const SearchDiscoverScreen({
    super.key,
    this.initialQuery,
    required this.type,
    this.initialGenres = const [],
    this.initialTags = const [],
    this.source,
  });

  @override
  ConsumerState<SearchDiscoverScreen> createState() =>
      _SearchDiscoverScreenState();
}

class _SearchDiscoverScreenState extends ConsumerState<SearchDiscoverScreen>
    with TickerProviderStateMixin {
  late final TextEditingController _searchController;
  late TabController _tabController;
  Timer? _debounceTimer;

  String _query = '';
  List<String> _genres = [];
  List<String> _tags = [];
  String? _source;

  late final FocusNode _searchFocusNode;
  late final FocusNode _keyboardFocusNode;

  List<MediaType> _supportedMediaTypes = [];

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery?.trim() ?? '';
    _searchController = TextEditingController(text: _query)
      ..addListener(_onSearchTextChanged);
    _genres = List.from(widget.initialGenres);
    _tags = List.from(widget.initialTags);
    _source = widget.source;

    _searchFocusNode = FocusNode();
    _keyboardFocusNode = FocusNode();
    _searchFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _supportedMediaTypes = ref.read(metadataSourceProvider).supportedMediaTypes;
    int initIndex = _supportedMediaTypes.indexOf(widget.type);
    if (initIndex == -1) initIndex = 0;

    _tabController = TabController(
      length: _supportedMediaTypes.length,
      vsync: this,
      initialIndex: initIndex,
    );

    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _attachOverlay();
      }
    });
  }

  void _rebuildTabController(List<MediaType> newTypes) {
    if (!mounted) return;
    _tabController.dispose();
    setState(() {
      _supportedMediaTypes = newTypes;
      _tabController = TabController(length: newTypes.length, vsync: this);
      _tabController.addListener(() {
        if (mounted && !_tabController.indexIsChanging) {
          setState(() {});
        }
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _attachOverlay();
    });
  }

  @override
  void didUpdateWidget(SearchDiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _source = widget.source;
    }
    if (oldWidget.initialQuery != widget.initialQuery) {
      _query = widget.initialQuery?.trim() ?? '';
      _searchController.text = _query;
    }

    final oldGenresStr = oldWidget.initialGenres.join(',');
    final newGenresStr = widget.initialGenres.join(',');
    if (oldGenresStr != newGenresStr) {
      _genres = List.from(widget.initialGenres);
    }

    final oldTagsStr = oldWidget.initialTags.join(',');
    final newTagsStr = widget.initialTags.join(',');
    if (oldTagsStr != newTagsStr) {
      _tags = List.from(widget.initialTags);
    }
  }

  void _attachOverlay() {
    Future.microtask(() {
      try {
        ref
            .read(navBarProvider.notifier)
            .attachTop(
              MediaSwitcherOverlay(
                controller: _tabController,
                onSearchTap: null,
                supportedTypes: _supportedMediaTypes,
              ),
              branchIndex: 1,
            );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchTextChanged);
    Future.microtask(() {
      try {
        ref.read(navBarProvider.notifier).clearTop(branchIndex: 1);
      } catch (_) {}
    });
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
    _debounceTimer?.cancel();
    final text = _searchController.text.trim();
    if (text.isEmpty && _query.isNotEmpty) {
      setState(() {
        _query = '';
      });
    }
  }

  void _submitSearch(String text) {
    _debounceTimer?.cancel();
    final trimmedText = text.trim();
    if (trimmedText.isNotEmpty) {
      final currentType =
          (_tabController.index >= 0 &&
              _tabController.index < _supportedMediaTypes.length)
          ? _supportedMediaTypes[_tabController.index]
          : MediaType.ANIME;
      context.pushFilteredDiscover(
        query: trimmedText,
        type: currentType,
        source: widget.source,
      );
    }
  }

  void _cancelSearch() {
    _debounceTimer?.cancel();
    setState(() {
      _query = '';
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  Future<void> _openAdvancedSearch(BuildContext context) async {
    final currentType =
        (_tabController.index >= 0 &&
            _tabController.index < _supportedMediaTypes.length)
        ? _supportedMediaTypes[_tabController.index]
        : MediaType.ANIME;

    MetadataTagsState? filtersState;
    try {
      filtersState = await ref.read(
        discoveryFiltersProvider((
          type: currentType,
          sourceId: widget.source,
        )).future,
      );
    } catch (_) {
      return;
    }

    final hasFilters = filtersState?.options.hasAnyFilter == true;
    if (!hasFilters) return;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      constraints: const BoxConstraints(maxWidth: 800),
      builder: (context) {
        return AdvancedSearchSheet(
          initialQuery: _query,
          type: currentType,
          initialGenres: _genres,
          initialTags: _tags,
          sourceId: widget.source,
          onApply: (query, genres, tags, sort, status, format) {
            context.pushFilteredDiscover(
              query: query.trim(),
              genres: genres,
              tags: tags,
              sort: sort,
              status: status,
              format: format,
              source: widget.source,
              type: currentType,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final currentType =
        (_tabController.index >= 0 &&
            _tabController.index < _supportedMediaTypes.length)
        ? _supportedMediaTypes[_tabController.index]
        : MediaType.ANIME;

    final filtersState = ref.watch(
      discoveryFiltersProvider((type: currentType, sourceId: widget.source)),
    );
    final hasFilters =
        filtersState.value != null && filtersState.value!.options.hasAnyFilter;

    String pageTitle = 'Discover';
    String pageSubtitle = 'Find your next anime or manga';

    if (widget.source != null && widget.source!.isNotEmpty) {
      final allAnimeSources =
          ref.watch(availableAnimeSourcesProvider).value ?? [];
      final allMangaSources =
          ref.watch(availableMangaSourcesProvider).value ?? [];
      final allSources = [...allAnimeSources, ...allMangaSources];
      final sourceObj = allSources
          .where((s) => s.id == widget.source)
          .firstOrNull;
      final sourceName =
          sourceObj?.name ??
          (widget.source![0].toUpperCase() + widget.source!.substring(1));
      pageTitle = sourceName;
      pageSubtitle = 'Browsing ${currentType.name.toLowerCase()} catalog';
    } else if (_genres.isNotEmpty && _tags.isNotEmpty) {
      pageTitle = _genres.join(', ');
      pageSubtitle = _tags.join(', ');
    } else if (_genres.isNotEmpty) {
      pageTitle = _genres.join(', ');
      pageSubtitle = 'Browsing ${currentType.name.toLowerCase()} by genre';
    } else if (_tags.isNotEmpty) {
      pageTitle = _tags.join(', ');
      pageSubtitle = 'Browsing ${currentType.name.toLowerCase()} by tag';
    }

    final showBackButton = widget.source != null && widget.source!.isNotEmpty;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isAltPressed ||
              HardwareKeyboard.instance.isMetaPressed) {
            return;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            if (_searchFocusNode.hasFocus) {
              _searchFocusNode.unfocus();
            }
            return;
          }
          final character = event.character;
          if (character != null && character.isNotEmpty) {
            final isAlphanumeric = RegExp(r'^[a-zA-Z0-9]$').hasMatch(character);
            if (isAlphanumeric) {
              final primaryFocus = FocusManager.instance.primaryFocus;
              final isAnyTextFieldFocused =
                  primaryFocus != null &&
                  (primaryFocus.context?.widget is EditableText ||
                      primaryFocus.context
                              ?.findAncestorWidgetOfExactType<EditableText>() !=
                          null);

              if (!isAnyTextFieldFocused) {
                setState(() {
                  _searchController.text = character;
                  _searchController.selection = TextSelection.fromPosition(
                    TextPosition(offset: character.length),
                  );
                });
                _searchFocusNode.requestFocus();
              }
            }
          }
        }
      },
      child: AppScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        showBackButton: showBackButton,
        body: SizedBox.expand(
          child: Stack(
            children: [
              Consumer(
                builder: (context, ref, child) {
                  ref.listen(metadataSourceProvider, (previous, next) {
                    if (previous?.supportedMediaTypes !=
                        next.supportedMediaTypes) {
                      _rebuildTabController(next.supportedMediaTypes);
                    }
                  });
                  return const SizedBox.shrink();
                },
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: _supportedMediaTypes.map((type) {
                            return DiscoverTabFeed(
                              type: type,
                              query: _query,
                              genres: _genres,
                              tags: _tags,
                              source: _source,
                              onGenreSelect: (g) {
                                context.pushFilteredDiscover(
                                  genres: [g],
                                  type: type,
                                );
                              },
                              onSourceSelect: (sId) {
                                context.pushFilteredDiscover(
                                  source: sId,
                                  type: type,
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: UnifiedSearchBar(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onBackPressed: _cancelSearch,
                      onClearPressed: () => _searchController.clear(),
                      onSubmitted: _submitSearch,
                      hasFilters: hasFilters,
                      onFilterPressed: () => _openAdvancedSearch(context),
                      leading:
                          _searchController.text.isEmpty &&
                              !_searchFocusNode.hasFocus
                          ? const Icon(Icons.search_rounded)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
