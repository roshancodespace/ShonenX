import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_spotlight_card.dart';
import 'package:shonenx/features/home/view/widgets/spotlight/spotlight_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';

class UiSettingsScreen extends ConsumerWidget {
  const UiSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
            onPressed: () => context.pop(),
            icon: const Icon(Iconsax.arrow_left_2)),
        title: const Text('UI Settings'),
        forceMaterialTransparency: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSection(
                title: 'UI Scale',
                titleColor: colorScheme.primary,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final scale = ref.watch(
                          uiSettingsProvider.select((ui) => ui.uiScale));
                      return _buildUiScalePreview(context, scale);
                    },
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final scale = ref.watch(
                          uiSettingsProvider.select((ui) => ui.uiScale));
                      return SliderSettingsItem(
                        icon: Icon(Iconsax.maximize_1,
                            color: colorScheme.primary),
                        accent: colorScheme.primary,
                        title: 'UI Scale',
                        description:
                            'Adjust overall UI size (auto scales on 4K displays)',
                        value: scale,
                        min: 0.5,
                        max: 1.0,
                        suffix: 'x',
                        onChanged: (value) {
                          final snapped = (value * 10).round() / 10;
                          ref.read(uiSettingsProvider.notifier).updateSettings(
                                (s) => s.copyWith(uiScale: snapped),
                              );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSection(
                  title: 'Content Display',
                  titleColor: colorScheme.primary,
                  children: [
                    NormalSettingsItem(
                      icon: Icon(Iconsax.card, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Card Style',
                      description: 'Customize card appearance',
                      onTap: () => _showCardStyleDialog(context, ref),
                    ),
                    NormalSettingsItem(
                      icon: Icon(Iconsax.card, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Spotlight Card Style',
                      description: 'Customize Spotlight card appearance',
                      onTap: () => _showCardStyleDialog(context, ref,
                          isSpotlightCard: true),
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final currentMode = ref.watch(uiSettingsProvider
                            .select((ui) => ui.episodeViewMode));
                        return DropdownSettingsItem(
                          icon: Icon(Iconsax.task, color: colorScheme.primary),
                          accent: colorScheme.primary,
                          title: 'Episode View Mode',
                          description: 'Choose how episodes are displayed',
                          value: currentMode,
                          items: const [
                            DropdownMenuItem(
                                value: 'list', child: Text('List')),
                            DropdownMenuItem(
                                value: 'compact', child: Text('Compact')),
                            DropdownMenuItem(
                                value: 'grid', child: Text('Grid')),
                            DropdownMenuItem(
                                value: 'block', child: Text('Block')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              ref
                                  .read(uiSettingsProvider.notifier)
                                  .updateSettings(
                                    (s) => s.copyWith(episodeViewMode: value),
                                  );
                            }
                          },
                        );
                      },
                    ),
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardStyleDialog(BuildContext context, WidgetRef ref,
      {bool isSpotlightCard = false}) async {
    final cardStyles = isSpotlightCard
        ? SpotlightCardMode.values.map((e) => e.name).toList()
        : AnimeCardMode.values.map((e) => e.name).toList();
    String tempStyle =
        ref.read(uiSettingsProvider.select((ui) => ui.cardStyle));
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownSettingsItem(
                      icon: Icon(Iconsax.card, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title:
                          '${isSpotlightCard ? 'Spotlight' : 'Normal'} Card Style',
                      description:
                          'Customize ${isSpotlightCard ? 'Spotlight' : 'Normal'} card appearance',
                      value: tempStyle,
                      items: cardStyles
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) => setDialogState(() {
                        tempStyle = value!;
                      }),
                    ),
                    Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primaryContainer,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        width: double.infinity,
                        child: Center(
                          child: _buildLivePreview(tempStyle,
                              isSpotlightCard: isSpotlightCard),
                        )),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (isSpotlightCard) {
                      ref.read(uiSettingsProvider.notifier).updateSettings(
                            (prev) =>
                                prev.copyWith(spotlightCardStyle: tempStyle),
                          );
                    } else {
                      ref.read(uiSettingsProvider.notifier).updateSettings(
                            (prev) => prev.copyWith(cardStyle: tempStyle),
                          );
                    }
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLivePreview(String cardStyle, {bool isSpotlightCard = false}) {
    final mode = isSpotlightCard
        ? SpotlightCardMode.values.firstWhere((e) => e.name == cardStyle)
        : AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);
    final anime = UniversalMedia(
      id: '1',
      coverImage: UniversalCoverImage(
        large:
            'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg',
        medium:
            'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg',
      ),
      title: UniversalTitle(
        english: "One Piece",
        romaji: "One Piece",
        native: "One Piece",
      ),
      format: 'TV',
      averageScore: 69,
      status: 'Completed',
      genres: ['Action', 'Adventure', 'Comedy'],
      episodes: 220,
      season: 'Fall',
    );
    if (isSpotlightCard) {
      return AnimeSpotlightCard(
          anime: anime, heroTag: 'abcd', mode: mode as SpotlightCardMode);
    }
    return AnimatedAnimeCard(
        anime: anime, tag: 'abcd', mode: mode as AnimeCardMode);
  }

  Widget _buildUiScalePreview(BuildContext context, double scale) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(16);
    final previewScale = scale.clamp(0.5, 1.0);

    return Container(
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.6),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Center(
          child: Transform.scale(
            scale: previewScale,
            alignment: Alignment.center,
            child: _buildUiScalePreviewContent(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildUiScalePreviewContent(ThemeData theme) {
    return Container(
      width: 240,
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 120,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 160,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 110,
                      decoration: BoxDecoration(
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Play',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Info',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
