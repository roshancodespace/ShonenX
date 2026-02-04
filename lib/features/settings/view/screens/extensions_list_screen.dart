import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:isar_community/isar.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'package:shonenx/core_mangayomi/models/manga.dart';
import 'package:shonenx/core_mangayomi/models/source.dart';
import 'package:shonenx/features/settings/view/widgets/extension_tile.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/main.dart';

// stream providers for installed/uninstalled extensions
final _uninstalledAnimeExtensionsProvider =
    StreamProvider.autoDispose<List<Source>>((ref) {
      return isar.sources
          .filter()
          .idIsNotNull()
          .and()
          .isAddedEqualTo(false)
          .isActiveEqualTo(true)
          .itemTypeEqualTo(ItemType.anime)
          .watch(fireImmediately: true);
    });

final _installedAnimeExtensionsProvider =
    StreamProvider.autoDispose<List<Source>>((ref) {
      return isar.sources
          .filter()
          .idIsNotNull()
          .and()
          .isAddedEqualTo(true)
          .isActiveEqualTo(true)
          .itemTypeEqualTo(ItemType.anime)
          .watch(fireImmediately: true);
    });

class ExtensionsListScreen extends ConsumerWidget {
  const ExtensionsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceState = ref.watch(sourceProvider);
    final sourceNotifier = ref.read(sourceProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton.filledTonal(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left_2),
          ),
          title: const Text('Extensions (WIP)'),
          forceMaterialTransparency: true,
          actions: [
            // add repository button
            IconButton(
              onPressed: () =>
                  _showAddRepoDialog(context, ref, sourceNotifier, sourceState),
              icon: const Icon(Iconsax.add),
              tooltip: 'Add Repository',
            ),
            // refresh extensions
            IconButton(
              onPressed: () => sourceNotifier.fetchSources(ItemType.anime),
              icon: const Icon(Iconsax.refresh),
              tooltip: 'Refresh Extensions',
            ),
            // settings
            IconButton(
              onPressed: () => _showSettingsDialog(context),
              icon: const Icon(Iconsax.setting_2),
              tooltip: 'Extension Settings',
            ),
            IconButton(
              onPressed: () => context.push('/settings/extensions/playground'),
              icon: const Icon(Iconsax.code),
              tooltip: 'Extension Playground',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Iconsax.tick_circle), text: 'Installed'),
              Tab(icon: Icon(Iconsax.add_circle), text: 'Available'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // installed extensions tab
            ExtensionsTab(
              asyncExtensions: ref.watch(_installedAnimeExtensionsProvider),
              isInstalledTab: true,
            ),
            // available extensions tab
            ExtensionsTab(
              asyncExtensions: ref.watch(_uninstalledAnimeExtensionsProvider),
              isInstalledTab: false,
            ),
          ],
        ),
        floatingActionButton: kDebugMode
            ? FloatingActionButton.extended(
                onPressed: () => context.push('/settings/extensions/demo'),
                icon: const Icon(Iconsax.play),
                label: const Text('Demo'),
              )
            : null,
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final settingsBox = Hive.box('settings');
            final autoUpdate = settingsBox.get(
              'auto_update_extensions',
              defaultValue: false,
            );

            return AlertDialog(
              title: const Text('Extension Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Auto Update Extensions'),
                    subtitle: const Text(
                      'Automatically update extensions when a new version is available.',
                    ),
                    value: autoUpdate,
                    onChanged: (value) {
                      settingsBox.put('auto_update_extensions', value);
                      setState(() {});
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // dialog for adding a new repository
  void _showAddRepoDialog(
    BuildContext context,
    WidgetRef ref,
    SourceNotifier notifier,
    dynamic sourceState,
  ) {
    final controller = TextEditingController(
      text: sourceState.activeAnimeRepo.isNotEmpty
          ? sourceState.activeAnimeRepo
          : 'https://raw.githubusercontent.com/Swakshan/mangayomi-swak-extensions/refs/heads/main/anime_index.json',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Repository URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://github.com/user/repo/blob/main/index.json',
                border: OutlineInputBorder(),
                helperText: 'GitHub links are automatically converted to raw',
                helperMaxLines: 2,
              ),
              minLines: 1,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Repository:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sourceState.activeAnimeRepo,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              var url = controller.text.trim();

              if (url.isNotEmpty) {
                if (url.contains('github.com') && url.contains('/blob/')) {
                  url = url
                      .replaceFirst('github.com', 'raw.githubusercontent.com')
                      .replaceFirst('/blob/', '/');
                }

                Navigator.pop(context);

                await ref.read(_uninstalledAnimeExtensionsProvider.future).then(
                  (sources) {
                    isar.writeTxn(() async {
                      isar.sources.deleteAll(
                        sources.map((s) => s.id!).toList(),
                      );
                    });
                  },
                );

                notifier.setActiveRepo(url, ItemType.anime);
                notifier.fetchSources(ItemType.anime);
              }
            },
            child: const Text('Add Repository'),
          ),
        ],
      ),
    );
  }
}

// widget for a tab (installed or available)
class ExtensionsTab extends ConsumerWidget {
  final AsyncValue<List<Source>> asyncExtensions;
  final bool isInstalledTab;

  const ExtensionsTab({
    super.key,
    required this.asyncExtensions,
    required this.isInstalledTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sourceState = ref.watch(sourceProvider);
    final sourceNotifier = ref.read(sourceProvider.notifier);

    return asyncExtensions.when(
      data: (extensions) {
        if (extensions.isEmpty) return _buildEmptyState(context);

        final grouped = _groupExtensionsByLanguage(extensions);
        final sortedLanguages = grouped.keys.toList()
          ..sort((a, b) {
            if (a == 'en') return -1;
            if (b == 'en') return 1;
            return _getLanguageName(a).compareTo(_getLanguageName(b));
          });

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: sortedLanguages.length,
          itemBuilder: (context, index) {
            final lang = sortedLanguages[index];
            final exts = grouped[lang]!;
            final langName = _getLanguageName(lang);
            final langFlag = _getLanguageFlag(lang);

            return Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: SettingsSection(
                title: '$langFlag $langName (${exts.length})',
                titleColor: Theme.of(context).primaryColor,
                children: exts.map((ext) {
                  final isSelected =
                      sourceState.activeAnimeSource?.id == ext.id;
                  final isInstalled =
                      isInstalledTab ||
                      sourceState.installedAnimeExtensions.any(
                        (s) => s.id == ext.id,
                      );
                  return ExtensionTile(
                    extension: ext,
                    isInstalled: isInstalled,
                    selected: isSelected,
                  ).build(context, ref);
                }).toList(),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => _buildErrorState(context, err, sourceNotifier),
    );
  }

  // group extensions by language
  Map<String, List<Source>> _groupExtensionsByLanguage(
    List<Source> extensions,
  ) {
    final grouped = <String, List<Source>>{};
    for (final ext in extensions) {
      final lang = ext.lang ?? 'unknown';
      grouped.putIfAbsent(lang, () => []).add(ext);
    }
    grouped.forEach(
      (_, list) => list.sort((a, b) => (a.name ?? '').compareTo(b.name ?? '')),
    );
    return grouped;
  }

  // map language code to emoji flag
  String _getLanguageFlag(String langCode) {
    const flags = {
      'en': '🇺🇸',
      'es': '🇪🇸',
      'fr': '🇫🇷',
      'de': '🇩🇪',
      'it': '🇮🇹',
      'pt': '🇵🇹',
      'ru': '🇷🇺',
      'ja': '🇯🇵',
      'ko': '🇰🇷',
      'zh': '🇨🇳',
      'ar': '🇸🇦',
      'hi': '🇮🇳',
      'tr': '🇹🇷',
      'nl': '🇳🇱',
      'pl': '🇵🇱',
      'sv': '🇸🇪',
      'no': '🇳🇴',
      'da': '🇩🇰',
      'fi': '🇫🇮',
      'th': '🇹🇭',
      'vi': '🇻🇳',
      'id': '🇮🇩',
      'ms': '🇲🇾',
      'tl': '🇵🇭',
    };
    return flags[langCode.toLowerCase()] ?? '🌐';
  }

  // map language code to name
  String _getLanguageName(String langCode) {
    const names = {
      'en': 'English',
      'es': 'Spanish',
      'fr': 'French',
      'de': 'German',
      'it': 'Italian',
      'pt': 'Portuguese',
      'ru': 'Russian',
      'ja': 'Japanese',
      'ko': 'Korean',
      'zh': 'Chinese',
      'ar': 'Arabic',
      'hi': 'Hindi',
      'tr': 'Turkish',
      'nl': 'Dutch',
      'pl': 'Polish',
      'sv': 'Swedish',
      'no': 'Norwegian',
      'da': 'Danish',
      'fi': 'Finnish',
      'th': 'Thai',
      'vi': 'Vietnamese',
      'id': 'Indonesian',
      'ms': 'Malay',
      'tl': 'Filipino',
    };
    return names[langCode.toLowerCase()] ?? langCode.toUpperCase();
  }

  // empty state widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isInstalledTab ? Iconsax.box : Iconsax.search_normal,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isInstalledTab
                ? 'No extensions installed'
                : 'No extensions available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isInstalledTab
                ? 'Install from the Available tab'
                : 'Check repository or refresh',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // error state widget
  Widget _buildErrorState(
    BuildContext context,
    Object error,
    SourceNotifier notifier,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.warning_2, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Error loading extensions',
            style: TextStyle(
              fontSize: 18,
              color: Colors.red[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => notifier.fetchSources(ItemType.anime),
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
