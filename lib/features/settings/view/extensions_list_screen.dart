import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:isar/isar.dart';
import 'package:shonenx/core_new/models/manga.dart';
import 'package:shonenx/core_new/models/source.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/extension_tile.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/main.dart';

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

  // Helper method to get country flag emoji from language code
  String _getLanguageFlag(String langCode) {
    const Map<String, String> languageFlags = {
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
    return languageFlags[langCode.toLowerCase()] ?? '🌐';
  }

  // Helper method to get full language name
  String _getLanguageName(String langCode) {
    const Map<String, String> languageNames = {
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
    return languageNames[langCode.toLowerCase()] ?? langCode.toUpperCase();
  }

  // Helper method to group extensions by language
  Map<String, List<Source>> _groupExtensionsByLanguage(
      List<Source> extensions) {
    final Map<String, List<Source>> grouped = {};

    for (final extension in extensions) {
      final lang = extension.lang ?? 'unknown';
      if (!grouped.containsKey(lang)) {
        grouped[lang] = [];
      }
      grouped[lang]!.add(extension);
    }

    // Sort each language group by name
    grouped.forEach((key, value) {
      value.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    });

    return grouped;
  }

  // Helper method to create settings item for extension
  Widget _createExtensionItem(
      Source extension,
      bool isInstalled,
      bool isSelected,
      SourceNotifier sourceNotifier,
      BuildContext context,
      WidgetRef ref) {
    return ExtensionTile(
            extension: extension,
            isInstalled: isInstalled,
            selected: isSelected)
        .build(context, ref);
  }

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
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    final TextEditingController controller =
                        TextEditingController(
                      text: sourceState.activeAnimeRepo.isNotEmpty
                          ? sourceState.activeAnimeRepo
                          : 'https://raw.githubusercontent.com/Swakshan/mangayomi-swak-extensions/refs/heads/main/anime_index.json',
                    );

                    return AlertDialog(
                      title: const Text('Add Repository URL'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              hintText: 'https://example.com/anime.json',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Repository:',
                                  style:
                                      Theme.of(context).textTheme.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sourceState.activeAnimeRepo,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
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
                            final url = controller.text.trim();
                            if (url.isNotEmpty) {
                              await ref
                                  .read(_uninstalledAnimeExtensionsProvider
                                      .future)
                                  .then((sources) {
                                isar.writeTxn(() async {
                                  isar.sources.deleteAll(
                                      sources.map((s) => s.id!).toList());
                                });
                              });
                              sourceNotifier.setActiveRepo(url, ItemType.anime);
                              sourceNotifier.fetchSources(ItemType.anime);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Add Repository'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Iconsax.add),
              tooltip: 'Add Repository',
            ),
            IconButton(
              onPressed: () {
                sourceNotifier.fetchSources(ItemType.anime);
              },
              icon: const Icon(Iconsax.refresh),
              tooltip: 'Refresh Extensions',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Iconsax.tick_circle),
                text: 'Installed',
              ),
              Tab(
                icon: Icon(Iconsax.add_circle),
                text: 'Available',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Installed Extensions Tab
            _buildExtensionsTab(
              ref.watch(_installedAnimeExtensionsProvider),
              true,
              sourceState,
              sourceNotifier,
            ),
            // Available Extensions Tab
            _buildExtensionsTab(
              ref.watch(_uninstalledAnimeExtensionsProvider),
              false,
              sourceState,
              sourceNotifier,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/settings/extensions/demo'),
          icon: const Icon(Iconsax.play),
          label: const Text('Demo'),
        ),
      ),
    );
  }

  Widget _buildExtensionsTab(
    AsyncValue<List<Source>> asyncExtensions,
    bool isInstalledTab,
    dynamic sourceState,
    SourceNotifier sourceNotifier,
  ) {
    return asyncExtensions.when(
      data: (extensions) {
        if (extensions.isEmpty) {
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
                      ? 'Install extensions from the Available tab'
                      : 'Check your repository or refresh',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        final groupedExtensions = _groupExtensionsByLanguage(extensions);
        final sortedLanguages = groupedExtensions.keys.toList()
          ..sort((a, b) {
            // Put English first, then sort alphabetically
            if (a == 'en') return -1;
            if (b == 'en') return 1;
            return _getLanguageName(a).compareTo(_getLanguageName(b));
          });

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: sortedLanguages.length,
          itemBuilder: (context, index) {
            final language = sortedLanguages[index];
            final languageExtensions = groupedExtensions[language]!;
            final languageName = _getLanguageName(language);
            final languageFlag = _getLanguageFlag(language);

            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Consumer(
                builder: (context, ref, child) {
                  return SettingsSection(
                      title:
                          '$languageFlag $languageName (${languageExtensions.length})',
                      titleColor: Theme.of(context).primaryColor,
                      children: languageExtensions.map((extension) {
                        final isSelected =
                            sourceState.activeAnimeSource?.id == extension.id;
                        final isInstalled = isInstalledTab ||
                            sourceState.installedAnimeExtensions
                                .any((source) => source.id == extension.id);

                        return _createExtensionItem(extension, isInstalled,
                            isSelected, sourceNotifier, context, ref);
                      }).toList());
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading extensions...'),
          ],
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.warning_2,
              size: 64,
              color: Colors.red[400],
            ),
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
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger a refresh
                sourceNotifier.fetchSources(ItemType.anime);
              },
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
