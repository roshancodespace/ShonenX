import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';

class ExtensionList extends StatefulWidget implements bridge.ExtensionConfig {
  @override
  final bridge.ItemType itemType;
  @override
  final bool isInstalled;
  @override
  final String searchQuery;
  @override
  final String selectedLanguage;

  const ExtensionList({
    super.key,
    required this.itemType,
    required this.isInstalled,
    required this.searchQuery,
    required this.selectedLanguage,
  });

  @override
  State<ExtensionList> createState() => _ExtensionListState();
}

class _ExtensionListState extends bridge.ExtensionList<ExtensionList> {
  @override
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
        icon: Icon(isInstalled ? Icons.delete_outline : Icons.download),
        onPressed: () async {
          try {
            if (isInstalled) {
              await manager.uninstallSource(source);
            } else {
              
              await manager.installSource(source);
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
}
