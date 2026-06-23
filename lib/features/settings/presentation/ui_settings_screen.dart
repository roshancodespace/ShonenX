import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/providers/ui_prefs_provider.dart';
import 'package:shonenx/core/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_watching_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/continue/continue_reading_card.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_tiles.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/features/history/domain/models/watch_history_entry.dart';
import 'package:shonenx/features/history/domain/models/read_history_entry.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  static final _previewHistoryEntry = WatchHistoryEntry()
    ..animeId = '1'
    ..animeTitle = 'One Piece'
    ..episodeNumber = 7
    ..episodeTitle = 'Orewa Kaizoku Ou Ni Naru!'
    ..positionInMilliseconds = 720000
    ..durationInMilliseconds = 1200000
    ..thumbnailUrl =
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

  static final _previewReadHistoryEntry = ReadHistoryEntry()
    ..mangaId = '2'
    ..mangaTitle = 'One Piece'
    ..chapterNumber = 236
    ..chapterTitle = 'Orewa Kaizoku Ou Ni Naru!'
    ..positionPage = 14
    ..totalPages = 20
    ..cover =
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final prefs = ref.watch(uiPrefsProvider);
    final notifier = ref.read(uiPrefsProvider.notifier);

    final themePrefs = ref.watch(themePrefsProvider);
    final themeNotifier = ref.read(themePrefsProvider.notifier);

    return AppScaffold(
      title: 'UI',
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          SettingsSection(
            title: 'Appearance',
            children: [
              SettingsActionTile(
                icon: Icons.tune_rounded,
                title: 'Global UI Customization',
                subtitle: 'Adjust corner radius, widget scale, and text scale',
                onTap: () => _showAppearanceSheet(
                  context,
                  ref,
                  themeNotifier,
                  themePrefs,
                  theme,
                ),
              ),
            ],
          ),

          const Divider(height: 1, indent: 10, endIndent: 10),

          SettingsSection(
            title: 'Media Cards',
            children: [
              SettingsActionTile(
                icon: Icons.style_outlined,
                title: 'Card Style',
                subtitle: 'Style of media cards on Home & Discover',
                trailing: _Chip(label: prefs.cardStyle.displayName, cs: cs),
                onTap: () => _showCardStyleSheet(context, ref, notifier, theme),
              ),
              SettingsActionTile(
                icon: Icons.play_circle_outline_rounded,
                title: 'Continue Watching Style',
                subtitle: 'Style of cards on the Continue Watching row',
                trailing: _Chip(
                  label: prefs.continueWatchingStyle.displayName,
                  cs: cs,
                ),
                onTap: () =>
                    _showContinueWatchingSheet(context, ref, notifier, theme),
              ),
              SettingsActionTile(
                icon: Icons.menu_book_rounded,
                title: 'Continue Reading Style',
                subtitle: 'Style of cards on the Continue Reading row',
                trailing: _Chip(
                  label: prefs.continueReadingStyle.displayName,
                  cs: cs,
                ),
                onTap: () =>
                    _showContinueReadingSheet(context, ref, notifier, theme),
              ),
            ],
          ),

          const Divider(height: 1, indent: 10, endIndent: 10),

          SettingsSection(
            title: 'Episodes',
            children: [
              SettingsActionTile(
                icon: Icons.view_list_rounded,
                title: 'Default Episode View',
                subtitle: 'Remembered view mode for episode lists',
                trailing: _Chip(
                  label: _episodeModeLabel(prefs.episodeViewMode),
                  cs: cs,
                ),
                onTap: () =>
                    _showEpisodeModeSheet(context, ref, notifier, theme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAppearanceSheet(
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
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                subtitle: 'Scale the size of media cards',
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
          );
        },
      ),
    );
  }

  void _showCardStyleSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Card Style',
      child: Consumer(
        builder: (_, r, _) {
          final current = r.watch(uiPrefsProvider.select((s) => s.cardStyle));

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: SizedBox(
                  width: current.layout.width,
                  height: current.layout.height,
                  child: MediaCard(
                    title: 'Demon Slayer: Kimetsu No Yaiba',
                    tag: 'ui-card-preview',
                    format: 'TV',
                    imageUrl:
                        'https://m.media-amazon.com/images/M/MV5BM2IyN2E0NjctYWU2ZC00ZDc4LThiOTQtODAyOGNkZWM0M2E1XkEyXkFqcGc@._V1_.jpg',
                    onTap: () {},
                    style: current,
                  ),
                ),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 4),

              ...MediaCardStyle.values.map(
                (style) => _SelectionTile(
                  selected: current == style,
                  icon: Icons.style_outlined,
                  title: style.displayName,
                  subtitle: _cardStyleDesc(style),
                  selectedColor: cs.primary,
                  onTap: () => notifier.updateCardStyle(style),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContinueWatchingSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Continue Watching Style',
      child: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.continueWatchingStyle),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ContinueWatchingItem(
                  style: current,
                  progress: 0.72,
                  entry: _previewHistoryEntry,
                ),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 4),

              ...ContinueWatchingStyle.values.map(
                (style) => _SelectionTile(
                  selected: current == style,
                  icon: _cwStyleIcon(style),
                  title: style.displayName,
                  subtitle: _cwStyleDesc(style),
                  selectedColor: cs.primary,
                  onTap: () => notifier.updateContinueWatchingStyle(style),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContinueReadingSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Continue Reading Style',
      child: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.continueReadingStyle),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: ContinueReadingItem(
                  style: current,
                  progress: 0.7,
                  entry: _previewReadHistoryEntry,
                ),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 4),

              ...ContinueReadingStyle.values.map(
                (style) => _SelectionTile(
                  selected: current == style,
                  icon: _crStyleIcon(style),
                  title: style.displayName,
                  subtitle: _crStyleDesc(style),
                  selectedColor: cs.primary,
                  onTap: () => notifier.updateContinueReadingStyle(style),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEpisodeModeSheet(
    BuildContext context,
    WidgetRef ref,
    UiPrefsNotifier notifier,
    ThemeData theme,
  ) {
    final cs = theme.colorScheme;

    AppBottomSheet.show(
      context: context,
      title: 'Episode View Mode',
      child: Consumer(
        builder: (_, r, _) {
          final current = r.watch(
            uiPrefsProvider.select((s) => s.episodeViewMode),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _EpisodeViewModePreview(mode: current),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 4),

              ...EpisodeViewMode.values.map(
                (mode) => _SelectionTile(
                  selected: current == mode,
                  icon: _episodeModeIcon(mode),
                  title: _episodeModeLabel(mode),
                  subtitle: _episodeModeDesc(mode),
                  selectedColor: cs.primary,
                  onTap: () => notifier.updateEpisodeViewMode(mode),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _cardStyleDesc(MediaCardStyle s) => switch (s) {
    MediaCardStyle.classic => 'Standard poster with title below',
    MediaCardStyle.minimal => 'Compact with subtle overlay',
    MediaCardStyle.expressive => 'Tall card with bold typography',
    MediaCardStyle.material => 'Material You elevated card',
    MediaCardStyle.liquidGlass => 'Frosted glass finish',
  };

  static String _cwStyleDesc(ContinueWatchingStyle s) => switch (s) {
    ContinueWatchingStyle.classic => 'Square cards with progress bar',
    ContinueWatchingStyle.wideBanner => 'Wide horizontal banner cards',
  };

  static IconData _cwStyleIcon(ContinueWatchingStyle s) => switch (s) {
    ContinueWatchingStyle.classic => Icons.view_module_outlined,
    ContinueWatchingStyle.wideBanner => Icons.view_day_outlined,
  };

  static String _crStyleDesc(ContinueReadingStyle s) => switch (s) {
    ContinueReadingStyle.classic => 'Vertical manga cover cards',
    ContinueReadingStyle.wideBanner => 'Wide horizontal banner cards',
  };

  static IconData _crStyleIcon(ContinueReadingStyle s) => switch (s) {
    ContinueReadingStyle.classic => Icons.view_module_outlined,
    ContinueReadingStyle.wideBanner => Icons.view_day_outlined,
  };

  static String _episodeModeLabel(EpisodeViewMode m) => switch (m) {
    EpisodeViewMode.classic => 'Classic',
    EpisodeViewMode.grid => 'Grid',
    EpisodeViewMode.box => 'Box',
  };

  static String _episodeModeDesc(EpisodeViewMode m) => switch (m) {
    EpisodeViewMode.classic => 'Detailed list with episode art and title',
    EpisodeViewMode.grid => 'Thumbnail grid with episode numbers',
    EpisodeViewMode.box => 'Compact numbered boxes — great for long anime',
  };

  static IconData _episodeModeIcon(EpisodeViewMode m) => switch (m) {
    EpisodeViewMode.classic => Icons.view_agenda_outlined,
    EpisodeViewMode.grid => Icons.grid_view_outlined,
    EpisodeViewMode.box => Icons.tag_outlined,
  };
}

class _SelectionTile extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color selectedColor;
  final VoidCallback onTap;

  const _SelectionTile({
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

    return ListTile(
      leading: Icon(
        icon,
        color: selected ? selectedColor : cs.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      trailing: selected
          ? Icon(Icons.check_rounded, color: selectedColor)
          : null,
      onTap: onTap,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final ColorScheme cs;

  const _Chip({required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
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

    return AnimatedSize(
      duration: Durations.short4,
      child: switch (mode) {
        EpisodeViewMode.classic => _PreviewContainer(
          key: const ValueKey('classic'),
          child: Column(
            children: List.generate(
              2,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: i == 1 ? 0 : 10),
                child: Container(
                  height: 76,
                  decoration: BoxDecoration(
                    color: i == 0
                        ? cs.primaryContainer.withValues(alpha: 0.28)
                        : cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        margin: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: i == 0
                              ? cs.primary
                              : cs.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        i == 0
                            ? Icons.play_circle_fill_rounded
                            : Icons.check_circle_rounded,
                        size: 28,
                        color: i == 0
                            ? cs.primary
                            : cs.onSurfaceVariant.withValues(alpha: 0.45),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SkeletonBar(
                                width: 78,
                                color: i == 0
                                    ? cs.primary
                                    : cs.surfaceContainerHighest,
                              ),
                              const Spacer(),
                              _SkeletonBar(
                                height: 14,
                                color: cs.surfaceContainerHighest,
                              ),
                              const SizedBox(height: 8),
                              _SkeletonBar(
                                width: 120,
                                height: 12,
                                color: cs.surfaceContainerHighest.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i == 0)
                        Container(
                          margin: const EdgeInsets.only(right: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'NOW',
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        EpisodeViewMode.grid => _PreviewContainer(
          key: const ValueKey('grid'),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemBuilder: (_, i) {
              final current = i == 1;
              final watched = i == 0;

              return Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (current)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.play_arrow_rounded,
                            size: 12,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),

                    if (watched)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),

                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Text(
                        'Ep ${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        EpisodeViewMode.box => _PreviewContainer(
          key: const ValueKey('box'),
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(18, (i) {
              final current = i == 4;
              final watched = i < 4;

              return Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: current
                      ? cs.primary
                      : watched
                      ? cs.surfaceContainerHighest
                      : cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: current
                        ? cs.onPrimary
                        : watched
                        ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                        : cs.onSurface,
                  ),
                ),
              );
            }),
          ),
        ),
      },
    );
  }
}

class _PreviewContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _PreviewContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  final double? width;
  final double height;
  final Color color;

  const _SkeletonBar({this.width, this.height = 10, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
