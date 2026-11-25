import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/features/settings/presentation/widgets/picker_sheet_shell.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

void showEpisodeModeSheet(
  BuildContext context,
  WidgetRef ref,
  UiPrefsNotifier notifier,
  ThemeData theme,
) {
  final cs = theme.colorScheme;
  final l10n = context.l10n;

  AppBottomSheet.show(
    context: context,
    title: l10n.episodeModeTitle,
    child: UiSettingsSheetLayout(
      preview: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.episodeViewMode),
          );
          return EpisodeModePreview(mode: current);
        },
      ),
      optionsTitle: l10n.episodeModePreset,
      options: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.episodeViewMode),
          );
          final options = EpisodeViewMode.values
              .map(
                (mode) => PickerOption(
                  icon: _episodeModeIcon(mode),
                  title: mode.displayName,
                  subtitle: _episodeModeDesc(context, mode),
                  selected: current == mode,
                  onTap: () => notifier.updateEpisodeViewMode(mode),
                ),
              )
              .toList();
          return PickerOptionsGrid(options: options, selectedColor: cs.primary);
        },
      ),
    ),
  );
}

const List<UnifiedEpisode> _previewEpisodes = [
  UnifiedEpisode(id: 'preview-1', number: 1, title: 'Pilot'),
  UnifiedEpisode(id: 'preview-2', number: 2, title: 'The Journey Begins'),
  UnifiedEpisode(id: 'preview-3', number: 3, title: 'First Encounter'),
];

class EpisodeModePreview extends StatelessWidget {
  final EpisodeViewMode mode;

  const EpisodeModePreview({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Durations.short4,
      curve: Curves.easeOutCubic,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: switch (mode) {
          EpisodeViewMode.classic => Column(
            key: const ValueKey('episode_preview_classic'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _previewEpisodes.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                EpisodeClassicTile(
                  episode: _previewEpisodes[i],
                  mediaType: MediaType.ANIME,
                  isCurrent: i == 0,
                  isWatched: i == 1,
                  onTap: () {},
                ),
              ],
            ],
          ),

          EpisodeViewMode.grid => Row(
            key: const ValueKey('episode_preview_grid'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _previewEpisodes.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                SizedBox(
                  width: 100,
                  height: 92,
                  child: EpisodeGridTile(
                    episode: _previewEpisodes[i],
                    mediaType: MediaType.ANIME,
                    isCurrent: i == 0,
                    isWatched: i == 1,
                    onTap: () {},
                  ),
                ),
              ],
            ],
          ),

          EpisodeViewMode.box => Wrap(
            key: const ValueKey('episode_preview_box'),
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(8, (i) {
              return SizedBox(
                width: 44,
                height: 44,
                child: EpisodeBoxTile(
                  episode: UnifiedEpisode(id: 'preview-box-$i', number: i + 1),
                  mediaType: MediaType.ANIME,
                  isCurrent: i == 0,
                  isWatched: i > 0 && i < 2,
                  onTap: () {},
                ),
              );
            }),
          ),

          EpisodeViewMode.compact => Column(
            key: const ValueKey('episode_preview_compact'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _previewEpisodes.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                EpisodeCompactTile(
                  episode: _previewEpisodes[i],
                  mediaType: MediaType.ANIME,
                  isCurrent: i == 0,
                  isWatched: i == 1,
                  onTap: () {},
                ),
              ],
            ],
          ),

          EpisodeViewMode.cover => EpisodeCoverTile(
            key: const ValueKey('episode_preview_cover'),
            episode: _previewEpisodes.first,
            mediaType: MediaType.ANIME,
            isCurrent: true,
            isWatched: false,
            onTap: () {},
          ),
        },
      ),
    );
  }
}

String _episodeModeDesc(BuildContext context, EpisodeViewMode m) {
  final l10n = context.l10n;
  return switch (m) {
    EpisodeViewMode.classic => l10n.episodeModeClassicDesc,
    EpisodeViewMode.grid => l10n.episodeModeGridDesc,
    EpisodeViewMode.box => l10n.episodeModeBoxDesc,
    EpisodeViewMode.compact => l10n.episodeModeCompactDesc,
    EpisodeViewMode.cover => l10n.episodeModeCoverDesc,
  };
}

IconData _episodeModeIcon(EpisodeViewMode m) => switch (m) {
  EpisodeViewMode.classic => Icons.view_agenda_outlined,
  EpisodeViewMode.grid => Icons.grid_view_outlined,
  EpisodeViewMode.box => Icons.tag_outlined,
  EpisodeViewMode.compact => Icons.format_list_bulleted_rounded,
  EpisodeViewMode.cover => Icons.video_library_outlined,
};
