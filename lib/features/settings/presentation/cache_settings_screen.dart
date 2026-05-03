import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/caching/cache_manager.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class CacheSettingsScreen extends ConsumerStatefulWidget {
  const CacheSettingsScreen({super.key});

  @override
  ConsumerState<CacheSettingsScreen> createState() =>
      _CacheSettingsScreenState();
}

class _CacheSettingsScreenState extends ConsumerState<CacheSettingsScreen> {
  int cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final cacheManager = ref.read(cacheManagerProvider);
    final size = await cacheManager.getCacheSize();
    setState(() {
      cacheSize = size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Cache Manager',
      body: ListView(
        children: [
          SettingsActionTile(
            icon: Icons.image_outlined,
            title: 'Clear Network Cache',
            subtitle: 'Frees up storage space ${cacheSize / 1024 / 1024} MB',
            isDestructive: true,
            onTap: () {
              ref.read(cacheManagerProvider).clearCache();
              _loadCacheSize();
            },
          ),
        ],
      ),
    );
  }
}
