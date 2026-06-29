import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class ManageReposSheet extends ConsumerStatefulWidget {
  final bridge.Extension manager;
  final String? autoAddUrl;
  final String? autoAddType;

  const ManageReposSheet({
    super.key,
    required this.manager,
    this.autoAddUrl,
    this.autoAddType,
  });

  @override
  ConsumerState<ManageReposSheet> createState() => _ManageReposSheetState();
}

class _ManageReposSheetState extends ConsumerState<ManageReposSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _clipboardText;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.autoAddType?.toLowerCase() ?? 'both';
    if (!['both', 'anime', 'manga'].contains(_selectedCategory)) {
      _selectedCategory = 'both';
    }
    _checkClipboard();

    if (widget.autoAddUrl != null &&
        widget.autoAddUrl!.isNotEmpty) {
      _controller.text = widget.autoAddUrl!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _addRepo());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null &&
          (text.startsWith('http://') || text.startsWith('https://'))) {
        if (mounted) setState(() => _clipboardText = text);
      }
    } catch (_) {}
  }

  String? _parseRepoUrl(String input) {
    input = input.trim();
    if (input.isEmpty) return null;
    if (input.startsWith('https://github.com/') && input.contains('/blob/')) {
      return input
          .replaceFirst(
            'https://github.com/',
            'https://raw.githubusercontent.com/',
          )
          .replaceFirst('/blob/', '/');
    }
    if (input.startsWith('https://raw.githubusercontent.com/')) return input;
    if (input.startsWith('http') && input.endsWith('.json')) return input;
    return null;
  }

  Future<void> _addRepo() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    final parsedUrl = _parseRepoUrl(url);
    if (parsedUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Invalid repository URL. Please provide a direct link to the index.min.json file.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      bool addedAnime = false;
      bool addedManga = false;

      if (_selectedCategory == 'both' || _selectedCategory == 'anime') {
        try {
          await widget.manager.addRepo(parsedUrl, bridge.ItemType.anime);
          addedAnime = true;
        } catch (_) {}
      }
      if (_selectedCategory == 'both' || _selectedCategory == 'manga') {
        try {
          await widget.manager.addRepo(parsedUrl, bridge.ItemType.manga);
          addedManga = true;
        } catch (_) {}
      }

      _controller.clear();
      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      if (mounted) {
        if (addedAnime || addedManga) {
          final typeLabel = addedAnime && addedManga
              ? 'Anime & Manga'
              : (addedAnime ? 'Anime' : 'Manga');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$typeLabel repository added successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Failed to add repository or already exists.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeRepo(String url) async {
    try {
      await widget.manager.removeRepo(url, bridge.ItemType.anime);
    } catch (_) {}
    try {
      await widget.manager.removeRepo(url, bridge.ItemType.manga);
    } catch (_) {}
    ref.invalidate(availableAnimeSourcesProvider);
    ref.invalidate(availableMangaSourcesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Repository removed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMangayomi = widget.manager.id == 'mangayomi';

    return AppBottomSheet(
      title: isMangayomi ? 'Manage Mangayomi Repos' : 'Manage Tachiyomi Repos',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Add Repository URL',
              prefixIcon: const Icon(Icons.add_link_rounded),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  return value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: _controller.clear,
                        )
                      : const SizedBox.shrink();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              helperText: isMangayomi
                  ? 'Format: https://.../index.min.json'
                  : 'Format: https://.../index.json',
            ),
            enabled: !_isLoading,
            onSubmitted: (_) => _addRepo(),
          ),
          const SizedBox(height: 12),
          Text(
            'Repository Category',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            segments: const [
              ButtonSegment(
                value: 'both',
                label: Text('Both', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'anime',
                label: Text('Anime Only', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: 'manga',
                label: Text('Manga Only', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_selectedCategory},
            onSelectionChanged: _isLoading
                ? null
                : (sel) => setState(() => _selectedCategory = sel.first),
          ),
          const SizedBox(height: 8),
          if (_clipboardText != null && !_isLoading) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  _controller.text = _clipboardText!;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _clipboardText!.length),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: Text(
                  'Paste copied link: $_clipboardText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _addRepo,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_download_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Add Repository',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Active Repositories',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final animeRepos = widget.manager
                .getReposRx(bridge.ItemType.anime)
                .value;
            final mangaRepos = widget.manager
                .getReposRx(bridge.ItemType.manga)
                .value;

            final animeUrls = animeRepos.map((r) => r.url).toSet();
            final mangaUrls = mangaRepos.map((r) => r.url).toSet();

            final Map<String, bridge.Repo> uniqueRepos = {};
            for (final r in [...animeRepos, ...mangaRepos]) {
              uniqueRepos[r.url] = r;
            }

            final repos = uniqueRepos.values.toList();

            if (repos.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'No repositories added yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: repos.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final repo = repos[index];
                  final uri = Uri.tryParse(repo.url);
                  final hostname = uri?.host ?? 'Custom Repo';
                  final isAnime = animeUrls.contains(repo.url);
                  final isManga = mangaUrls.contains(repo.url);

                  return Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_shared_outlined,
                          color: theme.colorScheme.primary,
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                repo.name ?? hostname,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  _buildBadge(
                                    context,
                                    isMangayomi ? 'MANGAYOMI' : 'TACHIYOMI',
                                    theme.colorScheme.primaryContainer,
                                    theme.colorScheme.onPrimaryContainer,
                                  ),
                                  if (isAnime && isManga)
                                    _buildBadge(
                                      context,
                                      'ANIME & MANGA',
                                      Colors.purple.withValues(alpha: 0.2),
                                      Colors.purple.shade800,
                                    )
                                  else if (isAnime)
                                    _buildBadge(
                                      context,
                                      'ANIME ONLY',
                                      Colors.orange.withValues(alpha: 0.2),
                                      Colors.orange.shade800,
                                    )
                                  else if (isManga)
                                    _buildBadge(
                                      context,
                                      'MANGA ONLY',
                                      Colors.green.withValues(alpha: 0.2),
                                      Colors.green.shade800,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                repo.url,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Remove Repository',
                          onPressed: () => _removeRepo(repo.url),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
