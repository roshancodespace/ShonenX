import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/history/domain/models/history_entry.dart';
import 'package:shonenx/features/settings/presentation/widgets/picker_sheet_shell.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

final _previewHistoryEntry = HistoryEntry()
  ..mediaId = '1'
  ..mediaTitle = 'One Piece'
  ..mediaType = MediaType.ANIME.id
  ..itemNumber = 7
  ..itemTitle = 'Orewa Kaizoku Ou Ni Naru!'
  ..progress = 720000
  ..total = 1200000
  ..thumbnailUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

final _previewReadHistoryEntry = HistoryEntry()
  ..mediaId = '2'
  ..mediaTitle = 'One Piece'
  ..mediaType = MediaType.MANGA.id
  ..itemNumber = 236
  ..itemTitle = 'Orewa Kaizoku Ou Ni Naru!'
  ..progress = 14
  ..total = 20
  ..cover =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

void _showCardStylePickerSheet({
  required BuildContext context,
  required String title,
  required String optionsTitle,
  required MediaCardStyle Function(UiPrefState) getStyle,
  required bool Function(UiPrefState, String) getIsWide,
  required void Function(UiPrefsNotifier, MediaCardStyle) onSelectStyle,
  required Widget Function(
    BuildContext,
    UiPrefState,
    MediaCardStyle,
    bool isWide,
  )
  previewBuilder,
  Widget Function(BuildContext, WidgetRef, UiPrefState)? togglesBuilder,
}) {
  final cs = Theme.of(context).colorScheme;

  AppBottomSheet.show(
    context: context,
    title: title,
    child: UiSettingsSheetLayout(
      preview: Consumer(
        builder: (ctx, r, _) {
          final uiState = r.watch(uiPrefsProvider);
          final current = getStyle(uiState);
          final isWide = getIsWide(uiState, current.name);
          return previewBuilder(ctx, uiState, current, isWide);
        },
      ),
      optionsTitle: optionsTitle,
      options: Consumer(
        builder: (_, r, _) {
          final notifier = r.read(uiPrefsProvider.notifier);
          final uiState = r.watch(uiPrefsProvider);
          final current = getStyle(uiState);
          final options = MediaCardStyle.values
              .map(
                (style) => PickerOption(
                  icon: _cardStyleIcon(style),
                  title: style.displayName,
                  subtitle: _cardStyleDesc(style),
                  selected: current == style,
                  onTap: () => onSelectStyle(notifier, style),
                ),
              )
              .toList();
          return PickerOptionsGrid(options: options, selectedColor: cs.primary);
        },
      ),
      toggles: togglesBuilder != null
          ? Consumer(
              builder: (ctx, r, _) =>
                  togglesBuilder(ctx, r, r.watch(uiPrefsProvider)),
            )
          : null,
    ),
  );
}

void showCardStyleSheet(
  BuildContext context,
  WidgetRef ref,
  UiPrefsNotifier notifier,
  ThemeData theme,
) {
  _showCardStylePickerSheet(
    context: context,
    title: 'Card Style',
    optionsTitle: 'Card Style Preset',
    getStyle: (s) => s.cardStyle,
    getIsWide: (s, name) => s.isMediaCardWide(name),
    onSelectStyle: (n, style) => n.updateCardStyle(style),
    previewBuilder: (ctx, state, style, isWide) {
      final layout = style.getLayout(isWideMode: isWide);
      return SizedBox(
        width: layout.width,
        height: layout.height,
        child: MediaCard(
          media: UnifiedMedia(
            id: 'ui-preview',
            type: MediaType.ANIME,
            title: const MediaTitle(english: 'Demon Slayer: Kimetsu No Yaiba'),
            format: 'TV',
            score: 8.7,
            year: 2024,
            status: 'Ongoing',
            genres: const ['Action', 'Fantasy'],
            cover:
                'https://m.media-amazon.com/images/M/MV5BM2IyN2E0NjctYWU2ZC00ZDc4LThiOTQtODAyOGNkZWM0M2E1XkEyXkFqcGc@._V1_.jpg',
          ),
          tag: 'ui-card-preview',
          onTap: () {},
          style: style,
        ),
      );
    },
    togglesBuilder: (ctx, r, uiState) {
      final notifier = r.read(uiPrefsProvider.notifier);
      final current = uiState.cardStyle;
      final isWide = uiState.isMediaCardWide(current.name);
      final canToggleWide =
          current != MediaCardStyle.compact &&
          current != MediaCardStyle.cinematic &&
          current != MediaCardStyle.wideBanner;

      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilterChip(
            avatar: const Icon(Icons.star_rounded, size: 16),
            label: const Text('Ratings'),
            selected: uiState.showCardRatings,
            onSelected: (_) => notifier.toggleShowCardRatings(),
          ),
          FilterChip(
            avatar: const Icon(Icons.category_rounded, size: 16),
            label: const Text('Genres'),
            selected: uiState.showCardGenres,
            onSelected: (_) => notifier.toggleShowCardGenres(),
          ),
          FilterChip(
            avatar: const Icon(Icons.calendar_today_rounded, size: 16),
            label: const Text('Release Year'),
            selected: uiState.showCardYear,
            onSelected: (_) => notifier.toggleShowCardYear(),
          ),
          if (canToggleWide)
            FilterChip(
              avatar: Icon(
                isWide ? Icons.table_rows_rounded : Icons.grid_view_rounded,
                size: 16,
              ),
              label: Text(isWide ? 'Wide Mode' : 'Portrait Mode'),
              selected: isWide,
              onSelected: (_) => notifier.toggleMediaCardWide(current.name),
            ),
        ],
      );
    },
  );
}

void showContinueWatchingSheet(
  BuildContext context,
  WidgetRef ref,
  UiPrefsNotifier notifier,
  ThemeData theme,
) {
  _showCardStylePickerSheet(
    context: context,
    title: 'Continue Watching Style',
    optionsTitle: 'Continue Watching Style Preset',
    getStyle: (s) => s.continueWatchingStyle,
    getIsWide: (s, name) => s.isContinueWatchingWide(name),
    onSelectStyle: (n, style) => n.updateContinueWatchingStyle(style),
    previewBuilder: (ctx, state, style, isWide) {
      return ContinueWatchingItem(
        style: style,
        progress: 0.72,
        entry: _previewHistoryEntry,
      );
    },
  );
}

void showContinueReadingSheet(
  BuildContext context,
  WidgetRef ref,
  UiPrefsNotifier notifier,
  ThemeData theme,
) {
  _showCardStylePickerSheet(
    context: context,
    title: 'Continue Reading Style',
    optionsTitle: 'Continue Reading Style Preset',
    getStyle: (s) => s.continueReadingStyle,
    getIsWide: (s, name) => s.isContinueReadingWide(name),
    onSelectStyle: (n, style) => n.updateContinueReadingStyle(style),
    previewBuilder: (ctx, state, style, isWide) {
      return ContinueReadingItem(
        style: style,
        progress: 0.72,
        entry: _previewReadHistoryEntry,
      );
    },
  );
}

IconData _cardStyleIcon(MediaCardStyle s) => switch (s) {
  MediaCardStyle.classic => Icons.grid_view_rounded,
  MediaCardStyle.minimal => Icons.photo_size_select_actual_rounded,
  MediaCardStyle.expressive => Icons.featured_play_list_rounded,
  MediaCardStyle.material => Icons.crop_portrait_rounded,
  MediaCardStyle.cinematic => Icons.movie_filter_rounded,
  MediaCardStyle.neon => Icons.electric_bolt_rounded,
  MediaCardStyle.compact => Icons.table_rows_rounded,
  MediaCardStyle.editorial => Icons.newspaper_rounded,
  MediaCardStyle.wideBanner => Icons.view_headline_rounded,
};

String _cardStyleDesc(MediaCardStyle s) => switch (s) {
  MediaCardStyle.classic => 'Classic poster layout with metadata overlay',
  MediaCardStyle.minimal => 'Clean border-free poster card',
  MediaCardStyle.expressive => 'Spacious container with bold badges',
  MediaCardStyle.material => 'Rounded Material card styling',
  MediaCardStyle.cinematic => 'Full-bleed cinematic landscape view',
  MediaCardStyle.neon => 'Glowing vibrant accent borders',
  MediaCardStyle.compact => 'Dense compact layout for high density',
  MediaCardStyle.editorial => 'High-whitespace magazine design',
  MediaCardStyle.wideBanner => 'Wide horizontal banner card',
};
