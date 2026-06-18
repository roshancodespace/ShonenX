import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExtensionList extends StatefulWidget {
  final bridge.ItemType itemType;
  final bridge.Extension manager;
  final bool isInstalled;
  final String searchQuery;
  final String selectedLanguage;

  const ExtensionList({
    super.key,
    required this.itemType,
    required this.isInstalled,
    required this.searchQuery,
    required this.manager,
    required this.selectedLanguage,
  });

  @override
  State<ExtensionList> createState() => _ExtensionListState();
}

class _ExtensionListState extends State<ExtensionList> {
  Widget extensionItem(bool isHeader, String lang, bridge.Source? source) {
    if (isHeader) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Text(
          lang,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (source == null) return const SizedBox.shrink();

    final name = source.name ?? 'Unknown';
    final icon = source.iconUrl ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: _buildIcon(icon),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: source.lang != null ? Text(source.lang!) : null,
      trailing: IconButton(
        icon: Icon(widget.isInstalled ? Icons.delete_outline : Icons.download),
        onPressed: () async {
          try {
            if (widget.isInstalled) {
              await widget.manager.uninstallSource(source);
            } else {
              await widget.manager.installSource(source);
            }
          } catch (_) {}
        },
      ),
    );
  }

  Widget _buildIcon(String url) {
    if (url.isEmpty || url.endsWith('.ico')) {
      return const Icon(Icons.extension, size: 40);
    }

    return Image.network(
      url,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const Icon(Icons.extension, size: 40);
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          width: 40,
          height: 40,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sources = widget.isInstalled
          ? widget.manager.getInstalledRx(widget.itemType).value
          : widget.manager.getAvailableRx(widget.itemType).value;

      var filteredSources = sources.where((s) {
        final name = (s.name ?? '').toLowerCase();
        final id = (s.id ?? '').toLowerCase();
        final query = widget.searchQuery.toLowerCase();
        return name.contains(query) || id.contains(query);
      }).toList();

      if (widget.selectedLanguage.isNotEmpty &&
          widget.selectedLanguage.toLowerCase() != 'all') {
        filteredSources = filteredSources.where((s) {
          final lang = s.lang ?? 'all';
          return lang.toLowerCase() == widget.selectedLanguage.toLowerCase();
        }).toList();
      }

      if (filteredSources.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.extension_off_outlined,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.searchQuery.isEmpty && widget.selectedLanguage.isEmpty
                      ? 'No extensions found'
                      : 'No extensions match your filters',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      final isAllLanguages =
          widget.selectedLanguage.isEmpty ||
          widget.selectedLanguage.toLowerCase() == 'all';

      if (isAllLanguages) {
        final Map<String, List<bridge.Source>> grouped = {};
        for (final s in filteredSources) {
          final lang = s.lang ?? 'all';
          grouped.putIfAbsent(lang, () => []).add(s);
        }

        final sortedKeys = grouped.keys.toList()..sort();
        final listItems = <Widget>[];

        for (final lang in sortedKeys) {
          listItems.add(extensionItem(true, lang.toUpperCase(), null));
          final langSources = grouped[lang]!;
          langSources.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
          for (final source in langSources) {
            listItems.add(extensionItem(false, '', source));
          }
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: listItems,
        );
      } else {
        filteredSources.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: filteredSources.length,
          itemBuilder: (context, index) {
            return extensionItem(false, '', filteredSources[index]);
          },
        );
      }
    });
  }
}
