import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart' as anilist_media;
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/data/hive/boxes/anime_watch_progress_box.dart';
import 'package:shonenx/screens/watch_screen/custom_dropdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class EpisodesPanel extends StatelessWidget {
  final List<EpisodeDataModel> episodes;
  final int selectedEpisodeIndex;
  final int totalEpisodes;
  final int rangeStart;
  final int itemsPerPage;
  final int gridColumns;
  final bool isGridView;
  final AnimeWatchProgressBox animeWatchProgressBox;
  final anilist_media.Media animeMedia;
  final List<String> servers;
  final String? selectedServer;
  final bool supportsDubSub;
  final String? selectedCategory;
  final List<Map<String, String>> qualityOptions;
  final String? selectedQuality;
  final void Function(int) onEpisodeTap;
  final void Function(String) onServerChange;
  final void Function(String) onCategoryChange;
  final void Function(String) onQualityChange;
  final VoidCallback onToggleLayout;
  final void Function(int) onRangeChange;
  final void Function(int) onItemsPerPageChange;
  final void Function(int) onGridColumnsChange;

  const EpisodesPanel({
    super.key,
    required this.episodes,
    required this.selectedEpisodeIndex,
    required this.totalEpisodes,
    required this.rangeStart,
    required this.itemsPerPage,
    required this.gridColumns,
    required this.isGridView,
    required this.animeWatchProgressBox,
    required this.animeMedia,
    required this.servers,
    required this.selectedServer,
    required this.supportsDubSub,
    required this.selectedCategory,
    required this.qualityOptions,
    required this.selectedQuality,
    required this.onEpisodeTap,
    required this.onServerChange,
    required this.onCategoryChange,
    required this.onQualityChange,
    required this.onToggleLayout,
    required this.onRangeChange,
    required this.onItemsPerPageChange,
    required this.onGridColumnsChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      child: episodes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [_buildControls(context), Expanded(child: _buildEpisodesView(context))]),
    );
  }

  Widget _buildControls(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainer,
      child: Row(
        children: [
          if (servers.isNotEmpty) _buildServerDropdown(context),
          const SizedBox(width: 12),
          if (supportsDubSub) _buildCategoryDropdown(context),
          const SizedBox(width: 12),
          if (qualityOptions.isNotEmpty) _buildQualityDropdown(context),
          const Spacer(),
          _buildLayoutToggle(context),
          const SizedBox(width: 12),
          _buildMoreMenu(context),
        ],
      ),
    );
  }

  Widget _buildServerDropdown(BuildContext context) => CustomDropdown(
        icon: Iconsax.devices,
        value: selectedServer!,
        items: servers,
        onChanged: onServerChange,
      );

  Widget _buildCategoryDropdown(BuildContext context) => CustomDropdown(
        icon: Iconsax.language_circle,
        value: selectedCategory!,
        items: const ['sub', 'dub'],
        onChanged: onCategoryChange,
      );

  Widget _buildQualityDropdown(BuildContext context) => CustomDropdown(
        icon: Iconsax.video,
        value: selectedQuality!,
        items: qualityOptions.map((q) => q['url']!).toList(),
        itemBuilder: (value) => Text(
          '${qualityOptions.firstWhere((q) => q['url'] == value)['quality']} ${qualityOptions.firstWhere((q) => q['url'] == value)['isDub'] == 'true' ? '(DUB)' : ''}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        onChanged: onQualityChange,
      );

  Widget _buildLayoutToggle(BuildContext context) => IconButton(
        icon: Icon(isGridView ? Iconsax.element_3 : Iconsax.element_2, color: Theme.of(context).colorScheme.onSurfaceVariant),
        onPressed: onToggleLayout,
        tooltip: isGridView ? 'Switch to List View' : 'Switch to Grid View',
      );

  Widget _buildMoreMenu(BuildContext context) => PopupMenuButton<String>(
        icon: const Icon(Iconsax.more, color: Colors.grey),
        onSelected: (value) {
          switch (value) {
            case 'vlc':
              launchUrl(Uri.parse('vlc://$selectedQuality'));
              break;
            case 'copy':
              Clipboard.setData(ClipboardData(text: selectedQuality ?? ''));
              _showSnackBar(context, 'URL Copied', 'Source URL copied to clipboard');
              break;
            case 'layout':
              _showLayoutSettingsDialog(context);
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: 'vlc', child: Text('Open with VLC')),
          const PopupMenuItem(value: 'copy', child: Text('Copy Source URL')),
          const PopupMenuItem(value: 'layout', child: Text('Layout Settings')),
        ],
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      );

  void _showSnackBar(BuildContext context, String title, String value) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(title: '$title Changed', message: 'Switched to ${value.toUpperCase()}', contentType: ContentType.success),
        ),
      );

  void _showLayoutSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Layout Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomDropdown(
              icon: Iconsax.ruler,
              value: itemsPerPage.toString(),
              items: ['50', '100', '200'],
              onChanged: (value) => onItemsPerPageChange(int.parse(value)),
            ),
            const SizedBox(height: 16),
            if (isGridView)
              CustomDropdown(
                icon: Iconsax.grid_2,
                value: gridColumns.toString(),
                items: ['2', '3', '4', '5'],
                onChanged: (value) => onGridColumnsChange(int.parse(value)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEpisodesView(BuildContext context) {
    final theme = Theme.of(context);
    final startIdx = rangeStart - 1;
    final endIdx = (startIdx + itemsPerPage > totalEpisodes) ? totalEpisodes : startIdx + itemsPerPage;
    final episodesInRange = episodes.sublist(startIdx, endIdx);
    final animeProgress = animeWatchProgressBox.getAllProgressByAnimeId(animeMedia.id!) ?? [];

    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: (totalEpisodes / itemsPerPage).ceil(),
            itemBuilder: (context, index) {
              final start = index * itemsPerPage + 1;
              final end = (start + itemsPerPage - 1) > totalEpisodes ? totalEpisodes : start + itemsPerPage - 1;
              final isSelected = rangeStart == start;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$start-$end', style: const TextStyle(fontSize: 14)),
                  selected: isSelected,
                  onSelected: (_) => onRangeChange(start),
                  selectedColor: theme.colorScheme.primaryContainer,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                  labelStyle: TextStyle(color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: isGridView ? _buildGridView(episodesInRange, animeProgress, theme) : _buildListView(episodesInRange, animeProgress, theme),
        ),
      ],
    );
  }

  Widget _buildListView(List<EpisodeDataModel> episodesInRange, List<dynamic> animeProgress, ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: episodesInRange.length,
      itemBuilder: (context, index) {
        final episode = episodesInRange[index];
        final globalIndex = (rangeStart - 1) + index;
        final isSelected = globalIndex == selectedEpisodeIndex;
        final isWatched = index < animeProgress.length && animeProgress[index].isCompleted;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isWatched ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
          ),
          child: ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
              child: Text(
                '${episode.number}',
                style: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            title: Text(
              'Episode ${episode.number}',
              style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 16),
            ),
            subtitle: episode.title != null ? Text(episode.title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)) : null,
            trailing: isSelected ? Icon(Iconsax.play_circle, color: theme.colorScheme.primary, size: 24) : null,
            onTap: () => onEpisodeTap(globalIndex),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<EpisodeDataModel> episodesInRange, List<dynamic> animeProgress, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridColumns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: episodesInRange.length,
      itemBuilder: (context, index) {
        final episode = episodesInRange[index];
        final globalIndex = (rangeStart - 1) + index;
        final isSelected = globalIndex == selectedEpisodeIndex;
        final isWatched = index < animeProgress.length && animeProgress[index].isCompleted;

        return GestureDetector(
          onTap: () => onEpisodeTap(globalIndex),
          child: Container(
            decoration: BoxDecoration(
              color: isWatched ? theme.colorScheme.surfaceContainerLow : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
                  child: Text(
                    '${episode.number}',
                    style: TextStyle(
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // const SizedBox(height: 8),
                // Text(
                //   'Ep ${episode.number}',
                //   style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 14),
                //   textAlign: TextAlign.center,
                // ),
                // if (episode.title != null)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 4),
                //     child: Text(
                //       episode.title!,
                //       style: const TextStyle(fontSize: 10),
                //       textAlign: TextAlign.center,
                //       maxLines: 2,
                //       overflow: TextOverflow.ellipsis,
                //     ),
                //   ),
                // if (isSelected)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 8),
                //     child: Icon(Iconsax.play_circle, color: theme.colorScheme.primary, size: 20),
                //   ),
              ],
            ),
          ),
        );
      },
    );
  }
}