import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core_new/extensions/fetch_anime_sources.dart';
import 'package:shonenx/core_new/extensions/fetch_manga_sources.dart';
import 'package:shonenx/core_new/extensions/fetch_novel_sources.dart';
import 'package:shonenx/core_new/models/manga.dart';
import 'package:shonenx/core_new/models/source.dart';
import 'package:shonenx/features/settings/view_model/source_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/widgets/settings_item.dart';

class ExtensionTile extends ConsumerWidget  {
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
    AppLogger.e('Uninstall failed cuz i didnt make it yet');
  }

  Future<void> _selectSource(WidgetRef ref) async {
    if (extension.sourceCode == null) return;
    ref.read(sourceProvider.notifier).setActiveSource(extension);
  }

  String _buildExtensionDescription(Source extension, bool isInstalled) {
    final List<String> parts = [];

    if (extension.version != null) {
      parts.add('v${extension.version}');
    }

    if (extension.isNsfw == true) {
      parts.add('NSFW');
    }

    if (isInstalled) {
      parts.add('Installed');
    } else {
      parts.add('Available');
    }

    return parts.join(' • ');
  }

  @override
  SettingsItem build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SettingsItem(
      leading: CachedNetworkImage(
        imageUrl: extension.iconUrl ?? '',
        errorWidget: (context, url, error) =>
            const Icon(Icons.error_outline_outlined),
      ),
      accent: isInstalled ? Colors.green : Colors.blue,
      title: extension.name ?? 'Unknown Extension',
      description: _buildExtensionDescription(extension, isInstalled),
      onTap: () {
        if (isInstalled) {
          _selectSource(ref);
        } else {
          // Install extension
          // sourceNotifier.installSource(extension);
        }
      },
      trailingWidgets: [
        if (isInstalled && selected) const Icon(Icons.check_rounded),
        if (isInstalled)
          IconButton(
              style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer),
              onPressed: () => _uninstallSource(ref),
              icon: const Icon(Iconsax.trash)),
        if (isInstalled)
          IconButton.filledTonal(
            onPressed: () => context.push(
                '/settings/extensions/extension-preference',
                extra: extension),
            icon: const Icon(Iconsax.setting_2),
          )
        else
          IconButton.filledTonal(
            onPressed: () => _installSource(ref),
            icon: const Icon(Icons.file_download_rounded),
          ),
      ],
    );
  }
}
