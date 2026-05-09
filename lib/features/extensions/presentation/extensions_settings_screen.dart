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
        actions: !Platform.isAndroid
            ? null
            : [
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
                    ref
                        .read(managerTypeProvider.notifier)
                        .setType(selected.first);
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
                          trailing: isInbuilt
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
                                        .firstWhere((e) => e.id == source.id);
                                    await manager.currentManager
                                        .uninstallSource(extSource);
                                    ref.invalidate(
                                      availableAnimeSourcesProvider,
                                    );

                                    setState(() => {});
                                  },
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
            ListView(
              children: manager.currentManager.availableAnimeExtensions.value
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
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.secondary,
          foregroundColor: theme.colorScheme.onSecondary,
          onPressed: () {
            final repoUrlController = TextEditingController();

            showModalBottomSheet(
              context: context,
              builder: (sheetContext) {
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return AppBottomSheet(
                      title: 'Add Repository',
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
                                await manager.currentManager.onRepoSaved([
                                  repoUrlController.text,
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
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
