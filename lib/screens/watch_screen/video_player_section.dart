import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart' as anilist_media;
import 'package:shonenx/screens/watch_screen/custom_dropdown.dart';
import 'package:shonenx/widgets/player/controls.dart';
import 'package:shonenx/widgets/ui/paints/diagonal_lines_bg.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching VLC

class VideoPlayerSection extends StatelessWidget {
  final String animeName;
  final List<EpisodeDataModel> episodes;
  final int selectedEpisodeIndex;
  final VideoController controller;
  final List<SubtitleTrack> subtitles;
  final anilist_media.Media animeMedia;
  final List<String> servers;
  final String? selectedServer;
  final bool supportsDubSub;
  final String? selectedCategory;
  final List<Map<String, String>> qualityOptions;
  final String? selectedQuality;
  final void Function(String) onServerChange;
  final void Function(String) onCategoryChange;
  final void Function(String) onQualityChange;

  const VideoPlayerSection({
    super.key,
    required this.animeName,
    required this.episodes,
    required this.selectedEpisodeIndex,
    required this.controller,
    required this.subtitles,
    required this.animeMedia,
    required this.servers,
    required this.selectedServer,
    required this.supportsDubSub,
    required this.selectedCategory,
    required this.qualityOptions,
    required this.selectedQuality,
    required this.onServerChange,
    required this.onCategoryChange,
    required this.onQualityChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: DiagonalLinesPainter(
        lineColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        lineWidth: 1.5,
        spacing: 30,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animeName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (episodes.isNotEmpty)
                        Text(
                          'Ep ${episodes[selectedEpisodeIndex].number}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildVideoSettings(context),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Video(
                  controller: controller,
                  controls: (videoState) => CustomControls(
                    animeMedia: animeMedia,
                    state: videoState,
                    subtitles: subtitles,
                    episodes: episodes,
                    currentEpisodeIndex: selectedEpisodeIndex,
                  ),
                  subtitleViewConfiguration: SubtitleViewConfiguration(
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      backgroundColor: Colors.black45,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 4,
                          offset: const Offset(1, 1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSettings(BuildContext context) {
    final theme = Theme.of(context);
    final currentQuality = qualityOptions.isNotEmpty
        ? qualityOptions.firstWhere((q) => q['url'] == selectedQuality, orElse: () => {'quality': 'Auto', 'isDub': 'false'})['quality']
        : 'Auto';
    final summary = '${selectedServer ?? 'Default'}, ${selectedCategory ?? 'Sub'}, $currentQuality';

    return GestureDetector(
      onTap: () => _showSettingsPanel(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.setting_2, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(
              summary,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsPanel(BuildContext context) {
    final theme = Theme.of(context);
    final currentUrl = selectedQuality ?? episodes[selectedEpisodeIndex].url; // Fallback to episode URL if no quality selected

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Iconsax.video_play, size: 24, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Video Settings',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (servers.isNotEmpty)
                _buildSettingsTile(
                  context,
                  icon: Iconsax.devices,
                  label: 'Server',
                  child: CustomDropdown(
                    icon: Iconsax.devices,
                    value: selectedServer!,
                    items: servers,
                    onChanged: onServerChange,
                  ),
                ),
              if (supportsDubSub) ...[
                const SizedBox(height: 12),
                _buildSettingsTile(
                  context,
                  icon: Iconsax.language_circle,
                  label: 'Category',
                  child: CustomDropdown(
                    icon: Iconsax.language_circle,
                    value: selectedCategory!,
                    items: const ['sub', 'dub'],
                    onChanged: onCategoryChange,
                  ),
                ),
              ],
              if (qualityOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSettingsTile(
                  context,
                  icon: Iconsax.video,
                  label: 'Quality',
                  child: CustomDropdown(
                    icon: Iconsax.video,
                    value: selectedQuality!,
                    items: qualityOptions.map((q) => q['url']!).toList(),
                    itemBuilder: (value) => Text(
                      '${qualityOptions.firstWhere((q) => q['url'] == value)['quality']} ${qualityOptions.firstWhere((q) => q['url'] == value)['isDub'] == 'true' ? '(DUB)' : ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    onChanged: onQualityChange,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildSettingsTile(
                context,
                icon: Iconsax.copy,
                label: 'Copy Source URL',
                child: ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: currentUrl ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied to clipboard!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Copy'),
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(
                context,
                icon: Iconsax.video_play,
                label: 'Open in VLC',
                child: ElevatedButton(
                  onPressed: () async {
                    final vlcUrl = Uri.parse('vlc://$currentUrl');
                    if (await canLaunchUrl(vlcUrl)) {
                      await launchUrl(vlcUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('VLC not installed or URL not supported')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Open'),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String label, required Widget child}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: child,
        ),
      ],
    );
  }
}