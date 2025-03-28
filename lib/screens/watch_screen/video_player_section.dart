import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shonenx/api/models/anime/episode_model.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart' as anilist_media;
import 'package:shonenx/api/models/anime/source_model.dart';
import 'package:shonenx/screens/watch_screen/custom_dropdown.dart';
import 'package:shonenx/widgets/player/controls.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoPlayerSection extends StatelessWidget {
  final String animeName;
  final List<EpisodeDataModel> episodes;
  final int selectedEpisodeIndex;
  final VideoController controller;
  final List<SubtitleTrack> subtitles;
  final anilist_media.Media animeMedia;
  final List<Source> sources;
  final ValueNotifier<Source?> selectedSource; // Changed to ValueNotifier
  final List<String> servers;
  final ValueNotifier<String?> selectedServer; // Changed to ValueNotifier
  final bool supportsDubSub;
  final ValueNotifier<String?> selectedCategory; // Changed to ValueNotifier
  final List<Map<String, String>> qualityOptions;
  final ValueNotifier<String?> selectedQuality; // Changed to ValueNotifier
  final void Function(Source) onSourceChange;
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
    required this.sources,
    required this.selectedSource,
    required this.servers,
    required this.selectedServer,
    required this.supportsDubSub,
    required this.selectedCategory,
    required this.qualityOptions,
    required this.selectedQuality,
    required this.onSourceChange,
    required this.onServerChange,
    required this.onCategoryChange,
    required this.onQualityChange,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
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
          child: Stack(
            children: [
              Video(
                controller: controller,
                controls: (videoState) => CustomControls(
                  animeMedia: animeMedia,
                  state: videoState,
                  subtitles: subtitles,
                  episodes: episodes,
                  currentEpisodeIndex: selectedEpisodeIndex,
                ),
                subtitleViewConfiguration: const SubtitleViewConfiguration(
                  visible: false,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _buildVideoSettings(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSettings(BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: selectedQuality,
      builder: (context, quality, _) {
        final currentQuality = qualityOptions.isNotEmpty
            ? qualityOptions.firstWhere(
                (q) => q['url'] == quality,
                orElse: () => {'quality': 'Auto', 'isDub': 'false'},
              )['quality']
            : 'Auto';
        return ValueListenableBuilder<String?>(
          valueListenable: selectedServer,
          builder: (context, server, _) => ValueListenableBuilder<String?>(
            valueListenable: selectedCategory,
            builder: (context, category, _) {
              final summary =
                  '${server ?? 'Default'}, ${category ?? 'Sub'}, $currentQuality';
              return GestureDetector(
                onTap: () => _showSettingsPanel(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showSettingsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      builder: (context) => _SettingsPanel(
        episodes: episodes,
        selectedEpisodeIndex: selectedEpisodeIndex,
        sources: sources,
        selectedSource: selectedSource,
        servers: servers,
        selectedServer: selectedServer,
        supportsDubSub: supportsDubSub,
        selectedCategory: selectedCategory,
        qualityOptions: qualityOptions,
        selectedQuality: selectedQuality,
        onSourceChange: onSourceChange,
        onServerChange: onServerChange,
        onCategoryChange: onCategoryChange,
        onQualityChange: onQualityChange,
      ),
    );
  }
}

class _SettingsPanel extends StatefulWidget {
  final List<EpisodeDataModel> episodes;
  final int selectedEpisodeIndex;
  final List<Source> sources;
  final ValueNotifier<Source?> selectedSource;
  final List<String> servers;
  final ValueNotifier<String?> selectedServer;
  final bool supportsDubSub;
  final ValueNotifier<String?> selectedCategory;
  final List<Map<String, String>> qualityOptions;
  final ValueNotifier<String?> selectedQuality;
  final void Function(Source) onSourceChange;
  final void Function(String) onServerChange;
  final void Function(String) onCategoryChange;
  final void Function(String) onQualityChange;

  const _SettingsPanel({
    required this.episodes,
    required this.selectedEpisodeIndex,
    required this.sources,
    required this.selectedSource,
    required this.servers,
    required this.selectedServer,
    required this.supportsDubSub,
    required this.selectedCategory,
    required this.qualityOptions,
    required this.selectedQuality,
    required this.onSourceChange,
    required this.onServerChange,
    required this.onCategoryChange,
    required this.onQualityChange,
  });

  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Video Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Iconsax.close_circle,
                      size: 24, color: theme.colorScheme.onSurfaceVariant),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Episode ${widget.episodes[widget.selectedEpisodeIndex].number}: ${widget.episodes[widget.selectedEpisodeIndex].title ?? 'Untitled'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.sources.isNotEmpty) ...[
                      ValueListenableBuilder<Source?>(
                        valueListenable: widget.selectedSource,
                        builder: (context, source, _) => _buildSettingsTile(
                          context,
                          icon: Iconsax.cloud_change,
                          label: 'Source',
                          child: CustomDropdown(
                            icon: Iconsax.cloud,
                            value: source?.quality ?? 'Default',
                            items: widget.sources
                                .map((source) => source.quality ?? 'Default')
                                .toList(),
                            onChanged: (value) {
                              final newSource = widget.sources.firstWhere(
                                  (source) => source.quality == value);
                              if (newSource.url != null) {
                                widget.onSourceChange(newSource);
                                widget.selectedSource.value = newSource;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.servers.isNotEmpty) ...[
                      ValueListenableBuilder<String?>(
                        valueListenable: widget.selectedServer,
                        builder: (context, server, _) => _buildSettingsTile(
                          context,
                          icon: Iconsax.devices,
                          label: 'Server',
                          child: CustomDropdown(
                            icon: Iconsax.devices,
                            value: server ?? 'Default',
                            items: widget.servers,
                            onChanged: (value) {
                              widget.onServerChange(value);
                              widget.selectedServer.value = value;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.supportsDubSub) ...[
                      ValueListenableBuilder<String?>(
                        valueListenable: widget.selectedCategory,
                        builder: (context, category, _) => _buildSettingsTile(
                          context,
                          icon: Iconsax.language_circle,
                          label: 'Category',
                          child: CustomDropdown(
                            icon: Iconsax.language_circle,
                            value: category ?? 'sub',
                            items: const ['sub', 'dub'],
                            onChanged: (value) {
                              widget.onCategoryChange(value);
                              widget.selectedCategory.value = value;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (widget.qualityOptions.isNotEmpty) ...[
                      ValueListenableBuilder<String?>(
                        valueListenable: widget.selectedQuality,
                        builder: (context, quality, _) => _buildSettingsTile(
                          context,
                          icon: Iconsax.video,
                          label: 'Quality',
                          child: CustomDropdown(
                            icon: Iconsax.video,
                            value: quality ?? widget.qualityOptions.first['url']!,
                            items: widget.qualityOptions.map((q) => q['url']!).toList(),
                            itemBuilder: (value) => Text(
                              '${widget.qualityOptions.firstWhere((q) => q['url'] == value)['quality']} ${widget.qualityOptions.firstWhere((q) => q['url'] == value)['isDub'] == 'true' ? '(DUB)' : ''}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            onChanged: (value) {
                              widget.onQualityChange(value);
                              widget.selectedQuality.value = value;
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ValueListenableBuilder<String?>(
                      valueListenable: widget.selectedQuality,
                      builder: (context, quality, _) => _buildSettingsTile(
                        context,
                        icon: Iconsax.copy,
                        label: 'Copy Source URL',
                        child: ElevatedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: quality ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URL copied to clipboard!')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Copy'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String?>(
                      valueListenable: widget.selectedQuality,
                      builder: (context, quality, _) => _buildSettingsTile(
                        context,
                        icon: Iconsax.video_play,
                        label: 'Open in VLC',
                        child: ElevatedButton(
                          onPressed: () async {
                            final vlcUrl = Uri.parse('vlc://${quality ?? ''}');
                            if (await canLaunchUrl(vlcUrl)) {
                              await launchUrl(vlcUrl,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('VLC not installed or URL not supported')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Open'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 3,
          child: child,
        ),
      ],
    );
  }
}