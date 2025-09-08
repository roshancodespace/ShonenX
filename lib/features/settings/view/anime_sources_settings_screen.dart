import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/widgets/settings_item.dart';

final providerStatusProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await http.get(Uri.parse(
      'https://raw.githubusercontent.com/Darkx-dev/ShonenX-Providers-Status/refs/heads/main/server_status.json'));
  if (response.statusCode == 200) {
    return json.decode(response.body);
  }
  throw Exception('Failed to load provider status');
});

class AnimeSourcesSettingsScreen extends ConsumerWidget {
  const AnimeSourcesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAnimeSource = ref.watch(selectedAnimeProvider);
    final animeSources = ref.read(animeSourceRegistryProvider).keys;
    final providerStatus = ref.watch(providerStatusProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left_2)),
        title: const Text('Anime Sources'),
        forceMaterialTransparency: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Sources',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
                'Select a source to fetch anime from. The status indicates if the source is currently working.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Expanded(
              child: providerStatus.when(
                data: (statusData) => ListView.builder(
                  itemCount: animeSources.length,
                  itemBuilder: (context, index) {
                    final provider = animeSources[index];
                    final statusInfo = statusData[provider];
                    final status = statusInfo?['status'] as String?;
                    final isSelected = selectedAnimeSource?.providerName ==
                        provider.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: SettingsItem(
                        icon: Icon(_getStatusIcon(status)),
                        iconColor: _getStatusColor(status),
                        accent: _getStatusColor(status),
                        title: provider.toUpperCase(),
                        description:
                            'Status: ${status?.toUpperCase() ?? 'UNKNOWN'}',
                        type: SettingsItemType.selectable,
                        isInSelectionMode: true,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedProviderKeyProvider.notifier)
                              .select(provider);
                        },
                      ),
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text('Failed to load provider status'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.refresh(providerStatusProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'degraded':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Iconsax.info_circle;
    switch (status.toLowerCase()) {
      case 'online':
        return Iconsax.health;
      case 'degraded':
        return Iconsax.warning_2;
      case 'offline':
        return Iconsax.danger;
      default:
        return Iconsax.info_circle;
    }
  }
}
