import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

final _previewHistoryEntry = WatchHistoryEntry()
  ..animeId = '1'
  ..animeTitle = 'One Piece'
  ..episodeNumber = 7
  ..episodeTitle = 'Orewa Kaizoku Ou Ni Naru!'
  ..positionInMilliseconds = 720000
  ..durationInMilliseconds = 1200000
  ..thumbnailUrl =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

final _previewReadHistoryEntry = ReadHistoryEntry()
  ..mangaId = '2'
  ..mangaTitle = 'One Piece'
  ..chapterNumber = 236
  ..chapterTitle = 'Orewa Kaizoku Ou Ni Naru!'
  ..positionPage = 14
  ..totalPages = 20
  ..cover =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

class UiSettingsSheetLayout extends StatelessWidget {
  final Widget preview;
  final String optionsTitle;
  final Widget options;
  final String? togglesTitle;
  final Widget? toggles;

  const UiSettingsSheetLayout({
    super.key,
    required this.preview,
    required this.optionsTitle,
    required this.options,
    this.togglesTitle,
    this.toggles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Center(child: preview),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              optionsTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: options,
          ),
          if (toggles != null) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                togglesTitle ?? 'Display Options',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: toggles!,
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

void showAppearanceSheet(
  BuildContext context,
  WidgetRef ref,
  ThemePrefsNotifier themeNotifier,
  ThemePrefsState initialThemePrefs,
  ThemeData theme,
) {
  AppBottomSheet.show(
    context: context,
    title: 'Global UI Customization',
    child: Consumer(
      builder: (_, r, __) {
        final currentPrefs = r.watch(themePrefsProvider);
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGlobalUiPreview(
                theme,
                currentPrefs.uiRoundness,
                currentPrefs.fontScaleFactor,
                currentPrefs.uiScaleFactor,
              ),
              SettingsSliderTile(
                title: 'Border Roundness',
                subtitle: 'Corner roundness across the app',
                value: currentPrefs.uiRoundness,
                min: 0.0,
                max: 32.0,
                divisions: 32,
                label: currentPrefs.uiRoundness.toStringAsFixed(1),
                icon: Icons.rounded_corner_outlined,
                onChanged: (v) => themeNotifier.updateTheme(
                  (s) => s.copyWith(uiRoundness: v),
                ),
              ),
              SettingsSliderTile(
                title: 'Font Scale',
                subtitle: 'Scale text size globally',
                value: currentPrefs.fontScaleFactor,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(currentPrefs.fontScaleFactor * 100).toInt()}%',
                icon: Icons.format_size_outlined,
                onChanged: (v) => themeNotifier.updateTheme(
                  (s) => s.copyWith(fontScaleFactor: v),
                ),
              ),
              SettingsSliderTile(
                title: 'Widget Scale',
                subtitle: 'Scale media cards & navigation bar',
                value: currentPrefs.uiScaleFactor,
                min: 0.8,
                max: 1.5,
                divisions: 7,
                label: '${(currentPrefs.uiScaleFactor * 100).toInt()}%',
                icon: Icons.aspect_ratio_outlined,
                onChanged: (v) => themeNotifier.updateTheme(
                  (s) => s.copyWith(uiScaleFactor: v),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildGlobalUiPreview(
  ThemeData theme,
  double roundness,
  double fontScale,
  double uiScale,
) {
  final cs = theme.colorScheme;
  return Container(
    height: 120,
    alignment: Alignment.center,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: AnimatedScale(
      scale: uiScale,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Builder(
        builder: (context) {
          final currentTextScale = MediaQuery.of(context).textScaler.scale(1.0);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(currentTextScale / uiScale),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              width: 220,
              height: 84,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(roundness),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(roundness * 0.6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Primary text',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14 * fontScale,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          'Secondary text',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

void _showMediaStylePickerSheet({
  required BuildContext context,
  required String title,
  required String optionsTitle,
  required MediaCardStyle Function(UiPrefState) getStyle,
  required bool Function(UiPrefState, String) getIsWide,
  required void Function(UiPrefsNotifier, MediaCardStyle) onSelectStyle,
  required void Function(UiPrefsNotifier, String) onToggleWide,
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
    actions: [
      Consumer(
        builder: (_, r, __) {
          final notifier = r.read(uiPrefsProvider.notifier);
          final uiState = r.watch(uiPrefsProvider);
          final current = getStyle(uiState);
          final isWide = getIsWide(uiState, current.name);
          final canToggleWide =
              current != MediaCardStyle.compact &&
              current != MediaCardStyle.cinematic &&
              current != MediaCardStyle.wideBanner;

          if (!canToggleWide) return const SizedBox.shrink();

          return Tooltip(
            message: isWide ? 'Switch to Portrait Mode' : 'Switch to Wide Mode',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onToggleWide(notifier, current.name),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isWide
                        ? cs.primaryContainer
                        : cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isWide
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isWide
                            ? Icons.table_rows_rounded
                            : Icons.grid_view_rounded,
                        size: 15,
                        color: isWide
                            ? cs.onPrimaryContainer
                            : cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isWide ? 'Wide' : 'Normal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isWide
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ],
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
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 54,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: MediaCardStyle.values.length,
            itemBuilder: (context, index) {
              final style = MediaCardStyle.values[index];
              return _StyleGridCard(
                selected: current == style,
                icon: _cardStyleIcon(style),
                title: style.displayName,
                subtitle: _cardStyleDesc(style),
                selectedColor: cs.primary,
                onTap: () => onSelectStyle(notifier, style),
              );
            },
          );
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
  _showMediaStylePickerSheet(
    context: context,
    title: 'Card Style',
    optionsTitle: 'Card Style Preset',
    getStyle: (s) => s.cardStyle,
    getIsWide: (s, name) => s.isMediaCardWide(name),
    onSelectStyle: (n, style) => n.updateCardStyle(style),
    onToggleWide: (n, name) => n.toggleMediaCardWide(name),
    previewBuilder: (ctx, state, style, isWide) {
      final layout = style.getLayout(isWideMode: isWide);
      return SizedBox(
        width: layout.width,
        height: layout.height,
        child: MediaCard(
          title: 'Demon Slayer: Kimetsu No Yaiba',
          tag: 'ui-card-preview',
          format: 'TV',
          score: 8.7,
          year: '2024',
          status: 'Ongoing',
          genres: const ['Action', 'Fantasy'],
          imageUrl:
              'https://m.media-amazon.com/images/M/MV5BM2IyN2E0NjctYWU2ZC00ZDc4LThiOTQtODAyOGNkZWM0M2E1XkEyXkFqcGc@._V1_.jpg',
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
  _showMediaStylePickerSheet(
    context: context,
    title: 'Continue Watching Style',
    optionsTitle: 'Continue Watching Style Preset',
    getStyle: (s) => s.continueWatchingStyle,
    getIsWide: (s, name) => s.isContinueWatchingWide(name),
    onSelectStyle: (n, style) => n.updateContinueWatchingStyle(style),
    onToggleWide: (n, name) => n.toggleContinueWatchingWide(name),
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
  _showMediaStylePickerSheet(
    context: context,
    title: 'Continue Reading Style',
    optionsTitle: 'Continue Reading Style Preset',
    getStyle: (s) => s.continueReadingStyle,
    getIsWide: (s, name) => s.isContinueReadingWide(name),
    onSelectStyle: (n, style) => n.updateContinueReadingStyle(style),
    onToggleWide: (n, name) => n.toggleContinueReadingWide(name),
    previewBuilder: (ctx, state, style, isWide) {
      return ContinueReadingItem(
        style: style,
        progress: 0.72,
        entry: _previewReadHistoryEntry,
      );
    },
  );
}

void showEpisodeModeSheet(
  BuildContext context,
  WidgetRef ref,
  UiPrefsNotifier notifier,
  ThemeData theme,
) {
  final cs = theme.colorScheme;

  AppBottomSheet.show(
    context: context,
    title: 'Episode View Mode',
    child: UiSettingsSheetLayout(
      preview: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.episodeViewMode),
          );
          return _EpisodeViewModePreview(mode: current);
        },
      ),
      optionsTitle: 'Episode View Mode Preset',
      options: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.episodeViewMode),
          );
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 54,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: EpisodeViewMode.values.length,
            itemBuilder: (context, index) {
              final mode = EpisodeViewMode.values[index];
              return _StyleGridCard(
                selected: current == mode,
                icon: _episodeModeIcon(mode),
                title: mode.displayName,
                subtitle: _episodeModeDesc(mode),
                selectedColor: cs.primary,
                onTap: () => notifier.updateEpisodeViewMode(mode),
              );
            },
          );
        },
      ),
    ),
  );
}

// ── Navigation Bar Sheet ─────────────────────────────────────────────────────

void showNavBarStyleSheet(
  BuildContext context,
  WidgetRef ref,
  UiPrefsNotifier notifier,
  ThemeData theme,
) {
  final cs = theme.colorScheme;

  AppBottomSheet.show(
    context: context,
    title: 'Navigation Bar Style',
    child: Consumer(
      builder: (_, r, _) {
        final current = r.watch(uiPrefsProvider.select((s) => s.navBarStyle));

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Builder(
                    builder: (context) {
                      const double barHeight = 52.0;
                      const double hPad = 6.0;
                      final barRadius =
                          (current == NavBarStyle.material ||
                              current == NavBarStyle.minimal)
                          ? barHeight / 2
                          : 12.0;

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(barRadius),
                        child: Container(
                          height: barHeight,
                          padding: const EdgeInsets.all(hPad),
                          decoration: switch (current) {
                            NavBarStyle.classic => BoxDecoration(
                              color: cs.surface.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(barRadius),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                            NavBarStyle.minimal => BoxDecoration(
                              color: cs.surface.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(barRadius),
                              border: Border.all(
                                color: cs.outlineVariant.withValues(alpha: 0.2),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            NavBarStyle.frosted => BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(barRadius),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 0.8,
                              ),
                            ),
                            NavBarStyle.material => BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(barRadius),
                            ),
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildPreviewItem(
                                'Home',
                                Icons.home_outlined,
                                true,
                                cs,
                                current,
                              ),
                              const SizedBox(width: 8),
                              _buildPreviewItem(
                                'Search',
                                Icons.search_rounded,
                                false,
                                cs,
                                current,
                              ),
                              const SizedBox(width: 8),
                              _buildPreviewItem(
                                'Library',
                                Icons.library_books_outlined,
                                false,
                                cs,
                                current,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Navigation Bar Preset',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisExtent: 58,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: NavBarStyle.values.length,
                  itemBuilder: (context, index) {
                    final style = NavBarStyle.values[index];
                    return _StyleGridCard(
                      selected: current == style,
                      icon: _navBarStyleIcon(style),
                      title: style.displayName,
                      subtitle: _navBarStyleDesc(style),
                      selectedColor: cs.primary,
                      onTap: () => notifier.updateNavBarStyle(style),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildPreviewItem(
  String label,
  IconData icon,
  bool active,
  ColorScheme cs,
  NavBarStyle style,
) {
  final activeIconColor = switch (style) {
    NavBarStyle.material => cs.onSecondaryContainer,
    NavBarStyle.frosted => Colors.white,
    NavBarStyle.minimal => cs.primary,
    _ => cs.onPrimary,
  };

  final inactiveIconColor = switch (style) {
    NavBarStyle.frosted => Colors.white54,
    NavBarStyle.minimal => cs.onSurfaceVariant.withValues(alpha: 0.5),
    _ => cs.onSurfaceVariant,
  };

  final activeTextColor = switch (style) {
    NavBarStyle.material => cs.onSecondaryContainer,
    NavBarStyle.frosted => Colors.white,
    NavBarStyle.minimal => cs.primary,
    _ => cs.onPrimary,
  };

  final itemDecoration = switch (style) {
    NavBarStyle.classic => BoxDecoration(
      color: active ? cs.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    ),
    NavBarStyle.minimal => const BoxDecoration(color: Colors.transparent),
    NavBarStyle.frosted => BoxDecoration(
      color: active ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      border: active
          ? Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5)
          : null,
    ),
    NavBarStyle.material => BoxDecoration(
      color: active ? cs.secondaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
    ),
  };

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: itemDecoration,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? activeIconColor : inactiveIconColor,
              size: 18,
            ),
            if (active) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: activeTextColor,
                ),
              ),
            ],
          ],
        ),
        if (style == NavBarStyle.minimal && active) ...[
          const SizedBox(height: 2),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    ),
  );
}

class _StyleGridCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color selectedColor;
  final VoidCallback onTap;

  const _StyleGridCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.15)
                : cs.surfaceContainerLow.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? selectedColor : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: cs.onSurfaceVariant.withValues(
                          alpha: selected ? 0.9 : 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                Icon(Icons.check_rounded, size: 16, color: selectedColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeViewModePreview extends StatelessWidget {
  final EpisodeViewMode mode;

  const _EpisodeViewModePreview({required this.mode});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final roundness = GlobalUI.uiRoundness.clamp(8.0, 20.0);

    return AnimatedSize(
      duration: Durations.short4,
      curve: Curves.easeOutCubic,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: switch (mode) {
          EpisodeViewMode.classic => Column(
            key: const ValueKey('classic_flat'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlatClassicRow(
                cs,
                roundness,
                num: '1',
                title: 'Pilot',
                time: '24m',
                isActive: true,
              ),
              const SizedBox(height: 6),
              _buildFlatClassicRow(
                cs,
                roundness,
                num: '2',
                title: 'The Journey Begins',
                time: '24m',
                isActive: false,
              ),
            ],
          ),

          EpisodeViewMode.grid => Row(
            key: const ValueKey('grid_flat'),
            children: [
              Expanded(
                child: _buildFlatGridItem(
                  cs,
                  roundness,
                  num: '1',
                  title: 'Pilot',
                  isActive: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFlatGridItem(
                  cs,
                  roundness,
                  num: '2',
                  title: 'Journey',
                  isActive: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildFlatGridItem(
                  cs,
                  roundness,
                  num: '3',
                  title: 'Encounter',
                  isActive: false,
                ),
              ),
            ],
          ),

          EpisodeViewMode.box => Wrap(
            key: const ValueKey('box_flat'),
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: List.generate(8, (i) {
              final active = i == 2;
              final watched = i < 2;
              return Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? cs.primary
                      : watched
                      ? cs.surfaceContainerHighest
                      : cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(roundness * 0.6),
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    color: active
                        ? cs.onPrimary
                        : watched
                        ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                        : cs.onSurface,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              );
            }),
          ),

          EpisodeViewMode.compact => Column(
            key: const ValueKey('compact_flat'),
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFlatCompactRow(
                cs,
                roundness,
                num: '1',
                title: 'Pilot',
                isActive: true,
              ),
              const SizedBox(height: 6),
              _buildFlatCompactRow(
                cs,
                roundness,
                num: '2',
                title: 'The Journey Begins',
                isActive: false,
              ),
              const SizedBox(height: 6),
              _buildFlatCompactRow(
                cs,
                roundness,
                num: '3',
                title: 'First Encounter',
                isActive: false,
              ),
            ],
          ),

          EpisodeViewMode.cover => _buildFlatCoverCard(cs, roundness),
        },
      ),
    );
  }

  Widget _buildFlatClassicRow(
    ColorScheme cs,
    double roundness, {
    required String num,
    required String title,
    required String time,
    required bool isActive,
  }) {
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.25)
            : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(roundness),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 2,
                height: 10,
                color: isActive ? cs.primary.withValues(alpha: 0.3) : dimColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Icon(
                  isActive
                      ? Icons.play_circle_fill_rounded
                      : Icons.check_circle,
                  size: 26,
                  color: isActive ? cs.primary : dimColor,
                ),
              ),
              Container(
                width: 2,
                height: 10,
                color: isActive ? cs.primary.withValues(alpha: 0.3) : dimColor,
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ep $num',
                  style: TextStyle(
                    color: isActive ? cs.primary : dimColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatGridItem(
    ColorScheme cs,
    double roundness, {
    required String num,
    required String title,
    required bool isActive,
  }) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(roundness * 0.8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.6, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    num,
                    style: TextStyle(
                      color: isActive ? cs.primary : Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontStyle: FontStyle.italic,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isActive)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'NOW',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatCompactRow(
    ColorScheme cs,
    double roundness, {
    required String num,
    required String title,
    required bool isActive,
  }) {
    final dimColor = cs.onSurfaceVariant.withValues(alpha: 0.5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? cs.primaryContainer.withValues(alpha: 0.35)
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(roundness * 0.7),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? cs.primary : cs.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: TextStyle(
                color: isActive ? cs.onPrimary : cs.onSurface,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? cs.primary : cs.onSurface,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isActive)
            Icon(Icons.play_circle_fill_rounded, size: 18, color: cs.primary)
          else
            Icon(Icons.check_circle_rounded, size: 16, color: dimColor),
        ],
      ),
    );
  }

  Widget _buildFlatCoverCard(ColorScheme cs, double roundness) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        key: const ValueKey('cover_flat'),
        width: double.maxFinite,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(roundness),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.65, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.88),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: cs.onPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Episode 1',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'The Beginning of a Legend',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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

String _episodeModeDesc(EpisodeViewMode m) => switch (m) {
  EpisodeViewMode.classic => 'Detailed list with episode art and title',
  EpisodeViewMode.grid => 'Thumbnail grid with episode numbers',
  EpisodeViewMode.box => 'Compact numbered boxes — great for long anime',
  EpisodeViewMode.compact =>
    'Clean text rows without thumbnails for fast browsing',
  EpisodeViewMode.cover => 'Cinematic wide cards with prominent action bar',
};

IconData _episodeModeIcon(EpisodeViewMode m) => switch (m) {
  EpisodeViewMode.classic => Icons.view_agenda_outlined,
  EpisodeViewMode.grid => Icons.grid_view_outlined,
  EpisodeViewMode.box => Icons.tag_outlined,
  EpisodeViewMode.compact => Icons.format_list_bulleted_rounded,
  EpisodeViewMode.cover => Icons.movie_creation_outlined,
};

String _navBarStyleDesc(NavBarStyle style) => switch (style) {
  NavBarStyle.classic => 'Floating container with modern backdrop blur',
  NavBarStyle.minimal => 'Sleek, transparent floating glass dock style',
  NavBarStyle.frosted => 'Super-translucent frosted glassmorphism layout',
  NavBarStyle.material =>
    'Material You rounded capsules with navigation indicators',
};

IconData _navBarStyleIcon(NavBarStyle style) => switch (style) {
  NavBarStyle.classic => Icons.layers_outlined,
  NavBarStyle.minimal => Icons.more_horiz_rounded,
  NavBarStyle.frosted => Icons.blur_on_rounded,
  NavBarStyle.material => Icons.android_rounded,
};
