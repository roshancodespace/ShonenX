import 'package:anymex_extension_runtime_bridge/Services/Mangayomi/MangayomiExtensions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/features/settings/presentation/source_settings_sheet.dart';

class ExtensionsSettingsScreen extends ConsumerStatefulWidget {
  const ExtensionsSettingsScreen({super.key});

  @override
  ConsumerState<ExtensionsSettingsScreen> createState() =>
      _ExtensionsSettingsScreenState();
}

class _ExtensionsSettingsScreenState
    extends ConsumerState<ExtensionsSettingsScreen> {
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final manager = ref.watch(extensionManagerProvider);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: _isSearching ? null : 'Sources',
        floatingActionButtonLocation: MediaQuery.of(context).size.width < 600
            ? FloatingActionButtonLocation.centerFloat
            : FloatingActionButtonLocation.endFloat,
        titleWidget: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search extensions...',
                  border: InputBorder.none,
                  hintStyle: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                style: theme.textTheme.titleMedium,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : null,
        barBottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Expanded(
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorAnimation: TabIndicatorAnimation.linear,
              tabs: [
                Tab(text: 'Installed'),
                Tab(text: 'Available'),
              ],
            ),
          ),
        ),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.speed_outlined),
              onPressed: () => context.push('/settings/extensions/test'),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showGuideSheet(context),
            ),
          ],
          const SizedBox(width: 10),
        ],
        body: TabBarView(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final sourcesAsync = ref.watch(availableAnimeSourcesProvider);

                return sourcesAsync.when(
                  data: (sources) {
                    final filteredSources = sources.where((s) {
                      final name = s.name.toLowerCase();
                      final id = s.id.toLowerCase();
                      final query = _searchQuery.toLowerCase();
                      return name.contains(query) || id.contains(query);
                    }).toList();

                    if (filteredSources.isEmpty) {
                      return Center(
                        child: Text(
                          'No extensions found',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredSources.length,
                      itemBuilder: (context, index) {
                        final source = filteredSources[index];
                        final isInbuilt = source.type == SourceType.inbuilt;

                        final sourceImpl = ref.read(
                          animeSourceProvider(source),
                        );

                        return SettingsActionTile(
                          title: source.name,
                          subtitle: source.id,
                          tileColor: isInbuilt
                              ? theme.colorScheme.secondaryContainer
                              : null,
                          foregroundColor: isInbuilt
                              ? theme.colorScheme.onSecondaryContainer
                              : null,
                          leading: CachedNetworkImage(
                            imageUrl: source.iconUrl ?? '',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.extension, size: 40),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FutureBuilder<List<SourceSetting>>(
                                future: sourceImpl.getSettingsSchema(),
                                builder: (context, snapshot) {
                                  final hasSettings =
                                      snapshot.hasData &&
                                      snapshot.data!.isNotEmpty;
                                  if (!hasSettings) {
                                    return const SizedBox.shrink();
                                  }

                                  return IconButton(
                                    icon: const Icon(Icons.settings_outlined),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) =>
                                            SourceSettingsSheet(
                                              source: source,
                                              schema: snapshot.data!,
                                            ),
                                      );
                                    },
                                  );
                                },
                              ),
                              isInbuilt
                                  ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Text(
                                        'INBUILT',
                                        style: TextStyle(
                                          color: theme
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final extSource = manager
                                            .getInstalledRx(
                                              bridge.ItemType.anime,
                                            )
                                            .value
                                            .firstWhere(
                                              (e) => e.id == source.id,
                                            );
                                        await manager.uninstallSource(
                                          extSource,
                                        );
                                        ref.invalidate(
                                          availableAnimeSourcesProvider,
                                        );

                                        setState(() => {});
                                      },
                                    ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                );
              },
            ),
            (() {
              final available = manager
                  .getAvailableRx(bridge.ItemType.anime)
                  .value;
              final filteredAvailable = available.where((e) {
                final name = (e.name ?? '').toLowerCase();
                final id = (e.id ?? '').toLowerCase();
                final query = _searchQuery.toLowerCase();
                return name.contains(query) || id.contains(query);
              }).toList();

              if (filteredAvailable.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.extension_off_outlined,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No available extensions'
                              : 'No extensions found',
                          style: theme.textTheme.titleLarge,
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            manager is MangayomiExtensions
                                ? 'Add a Mangayomi repository to fetch and install extensions.'
                                : 'Add a Tachiyomi repository to fetch and install extensions.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return ListView(
                children: filteredAvailable.map((e) {
                  return SettingsActionTile(
                    title: e.name ?? 'N/A',
                    subtitle: e.id ?? 'N/A',
                    leading: CachedNetworkImage(
                      imageUrl: e.iconUrl ?? '',
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.extension, size: 40),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        await manager.installSource(e);
                        ref.invalidate(availableAnimeSourcesProvider);
                        setState(() => {});
                      },
                    ),
                  );
                }).toList(),
              );
            })(),
          ],
        ),
        floatingActionButton: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 48,
              child: SegmentedButton<String>(
                style: SegmentedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                segments: const [
                  ButtonSegment(
                    value: 'mangayomi',
                    label: Text('Mangayomi', style: TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment(
                    value: 'aniyomi',
                    label: Text('Tachiyomi', style: TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {manager.id.replaceAll('-desktop', '')},
                onSelectionChanged: (selected) {
                  ref
                      .read(extensionManagerProvider.notifier)
                      .setManager(selected.first);
                  ref.invalidate(availableAnimeSourcesProvider);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: FloatingActionButton.extended(
                heroTag: 'add_repo_fab',
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Repo', style: TextStyle(fontSize: 13)),
                onPressed: () => _showAddRepoSheet(context),
              ),
            ),
          ],
        ),
      ),
    );
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

    if (input.startsWith('https://raw.githubusercontent.com/')) {
      return input;
    }

    if (input.startsWith('http') && input.endsWith('.json')) {
      return input;
    }

    return null;
  }

  void _showGuideSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AppBottomSheet(
          title: 'Extensions Guide',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This app supports installing external community extensions to fetch content from various sources.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Repository Types',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Mangayomi: A modern extension ecosystem. Recommended for best compatibility.',
              ),
              const SizedBox(height: 4),
              const Text(
                '• Tachiyomi / Aniyomi: The classic extension ecosystem. Available for backward compatibility.',
              ),
              const SizedBox(height: 16),
              Text(
                'How to use',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Select your preferred extension ecosystem from the top toggle.\n'
                '2. Click the Add Repo button at the bottom and enter a valid repository URL.\n'
                '3. Once added, the available extensions will appear in the Available tab.\n'
                '4. Click the + icon to install an extension and start watching!',
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it!'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddRepoSheet(BuildContext context) {
    final manager = ref.watch(extensionManagerProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _AddRepoSheet(
          manager: manager,
          onAdd: (url) async {
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

            await manager.addRepo(parsedUrl, bridge.ItemType.anime);
            if (context.mounted) {
              Navigator.pop(context);
            }
            ref.invalidate(availableAnimeSourcesProvider);
            setState(() {});
          },
        );
      },
    );
  }
}

class _AddRepoSheet extends StatefulWidget {
  final bridge.Extension manager;
  final Future<void> Function(String url) onAdd;

  const _AddRepoSheet({required this.manager, required this.onAdd});

  @override
  State<_AddRepoSheet> createState() => _AddRepoSheetState();
}

class _AddRepoSheetState extends State<_AddRepoSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _clipboardText;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
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
        setState(() {
          _clipboardText = text;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMangayomi = widget.manager.id == 'mangayomi';

    return AppBottomSheet(
      title: isMangayomi ? 'Add Mangayomi Repo' : 'Add Tachiyomi Repo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct JSON Link Required',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMangayomi
                            ? 'Please provide a direct URL pointing to the index.min.json file.'
                            : 'Please provide a direct URL to the repository index.json file.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Repository URL',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  return value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () => _controller.clear(),
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
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
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
                    vertical: 8,
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
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
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
        ],
      ),
    );
  }

  void _submit() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onAdd(url);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
