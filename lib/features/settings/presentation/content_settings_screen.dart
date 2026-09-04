import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/content_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/selection_card_group.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/features/discovery/providers/home_feed_provider.dart';

class ContentSettingsScreen extends ConsumerWidget {
  const ContentSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(contentPrefsProvider);

    return AppScaffold(
      title: 'Content Settings',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 50),
        children: [
          SettingsSection(
            title: 'Filters',
            children: [
              SettingsSegmentedTile<AdultContentMode>(
                title: 'Show 18+ Content',
                segments: const [
                  ButtonSegment(
                    value: AdultContentMode.safe,
                    label: Text('Safe'),
                  ),
                  ButtonSegment(
                    value: AdultContentMode.mixed,
                    label: Text('Mixed'),
                  ),
                  ButtonSegment(
                    value: AdultContentMode.adultOnly,
                    label: Text('18+ Only'),
                  ),
                ],
                selected: {prefs.adultContentMode},
                onSelectionChanged: (set) {
                  if (set.isNotEmpty) {
                    ref
                        .read(contentPrefsProvider.notifier)
                        .setAdultContentMode(set.first);
                  }
                },
              ),
              SettingsDropdownTile<TitlePreference>(
                icon: Icons.title_rounded,
                title: 'Preferred Title Language',
                value: prefs.titlePreference,
                items: TitlePreference.values
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(contentPrefsProvider.notifier)
                        .setTitlePreference(val);
                    ref.invalidate(homeSectionFeedProvider);
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: 'Episode Metadata',
            children: [
              SettingsNavTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Episode Metadata Provider',
                subtitle: prefs.episodeMetadataProvider.displayName,
                onTap: () => _showMetadataProviderSheet(
                  context,
                  ref,
                  prefs.episodeMetadataProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMetadataProviderSheet(
    BuildContext context,
    WidgetRef ref,
    EpisodeMetadataProviderType activeProvider,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Episode Metadata Provider',
      titleIcon: Icons.auto_awesome_rounded,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectionCardGroup(
              title: 'Available Providers',
              subtitle:
                  'Select which provider enriches episode titles and thumbnails.',
              children: [
                _buildProviderTile(
                  context,
                  type: EpisodeMetadataProviderType.auto,
                  activeProvider: activeProvider,
                  icon: Icons.auto_mode_rounded,
                  title: 'Auto (Recommended)',
                  subtitle: 'Tenrai → Kitsu → AniZip (Thumbnails & metadata)',
                  showDivider: true,
                  onTap: () {
                    ref
                        .read(contentPrefsProvider.notifier)
                        .setEpisodeMetadataProvider(
                          EpisodeMetadataProviderType.auto,
                        );
                    Navigator.pop(context);
                  },
                ),
                _buildProviderTile(
                  context,
                  type: EpisodeMetadataProviderType.tenrai,
                  activeProvider: activeProvider,
                  icon: Icons.image_rounded,
                  title: 'Tenrai',
                  subtitle:
                      'Official titles, air dates & thumbnails from MyAnimeList',
                  showDivider: true,
                  onTap: () {
                    ref
                        .read(contentPrefsProvider.notifier)
                        .setEpisodeMetadataProvider(
                          EpisodeMetadataProviderType.tenrai,
                        );
                    Navigator.pop(context);
                  },
                ),
                _buildProviderTile(
                  context,
                  type: EpisodeMetadataProviderType.kitsu,
                  activeProvider: activeProvider,
                  icon: Icons.collections_rounded,
                  title: 'Kitsu',
                  subtitle: 'Community titles, synopses & preview thumbnails',
                  showDivider: true,
                  onTap: () {
                    ref
                        .read(contentPrefsProvider.notifier)
                        .setEpisodeMetadataProvider(
                          EpisodeMetadataProviderType.kitsu,
                        );
                    Navigator.pop(context);
                  },
                ),
                _buildProviderTile(
                  context,
                  type: EpisodeMetadataProviderType.anizip,
                  activeProvider: activeProvider,
                  icon: Icons.speed_rounded,
                  title: 'AniZip',
                  subtitle:
                      'Fast titles & synopses from AniList / MAL (No thumbnails)',
                  showDivider: true,
                  onTap: () {
                    ref
                        .read(contentPrefsProvider.notifier)
                        .setEpisodeMetadataProvider(
                          EpisodeMetadataProviderType.anizip,
                        );
                    Navigator.pop(context);
                  },
                ),
                _buildProviderTile(
                  context,
                  type: EpisodeMetadataProviderType.disabled,
                  activeProvider: activeProvider,
                  icon: Icons.do_not_disturb_on_rounded,
                  title: 'Disabled',
                  subtitle: 'Raw stream titles without external metadata',
                  showDivider: false,
                  onTap: () {
                    ref
                        .read(contentPrefsProvider.notifier)
                        .setEpisodeMetadataProvider(
                          EpisodeMetadataProviderType.disabled,
                        );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile(
    BuildContext context, {
    required EpisodeMetadataProviderType type,
    required EpisodeMetadataProviderType activeProvider,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = type == activeProvider;

    return SelectionCardTile(
      isSelected: isSelected,
      showDivider: showDivider,
      leading: Icon(
        icon,
        size: 20,
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
