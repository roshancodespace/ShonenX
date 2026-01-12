import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shonenx/features/anime/view_model/episode_stream_provider.dart';

class SubtitleSelectionSheet extends ConsumerWidget {
  final VoidCallback onLocalFilePressed;

  const SubtitleSelectionSheet({
    super.key,
    required this.onLocalFilePressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(episodeDataProvider);
    final existingSubtitles = data.subtitles;
    final selectedIndex = data.selectedSubtitleIdx;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Subtitles',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Iconsax.folder_open),
            title: const Text('Import Local File'),
            onTap: onLocalFilePressed,
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: existingSubtitles.length,
              itemBuilder: (context, index) {
                final sub = existingSubtitles[index];
                final isSelected = index == selectedIndex;

                return ListTile(
                  title: Text(sub.lang ?? 'Unknown'),
                  trailing: isSelected
                      ? Icon(Iconsax.tick_circle,
                          color: Theme.of(context).primaryColor)
                      : null,
                  onTap: () {
                    ref
                        .read(episodeDataProvider.notifier)
                        .changeSubtitle(index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
