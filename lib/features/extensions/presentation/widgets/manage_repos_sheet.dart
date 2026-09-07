import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/snackbar_utils.dart';
import 'package:shonenx/features/extensions/providers/extension_service_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class ManageReposSheet extends ConsumerStatefulWidget {
  final String? managerId;
  final String? autoAddUrl;
  final String? autoAddType;
  final String? autoAddManager;

  const ManageReposSheet({
    super.key,
    this.managerId,
    this.autoAddUrl,
    this.autoAddType,
    this.autoAddManager,
  });

  @override
  ConsumerState<ManageReposSheet> createState() => _ManageReposSheetState();
}

class _ManageReposSheetState extends ConsumerState<ManageReposSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _clipboardText;
  late String _selectedEngineId;

  @override
  void initState() {
    super.initState();
    if (widget.autoAddManager != null &&
        [
          'aniyomi',
          'mangayomi',
          'cloudstream',
          'kotatsu',
          'sora',
        ].contains(widget.autoAddManager)) {
      _selectedEngineId = widget.autoAddManager!;
    } else if (widget.autoAddUrl != null) {
      final lower = widget.autoAddUrl!.toLowerCase();
      if (lower.contains('cloudstream')) {
        _selectedEngineId = 'cloudstream';
      } else if (lower.contains('kotatsu')) {
        _selectedEngineId = 'kotatsu';
      } else if (lower.contains('sora')) {
        _selectedEngineId = 'sora';
      } else if (lower.contains('mangayomi')) {
        _selectedEngineId = 'mangayomi';
      } else {
        _selectedEngineId =
            widget.managerId?.replaceAll('-desktop', '') ?? 'aniyomi';
      }
    } else {
      _selectedEngineId =
          widget.managerId?.replaceAll('-desktop', '') ?? 'aniyomi';
    }

    if (![
      'aniyomi',
      'mangayomi',
      'cloudstream',
      'kotatsu',
      'sora',
    ].contains(_selectedEngineId)) {
      _selectedEngineId = 'aniyomi';
    }

    _checkClipboard();

    if (widget.autoAddUrl != null && widget.autoAddUrl!.isNotEmpty) {
      _controller.text = widget.autoAddUrl!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _addRepo());
    }
  }

  @override
  void dispose() {
    SnackbarUtils.dismissCurrent();
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
    return ExtensionAdapter.normalizeRepoUrl(input, _selectedEngineId);
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    SnackbarUtils.show(
      context,
      message,
      isError: isError,
      isSuccess: isSuccess,
    );
  }

  Future<void> _addRepo() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    final parsedUrl = _parseRepoUrl(url);
    if (parsedUrl == null) {
      _showSnackBar('Invalid repository URL.', isError: true);
      return;
    }

    // Check if repository already exists in active repositories
    final currentRepos = ref.read(activeExtReposProvider);
    final isAlreadyAdded = currentRepos.any((r) {
      final cleanCurrent = r.url.trim().toLowerCase();
      final cleanParsed = parsedUrl.trim().toLowerCase();
      return cleanCurrent == cleanParsed &&
          (r.managerId.replaceAll('-desktop', '') ==
              _selectedEngineId.replaceAll('-desktop', ''));
    });

    if (isAlreadyAdded) {
      _showSnackBar(
        'Repository is already in your active list for ${_getEngineName(_selectedEngineId)}.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final adapter = ref.read(extensionAdapterProvider);
      bool added = false;

      final types =
          (widget.autoAddType != null &&
              [
                'anime',
                'manga',
                'novel',
              ].contains(widget.autoAddType!.toLowerCase()))
          ? [
              switch (widget.autoAddType!.toLowerCase()) {
                'anime' => bridge.ItemType.anime,
                'manga' => bridge.ItemType.manga,
                _ => bridge.ItemType.novel,
              },
            ]
          : [
              bridge.ItemType.anime,
              bridge.ItemType.manga,
              bridge.ItemType.novel,
            ];

      for (final type in types) {
        if (await adapter.addRepo(parsedUrl, _selectedEngineId, type)) {
          added = true;
        }
      }

      if (mounted) {
        if (added) {
          _controller.clear();
          // Invalidate so the UI rebuilds with fresh data
          ref.invalidate(activeExtReposProvider);
          ref.invalidate(availableAnimeSourcesProvider);
          ref.invalidate(availableMangaSourcesProvider);
          ref.invalidate(availableNovelSourcesProvider);
          _showSnackBar(
            'Repository added to ${_getEngineName(_selectedEngineId)} successfully!',
            isSuccess: true,
          );
        } else {
          _showSnackBar(
            'Failed to add repository to ${_getEngineName(_selectedEngineId)}.',
            isError: true,
          );
        }
      }
    } catch (e) {
      String message = e.toString();
      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }
      if (mounted) {
        _showSnackBar('Failed to add repository: $message', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeRepo(String url, String managerId) async {
    setState(() => _isLoading = true);
    try {
      final adapter = ref.read(extensionAdapterProvider);
      final removed = await adapter.removeRepo(url, managerId);

      if (removed) {
        ref.invalidate(activeExtReposProvider);
        ref.invalidate(availableAnimeSourcesProvider);
        ref.invalidate(availableMangaSourcesProvider);
        ref.invalidate(availableNovelSourcesProvider);
        if (mounted) {
          _showSnackBar('Repository removed successfully.', isSuccess: true);
        }
      } else {
        if (mounted) {
          _showSnackBar('Failed to remove repository.', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to remove repository: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _availableEngines = [
    ('aniyomi', 'Tachiyomi / Aniyomi'),
    ('mangayomi', 'Mangayomi'),
    ('cloudstream', 'CloudStream'),
    ('kotatsu', 'Kotatsu'),
    ('sora', 'Sora'),
  ];

  Future<void> _confirmClearAllRepos() async {
    final roundness = GlobalUI.uiRoundness;
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Delete All Repositories?',
      icon: Icon(
        Icons.delete_sweep_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      child: Text(
        'This will remove all added extension repositories across all engines.\n\nAre you sure you want to delete all repositories?',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(roundness * 0.5),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(roundness * 0.5),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete All'),
        ),
      ],
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final adapter = ref.read(extensionAdapterProvider);
        await adapter.clearAllRepos();
        ref.invalidate(activeExtReposProvider);
        ref.invalidate(availableAnimeSourcesProvider);
        ref.invalidate(availableMangaSourcesProvider);
        ref.invalidate(availableNovelSourcesProvider);
        if (mounted) {
          _showSnackBar('All repositories have been deleted.', isSuccess: true);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to delete repositories: $e', isError: true);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _getEngineName(String id) {
    switch (id.replaceAll('-desktop', '').toLowerCase()) {
      case 'mangayomi':
        return 'Mangayomi';
      case 'aniyomi':
        return 'Tachiyomi / Aniyomi';
      case 'cloudstream':
        return 'CloudStream';
      case 'kotatsu':
        return 'Kotatsu';
      case 'sora':
        return 'Sora';
      default:
        return id.toUpperCase();
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRepoTitle(BuildContext context, String displayName) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (displayName.contains(' / ')) {
      final parts = displayName.split(' / ');
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${parts[0]} / ',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
                fontSize: 13.5,
              ),
            ),
            TextSpan(
              text: parts[1],
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                fontSize: 13.5,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      displayName,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildEngineChip({
    required BuildContext context,
    required String id,
    required String label,
    required bool isSelected,
    required double roundness,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _isLoading ? null : () => setState(() => _selectedEngineId = id),
      borderRadius: BorderRadius.circular(roundness * 0.7),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary
              : cs.surfaceContainerHigh.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(roundness * 0.7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final roundness = GlobalUI.uiRoundness;
    final activeRepos = ref.watch(activeExtReposProvider);

    return AppBottomSheet(
      title: 'Manage Repositories',
      titleIcon: Icons.folder_copy_rounded,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section 1: Engine Selection
            _buildSectionHeader(context, 'TARGET ENGINE'),
            const SizedBox(height: 2),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _availableEngines.map((engine) {
                  final isSelected = _selectedEngineId == engine.$1;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildEngineChip(
                      context: context,
                      id: engine.$1,
                      label: engine.$2,
                      isSelected: isSelected,
                      roundness: roundness,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Section 2: Repository URL
            _buildSectionHeader(context, 'REPOSITORY URL'),
            const SizedBox(height: 2),

            TextField(
              controller: _controller,
              style: TextStyle(fontSize: 14, color: cs.onSurface),
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.surfaceContainerHigh.withValues(alpha: 0.6),
                hintText: 'https://... (GitHub, JSON, or repo URL)',
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 13.5,
                ),
                prefixIcon: Icon(
                  Icons.link_rounded,
                  color: cs.primary,
                  size: 20,
                ),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    if (value.text.isNotEmpty) {
                      return IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: cs.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: () {
                          _controller.clear();
                          setState(() {});
                        },
                      );
                    }
                    if (_clipboardText != null && _clipboardText!.isNotEmpty) {
                      return IconButton(
                        icon: Icon(
                          Icons.content_paste_rounded,
                          color: cs.primary,
                          size: 18,
                        ),
                        tooltip: 'Paste from clipboard',
                        onPressed: () {
                          _controller.text = _clipboardText!;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: _clipboardText!.length),
                          );
                          setState(() {});
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(roundness),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(roundness),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(roundness),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              enabled: !_isLoading,
              onSubmitted: (_) => _addRepo(),
            ),

            // Quick Paste suggestion
            if (_clipboardText != null &&
                _controller.text.isEmpty &&
                !_isLoading) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  _controller.text = _clipboardText!;
                  _controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: _clipboardText!.length),
                  );
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(roundness * 0.6),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(roundness * 0.6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.content_paste_go_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Paste: $_clipboardText',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16,
                        color: cs.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              const SizedBox(height: 12),
            ],

            // Add Repository Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _addRepo,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(roundness),
                ),
              ),
              icon: _isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.add_link_rounded, size: 20),
              label: Text(
                _isLoading
                    ? 'Adding Repository...'
                    : 'Add to ${_getEngineName(_selectedEngineId)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Section 3: Active Repositories Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildSectionHeader(context, 'ACTIVE REPOSITORIES'),
                    if (activeRepos.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              roundness * 0.5,
                            ),
                          ),
                          child: Text(
                            '${activeRepos.length}',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (activeRepos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton.icon(
                      onPressed: _isLoading ? null : _confirmClearAllRepos,
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: cs.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(roundness * 0.5),
                        ),
                      ),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                      label: const Text(
                        'Delete All',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Active Repositories List
            if (activeRepos.isEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 40,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No repositories added yet',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add repository URLs above to discover and install extensions for anime, manga, and novels.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeRepos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final repo = activeRepos[index];
                  final displayName = ExtensionAdapter.extractRepoDisplayName(
                    repo.url,
                    repo.name,
                  );
                  final engineName = _getEngineName(repo.managerId);

                  return Material(
                    color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(roundness * 0.75),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: _buildRepoTitle(
                                        context,
                                        displayName,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildBadge(context, engineName, roundness),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  repo.url,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                            tooltip: 'Copy URL',
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: repo.url));
                              _showSnackBar('URL copied to clipboard');
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: cs.error,
                            ),
                            tooltip: 'Remove Repository',
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                _removeRepo(repo.url, repo.managerId),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, double roundness) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(roundness * 0.4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: cs.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
