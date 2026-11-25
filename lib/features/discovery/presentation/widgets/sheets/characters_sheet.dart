import 'package:shonenx/shared/widgets/smart_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
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
    return AppBottomSheet.show(
      context: context,
      title: 'Character',
      titleIcon: Icons.person_rounded,
      contentPadding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
      child: _CharacterDetailsModal(character: character),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Search character or voice actor...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.65),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: cs.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: cs.onSurfaceVariant,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: ShapeDecoration(
                          color: cs.surfaceContainerLow,
                          shape: const StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _FilterChipItem(
                              label: 'All',
                              count: _characters.length,
                              selected: _selectedRole == 'ALL',
                              onTap: () =>
                                  setState(() => _selectedRole = 'ALL'),
                            ),
                            _FilterChipItem(
                              label: 'Main',
                              selected: _selectedRole == 'MAIN',
                              onTap: () =>
                                  setState(() => _selectedRole = 'MAIN'),
                            ),
                            _FilterChipItem(
                              label: 'Supporting',
                              selected: _selectedRole == 'SUPPORTING',
                              onTap: () =>
                                  setState(() => _selectedRole = 'SUPPORTING'),
                            ),
                            _FilterChipItem(
                              label: 'Background',
                              selected: _selectedRole == 'BACKGROUND',
                              onTap: () =>
                                  setState(() => _selectedRole = 'BACKGROUND'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${filtered.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.16)),
        Expanded(
          child: filtered.isEmpty && !_isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        size: 36,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No matching characters',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 520
                        ? (constraints.maxWidth / 270).floor().clamp(2, 3)
                        : 1;
                    return GridView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisExtent: 104,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: filtered.length + (_isLoading ? columns : 0),
                      itemBuilder: (context, index) {
                        if (index >= filtered.length) {
                          return Container(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        return CharacterCastCard(character: filtered[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

}

class _CharacterDetailsModal extends ConsumerStatefulWidget {
  final MediaCharacter character;

  const _CharacterDetailsModal({required this.character});

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
    final isMain = (c.role?.toUpperCase() ?? '') == 'MAIN';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _CastPortrait(
              url: c.image,
              width: 96,
              height: 134,
              radius: 16,
              fallbackIcon: Icons.person_rounded,
              iconSize: 34,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (c.role != null && c.role!.isNotEmpty) ...[
                    Text(
                      '${c.role!.replaceAll('_', ' ').toUpperCase()} CHARACTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isMain ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    c.name,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.12,
                    ),
                  ),
                  if (c.nativeName != null && c.nativeName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      c.nativeName!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (c.voiceActorName != null && c.voiceActorName!.isNotEmpty) ...[
          Divider(
            height: 32,
            color: cs.outlineVariant.withValues(alpha: 0.2),
          ),
          Row(
            children: [
              _CastPortrait(
                url: c.voiceActorImage,
                width: 52,
                height: 68,
                radius: 12,
                fallbackIcon: Icons.mic_none_rounded,
                iconSize: 20,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VOICED BY',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.voiceActorName!,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        Divider(
          height: 32,
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
        Text(
          'BIOGRAPHY',
          style: textTheme.labelSmall?.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: cs.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingBio)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (c.description != null && c.description!.isNotEmpty)
          MarkdownWidget(
            markdown: Markdown.fromString(c.description!),
            theme: MarkdownThemeData(
              textStyle:
                  textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ) ??
                  TextStyle(
                    height: 1.6,
                    color: cs.onSurface.withValues(alpha: 0.85),
                  ),
              linkColor: cs.primary,
            ),
          )
        else
          Text(
            'No bio available for this character.',
            style: textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterCastCard extends StatelessWidget {
  final MediaCharacter character;
  final double radius;
  final double? width;
  final double height;
  final double characterImageWidth;
  final double voiceActorImageWidth;
  final VoidCallback? onTap;

  const CharacterCastCard({
    super.key,
    required this.character,
    this.radius = 16,
    this.width,
    this.height = 104,
    this.characterImageWidth = 68,
    this.voiceActorImageWidth = 52,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isMain = (character.role?.toUpperCase() ?? '') == 'MAIN';
    final hasVa =
        character.voiceActorName != null &&
        character.voiceActorName!.isNotEmpty;
    final hasVaImage =
        character.voiceActorImage != null &&
        character.voiceActorImage!.isNotEmpty;

    final card = Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap ?? () => CharactersSheet.showDetails(context, character),
        child: Row(
          children: [
            _CastPortrait(
              url: character.image,
              width: characterImageWidth,
              height: height,
              fallbackIcon: Icons.person_rounded,
              iconSize: 24,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (character.role != null &&
                            character.role!.isNotEmpty) ...[
                          Text(
                            character.role!.replaceAll('_', ' ').toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isMain ? cs.primary : cs.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              fontSize: 9.5,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                        ],
                        Text(
                          character.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    if (hasVa)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'VOICE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: cs.onSurfaceVariant.withValues(
                                alpha: 0.65,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            character.voiceActorName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (hasVa && hasVaImage)
              _CastPortrait(
                url: character.voiceActorImage,
                width: voiceActorImageWidth,
                height: height,
                fallbackIcon: Icons.mic_none_rounded,
                iconSize: 20,
              ),
          ],
        ),
      ),
    );

    return width != null ? SizedBox(width: width, child: card) : card;
  }
}

class _CastPortrait extends StatelessWidget {
  final String? url;
  final double width;
  final double height;
  final double radius;
  final IconData fallbackIcon;
  final double iconSize;

  const _CastPortrait({
    required this.url,
    required this.width,
    required this.height,
    this.radius = 0,
    required this.fallbackIcon,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: cs.surfaceContainerHigh,
      child: Icon(fallbackIcon, size: iconSize, color: cs.onSurfaceVariant),
    );

    final child = url != null && url!.isNotEmpty
        ? SmartImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => placeholder,
          )
        : placeholder;

    return radius > 0
        ? ClipRRect(borderRadius: BorderRadius.circular(radius), child: child)
        : child;
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: ShapeDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: -0.1,
                color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color:
                      (selected ? cs.onPrimaryContainer : cs.onSurfaceVariant)
                          .withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
