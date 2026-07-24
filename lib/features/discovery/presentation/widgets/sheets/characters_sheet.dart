import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class CharactersSheet extends ConsumerStatefulWidget {
  final String mediaId;
  final MediaType mediaType;
  final String mediaTitle;
  final List<MediaCharacter> initialCharacters;

  const CharactersSheet({
    super.key,
    required this.mediaId,
    required this.mediaType,
    required this.mediaTitle,
    this.initialCharacters = const [],
  });

  static Future<void> show(
    BuildContext context, {
    required String mediaId,
    required MediaType mediaType,
    required String mediaTitle,
    List<MediaCharacter> initialCharacters = const [],
  }) {
    return AppBottomSheet.show(
      context: context,
      title: 'Characters',
      titleIcon: Icons.people_alt_rounded,
      contentPadding: EdgeInsets.zero,
      child: CharactersSheet(
        mediaId: mediaId,
        mediaType: mediaType,
        mediaTitle: mediaTitle,
        initialCharacters: initialCharacters,
      ),
    );
  }

  static Future<void> showDetails(
    BuildContext context,
    MediaCharacter character,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return _CharacterDetailsModal(
              character: character,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  @override
  ConsumerState<CharactersSheet> createState() => _CharactersSheetState();
}

class _CharactersSheetState extends ConsumerState<CharactersSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<MediaCharacter> _characters = [];
  bool _isLoading = false;
  bool _hasNextPage = true;
  int _currentPage = 1;
  String _searchQuery = '';
  String _selectedRole = 'ALL';

  @override
  void initState() {
    super.initState();
    _characters.addAll(widget.initialCharacters);
    _scrollController.addListener(_onScroll);
    _fetchNextPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasNextPage) {
      _fetchNextPage();
    }
  }

  void _checkIfNeedMore() {
    if (!_isLoading &&
        _hasNextPage &&
        _scrollController.hasClients &&
        _scrollController.position.maxScrollExtent <= 100) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchNextPage() async {
    if (widget.mediaId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final tracker = ref.read(metadataSourceProvider);

      final result = await tracker.getCharacters(
        widget.mediaId,
        page: _currentPage,
        perPage: 25,
        type: widget.mediaType,
      );

      _hasNextPage = result.hasNextPage;

      if (mounted) {
        setState(() {
          if (result.items.isNotEmpty && _currentPage == 1) {
            _characters.clear();
          }
          final existingNames = _characters
              .map((c) => c.name.toLowerCase())
              .toSet();
          for (final item in result.items) {
            if (!existingNames.contains(item.name.toLowerCase())) {
              _characters.add(item);
              existingNames.add(item.name.toLowerCase());
            }
          }
          _currentPage++;
          _isLoading = false;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _checkIfNeedMore();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final filtered = _characters.where((c) {
      final matchesQuery =
          _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.nativeName != null &&
              c.nativeName!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) ||
          (c.voiceActorName != null &&
              c.voiceActorName!.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ));

      final matchesRole =
          _selectedRole == 'ALL' ||
          (c.role != null &&
              c.role!.toUpperCase() == _selectedRole.toUpperCase());

      return matchesQuery && matchesRole;
    }).toList();

    return Column(
      children: [
        // Search Bar & Filter Chips Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search character or voice actor...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipItem(
                      label: 'All (${_characters.length})',
                      selected: _selectedRole == 'ALL',
                      onTap: () => setState(() => _selectedRole = 'ALL'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: 'Main',
                      selected: _selectedRole == 'MAIN',
                      onTap: () => setState(() => _selectedRole = 'MAIN'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: 'Supporting',
                      selected: _selectedRole == 'SUPPORTING',
                      onTap: () => setState(() => _selectedRole = 'SUPPORTING'),
                    ),
                    const SizedBox(width: 6),
                    _FilterChipItem(
                      label: 'Background',
                      selected: _selectedRole == 'BACKGROUND',
                      onTap: () => setState(() => _selectedRole = 'BACKGROUND'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Character Grid View with Infinite Scroll
        Expanded(
          child: filtered.isEmpty && !_isLoading
              ? Center(
                  child: Text(
                    'No characters found',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : GridView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 195,
                    mainAxisExtent: 105,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filtered.length + (_isLoading ? 2 : 0),
                  itemBuilder: (context, index) {
                    if (index >= filtered.length) {
                      return Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(
                            GlobalUI.uiRoundness,
                          ),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }

                    final c = filtered[index];
                    return InkWell(
                      onTap: () => _showCharacterDetails(context, c),
                      borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            GlobalUI.uiRoundness,
                          ),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (c.image != null && c.image!.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  GlobalUI.uiRoundness * 0.7,
                                ),
                                child: CachedNetworkImage(
                                  imageUrl: c.image!,
                                  width: 52,
                                  height: 92,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 52,
                                    height: 92,
                                    color: cs.surfaceContainerHigh,
                                    child: const Icon(
                                      Icons.person_rounded,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 52,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(
                                    GlobalUI.uiRoundness * 0.7,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 22,
                                ),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    c.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (c.role != null && c.role!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      c.role!.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ],
                                  if (c.voiceActorName != null &&
                                      c.voiceActorName!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      c.voiceActorName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
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
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCharacterDetails(BuildContext context, MediaCharacter c) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return _CharacterDetailsModal(
              character: c,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _CharacterDetailsModal extends ConsumerStatefulWidget {
  final MediaCharacter character;
  final ScrollController scrollController;

  const _CharacterDetailsModal({
    required this.character,
    required this.scrollController,
  });

  @override
  ConsumerState<_CharacterDetailsModal> createState() =>
      _CharacterDetailsModalState();
}

class _CharacterDetailsModalState
    extends ConsumerState<_CharacterDetailsModal> {
  late MediaCharacter _character;
  bool _isLoadingBio = false;

  @override
  void initState() {
    super.initState();
    _character = widget.character;
    if ((_character.description == null || _character.description!.isEmpty) &&
        _character.id.isNotEmpty) {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoadingBio = true);
    try {
      final tracker = ref.read(metadataSourceProvider);
      final details = await tracker.getCharacterDetails(_character.id);

      if (mounted && details != null) {
        setState(() {
          _character = MediaCharacter(
            id: _character.id,
            name: details.name.isNotEmpty ? details.name : _character.name,
            nativeName: details.nativeName ?? _character.nativeName,
            role: _character.role,
            image: details.image ?? _character.image,
            description: details.description ?? _character.description,
            voiceActorName: _character.voiceActorName,
            voiceActorImage: _character.voiceActorImage,
          );
          _isLoadingBio = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingBio = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final c = _character;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: widget.scrollController,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.image != null && c.image!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                  child: CachedNetworkImage(
                    imageUrl: c.image!,
                    width: 100,
                    height: 140,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 100,
                      height: 140,
                      color: cs.surfaceContainerHigh,
                      child: const Icon(Icons.person_rounded, size: 36),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (c.nativeName != null && c.nativeName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        c.nativeName!,
                        style: textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (c.role != null && c.role!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.role!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                    if (c.voiceActorName != null &&
                        c.voiceActorName!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Voice Actor (Seiyuu)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.voiceActorName!,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'About',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          if (_isLoadingBio)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (c.description != null && c.description!.isNotEmpty)
            MarkdownBody(
              data: c.description!,
              styleSheet: MarkdownStyleSheet(
                p: textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: cs.onSurfaceVariant,
                ),
                strong: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            )
          else
            Text(
              'No bio available for this character.',
              style: textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
      ),
      selectedColor: cs.primaryContainer,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
      ),
    );
  }
}
