import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core_new/models/manga.dart';
import 'package:shonenx/core_new/models/source.dart';
import 'package:shonenx/core_new/extensions/fetch_anime_sources.dart';
import 'package:shonenx/core_new/extensions/fetch_manga_sources.dart';
import 'package:shonenx/core_new/extensions/fetch_novel_sources.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/main.dart';

class ExtensionTile extends ConsumerWidget {
  final Source extension;
  final bool isInstalled;
  final bool selected;

  const ExtensionTile({
    super.key,
    required this.extension,
    required this.isInstalled,
    required this.selected,
  });

  Future<void> _installSource(WidgetRef ref) async {
    final sourceNotifier = ref.read(sourceProvider.notifier);
    extension.itemType == ItemType.manga
        ? await ref.watch(
            fetchMangaSourcesListProvider(id: extension.id, reFresh: true)
                .future)
        : extension.itemType == ItemType.anime
            ? await ref.watch(
                fetchAnimeSourcesListProvider(id: extension.id, reFresh: true)
                    .future)
            : await ref.watch(
                fetchNovelSourcesListProvider(id: extension.id, reFresh: true)
                    .future);
    await sourceNotifier.initialize();
  }

  Future<void> _uninstallSource(WidgetRef ref) async {
    final sourceNotifier = ref.read(sourceProvider.notifier);
    await isar.writeTxn(() async {
      await isar.sources.delete(extension.id!);
    });
    await sourceNotifier.initialize();
  }

  Future<void> _selectSource(WidgetRef ref) async {
    if (extension.sourceCode == null) return;
    ref.read(sourceProvider.notifier).setActiveSource(extension);
  }

  String _buildExtensionDescription(Source extension, bool isInstalled) {
    final parts = <String>[];
    if (extension.version != null) parts.add("v${extension.version}");
    if (extension.isNsfw == true) parts.add("NSFW");
    parts.add(isInstalled ? "Installed" : "Available");
    return parts.join(" • ");
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(0),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => isInstalled ? _selectSource(ref) : _installSource(ref),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Icon / Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: extension.iconUrl ?? '',
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error_outline,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title + description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      extension.name ?? "Unknown Extension",
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildExtensionDescription(extension, isInstalled),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isInstalled && selected)
                    const Icon(Icons.check_rounded, color: Colors.green),
                  if (isInstalled) ...[
                    IconButton(
                      tooltip: "Preferences",
                      onPressed: () => context.push(
                        '/settings/extensions/extension-preference',
                        extra: extension,
                      ),
                      icon: const Icon(Iconsax.setting_2),
                    ),
                    IconButton(
                      tooltip: "Uninstall",
                      color: theme.colorScheme.error,
                      onPressed: () => _uninstallSource(ref),
                      icon: const Icon(Iconsax.trash),
                    ),
                  ] else
                    IconButton.filledTonal(
                      tooltip: "Install",
                      onPressed: () => _installSource(ref),
                      icon: const Icon(Icons.file_download_rounded),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
