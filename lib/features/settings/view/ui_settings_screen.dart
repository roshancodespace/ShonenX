import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/core/models/anilist/media.dart'
    as anime_media;
import 'package:uuid/uuid.dart';

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
                  title: 'Content Display',
                  titleColor: colorScheme.primary,
                  children: [
                    SettingsItem(
                      icon: Icon(Iconsax.card, color: colorScheme.primary),
                      accent: colorScheme.primary,
                      title: 'Card Style',
                      description: 'Customize card appearance',
                      onTap: () => _showCardStyleDialog(context, ref),
                    ),
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardStyleDialog(BuildContext context, WidgetRef ref) async {
    final cardStyles = AnimeCardMode.values.map((e) => e.name).toList();
    String tempStyle = ref.read(uiSettingsProvider).cardStyle;
    final colorScheme = Theme.of(context).colorScheme;

    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              actionsPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SettingsItem(
                    icon: Icon(Iconsax.card, color: colorScheme.primary),
                    accent: colorScheme.primary,
                    title: 'Card Style',
                    description: 'Customize card appearance',
                    type: SettingsItemType.dropdown,
                    dropdownValue: tempStyle,
                    dropdownItems: cardStyles,
                    onDropdownChanged: (value) => setDialogState(() {
                      tempStyle = value!;
                    }),
                  ),
                  Container(
                      color: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      width: double.infinity,
                      child: Center(
                        child: _buildLivePreview(tempStyle),
                      )),
                ],
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
                  onPressed: () => {
                    ref.read(uiSettingsProvider.notifier).updateSettings(
                          (prev) => prev.copyWith(cardStyle: tempStyle),
                        ),
                    Navigator.pop(dialogContext)
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

  Widget _buildLivePreview(String cardStyle) {
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle);
    final anime = anime_media.Media(
      id: 1,
      coverImage: anime_media.CoverImage(
        large:
            'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg',
        medium:
            'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg',
      ),
      title: anime_media.Title(
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
    final tag = const Uuid().v4();
    return AnimatedAnimeCard(anime: anime, tag: tag, mode: mode);
  }
}
