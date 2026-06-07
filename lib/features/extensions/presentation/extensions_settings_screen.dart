import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final manager = ref.read(extensionManagerProvider);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        title: 'Sources',
        barBottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
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
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showGuideSheet(context),
          ),
          if (Platform.isAndroid)
            SegmentedButton(
              segments: [
                ButtonSegment(
                  value: bridge.ExtensionType.mangayomi,
                  label: Text('Mangayomi'),
                ),
                ButtonSegment(
                  value: bridge.ExtensionType.aniyomi,
                  label: Text('Tachiyomi'),
                ),
              ],
              onSelectionChanged: (Set<bridge.ExtensionType> selected) {
                ref.read(managerTypeProvider.notifier).setType(selected.first);
                ref.invalidate(availableAnimeSourcesProvider);
                setState(() => {});
              },
              selected: {ref.watch(managerTypeProvider)},
            ),
          const SizedBox(width: 10),
        ],
        body: TabBarView(
          children: [
            Consumer(
              builder: (context, ref, child) {
                final sourcesAsync = ref.watch(availableAnimeSourcesProvider);

                return sourcesAsync.when(
                  data: (sources) {
                    return ListView.builder(
                      itemCount: sources.length,
                      itemBuilder: (context, index) {
                        final source = sources[index];
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
                                            .currentManager
                                            .installedAnimeExtensions
                                            .value
                                            .firstWhere(
                                              (e) => e.id == source.id,
                                            );
                                        await manager.currentManager
                                            .uninstallSource(extSource);
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
            manager.currentManager.availableAnimeExtensions.value.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.extension_off_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No available extensions',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ref.watch(managerTypeProvider) ==
                                    bridge.ExtensionType.mangayomi
                                ? 'Add a Mangayomi repository to fetch and install extensions.'
                                : 'Add a Tachiyomi repository to fetch and install extensions.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    children: manager
                        .currentManager
                        .availableAnimeExtensions
                        .value
                        .map((e) {
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
                                await manager.currentManager.installSource(e);
                                ref.invalidate(availableAnimeSourcesProvider);
                                setState(() => {});
                              },
                            ),
                          );
                        })
                        .toList(),
                  ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          icon: const Icon(Icons.add),
          label: Text(
            ref.watch(managerTypeProvider) == bridge.ExtensionType.mangayomi
                ? 'Add Mangayomi Repo'
                : 'Add Tachiyomi Repo',
          ),
          onPressed: () {
            final repoUrlController = TextEditingController();

            showModalBottomSheet(
              context: context,
              builder: (sheetContext) {
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return AppBottomSheet(
                      title:
                          ref.watch(managerTypeProvider) ==
                              bridge.ExtensionType.mangayomi
                          ? 'Add Mangayomi Repository'
                          : 'Add Tachiyomi Repository',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: repoUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Repository URL',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.maxFinite,
                            child: FilledButton(
                              onPressed: () async {
                                final parsedUrl = _parseRepoUrl(
                                  repoUrlController.text,
                                );

                                if (parsedUrl == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'Invalid repository URL. Please provide a direct link to the index.min.json file.',
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                await manager.currentManager.onRepoSaved([
                                  parsedUrl,
                                ], bridge.ItemType.anime);

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }

                                ref.invalidate(availableAnimeSourcesProvider);

                                setState(() {});
                              },
                              child: const Text('Add'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
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
}
