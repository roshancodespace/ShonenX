import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shonenx/core/utils/snackbar_utils.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/source_registry.dart';

class ManageReposSheet extends ConsumerStatefulWidget {
  final bridge.Extension? manager;
  final String? autoAddUrl;
  final String? autoAddType;
  final String? autoAddManager;

  const ManageReposSheet({
    super.key,
    this.manager,
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
  late String _selectedCategory;
  late String _selectedEngineId;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.autoAddType?.toLowerCase() ?? 'both';
    if (!['both', 'anime', 'manga', 'novel'].contains(_selectedCategory)) {
      _selectedCategory = 'both';
    }

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
            widget.manager?.id.replaceAll('-desktop', '') ?? 'aniyomi';
      }
    } else {
      _selectedEngineId =
          widget.manager?.id.replaceAll('-desktop', '') ?? 'aniyomi';
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
    if (input.startsWith('https://github.com/') && input.contains('/blob/')) {
      return input
          .replaceFirst(
            'https://github.com/',
            'https://raw.githubusercontent.com/',
          )
          .replaceFirst('/blob/', '/');
    }
    if (!input.startsWith('http://') && !input.startsWith('https://')) {
      return 'https://$input';
    }
    return input;
  }

  void _showSnackBar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    BuildContext? ctx,
  }) {
    SnackbarUtils.show(
      ctx ?? context,
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

    setState(() => _isLoading = true);
    try {
      final bridgeManager = Get.find<bridge.ExtensionManager>();
      final targetManager =
          bridgeManager.findById(_selectedEngineId) ??
          bridgeManager.findById('$_selectedEngineId-desktop');

      if (targetManager == null) {
        _showSnackBar(
          'Engine $_selectedEngineId is not available or registered.',
          isError: true,
        );
        return;
      }

      bool added = false;
      if (_selectedCategory == 'both' || _selectedCategory == 'anime') {
        try {
          await targetManager.addRepo(parsedUrl, bridge.ItemType.anime);
          added = true;
        } catch (_) {}
      }
      if (_selectedCategory == 'both' || _selectedCategory == 'manga') {
        try {
          await targetManager.addRepo(parsedUrl, bridge.ItemType.manga);
          added = true;
        } catch (_) {}
      }
      if (_selectedCategory == 'both' || _selectedCategory == 'novel') {
        try {
          await targetManager.addRepo(parsedUrl, bridge.ItemType.novel);
          added = true;
        } catch (_) {}
      }

      _controller.clear();
      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      ref.invalidate(availableNovelSourcesProvider);
      if (mounted) {
        if (added) {
          _showSnackBar(
            'Repository added to ${_getEngineName(_selectedEngineId)} successfully!',
            isSuccess: true,
          );
        } else {
          _showSnackBar(
            'Failed to add repository or already exists.',
            isError: true,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeRepo(String url, String managerId) async {
    setState(() => _isLoading = true);
    try {
      final bridgeManager = Get.find<bridge.ExtensionManager>();
      final targetManager =
          bridgeManager.findById(managerId) ??
          bridgeManager.findById('$managerId-desktop');
      if (targetManager != null) {
        try {
          await targetManager.removeRepo(url, bridge.ItemType.anime);
        } catch (_) {}
        try {
          await targetManager.removeRepo(url, bridge.ItemType.manga);
        } catch (_) {}
        try {
          await targetManager.removeRepo(url, bridge.ItemType.novel);
        } catch (_) {}
      }
      ref.invalidate(availableAnimeSourcesProvider);
      ref.invalidate(availableMangaSourcesProvider);
      ref.invalidate(availableNovelSourcesProvider);
      if (mounted) {
        _showSnackBar('Repository removed');
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Failed to remove repository', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getEngineName(String id) {
    switch (id.replaceAll('-desktop', '')) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBottomSheet(
      title: 'Manage Extension Repositories',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Target Engine',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedEngineId,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'aniyomi',
                child: Text('Tachiyomi / Aniyomi'),
              ),
              DropdownMenuItem(value: 'mangayomi', child: Text('Mangayomi')),
              DropdownMenuItem(
                value: 'cloudstream',
                child: Text('CloudStream'),
              ),
              DropdownMenuItem(value: 'kotatsu', child: Text('Kotatsu')),
              DropdownMenuItem(value: 'sora', child: Text('Sora')),
            ],
            onChanged: _isLoading
                ? null
                : (val) {
                    if (val != null) setState(() => _selectedEngineId = val);
                  },
          ),
          const SizedBox(height: 12),
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
              helperText: 'Enter direct URL or raw repository link',
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
            segments: const [
              ButtonSegment(
                value: 'both',
                label: Text('All', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: 'anime',
                label: Text('Anime', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: 'manga',
                label: Text('Manga', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment(
                value: 'novel',
                label: Text('Novel', style: TextStyle(fontSize: 11)),
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
            final bridgeManager = Get.find<bridge.ExtensionManager>();
            final allManagers = bridgeManager.managers;
            final List<(bridge.Repo, String)> reposWithManager = [];
            final urls = <String>{};

            for (final m in allManagers) {
              final mId = m.id.replaceAll('-desktop', '');
              final aRepos = m.getReposRx(bridge.ItemType.anime).value;
              final mRepos = m.getReposRx(bridge.ItemType.manga).value;
              final nRepos = m.getReposRx(bridge.ItemType.novel).value;
              for (final r in [...aRepos, ...mRepos, ...nRepos]) {
                if (urls.add(r.url)) {
                  reposWithManager.add((r, r.managerId ?? mId));
                }
              }
            }

            if (reposWithManager.isEmpty) {
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
                itemCount: reposWithManager.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = reposWithManager[index];
                  final repo = item.$1;
                  final mId = item.$2;
                  final uri = Uri.tryParse(repo.url);
                  final hostname = uri?.host ?? 'Custom Repo';

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
                                    _getEngineName(mId).toUpperCase(),
                                    theme.colorScheme.primaryContainer,
                                    theme.colorScheme.onPrimaryContainer,
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
                          onPressed: () => _removeRepo(repo.url, mId),
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
