import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';

class SyncSettingsScreen extends ConsumerWidget {
  const SyncSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget buildSyncOption({
      required String title,
      required String description,
      required bool value,
      required Function(bool) onChanged,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_1),
        ),
        title: const Text(
          'Sync Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Sync Behavior',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          buildSyncOption(
            title: 'Auto-sync on startup',
            description: 'Automatically sync your lists when the app starts',
            value: true, // Connect to a provider
            onChanged: (value) {
              // Update provider
            },
          ),
          buildSyncOption(
            title: 'Sync while watching',
            description: 'Update progress on AniList while watching episodes',
            value: true, // Connect to a provider
            onChanged: (value) {
              // Update provider
            },
          ),
          buildSyncOption(
            title: 'Background sync',
            description: 'Periodically sync in the background when app is closed',
            value: false, // Connect to a provider
            onChanged: (value) {
              // Update provider
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Sync Data',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          buildSyncOption(
            title: 'Sync watch status',
            description: 'Keep watching status in sync with AniList',
            value: true, // Connect to a provider
            onChanged: (value) {
              // Update provider
            },
          ),
          buildSyncOption(
            title: 'Sync ratings',
            description: 'Keep your anime ratings in sync with AniList',
            value: true, // Connect to a provider
            onChanged: (value) {
              // Update provider
            },
          ),
          buildSyncOption(
            title: 'Sync notes',
            description: 'Keep your anime notes in sync with AniList',
            value: false, // Connect to a provider
            onChanged: (value) {
              // Update provider
            },
          ),
        ],
      ),
    );
  }
}