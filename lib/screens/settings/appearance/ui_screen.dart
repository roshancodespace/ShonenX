import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/api/models/anilist/anilist_media_list.dart'
    as anime_media;
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';
import 'package:shonenx/widgets/anime/card/anime_card.dart';
import 'package:shonenx/widgets/ui/shonenx_settings.dart';

// Riverpod provider for UI settings
final uiSettingsProvider =
    StateNotifierProvider<UISettingsNotifier, UISettingsState>((ref) {
  return UISettingsNotifier();
});

class UISettingsState {
  final UISettingsModel uiSettings;
  final bool isLoading;

  UISettingsState({required this.uiSettings, this.isLoading = false});

  UISettingsState copyWith({UISettingsModel? uiSettings, bool? isLoading}) {
    return UISettingsState(
      uiSettings: uiSettings ?? this.uiSettings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UISettingsNotifier extends StateNotifier<UISettingsState> {
  SettingsBox? _settingsBox;

  UISettingsNotifier() : super(UISettingsState(uiSettings: UISettingsModel()));

  Future<void> initializeSettings() async {
    // Public method
    state = state.copyWith(isLoading: true);
    _settingsBox = SettingsBox();
    await _settingsBox?.init();
    _loadSettings();
    state = state.copyWith(isLoading: false);
  }

  void _loadSettings() {
    final settings = _settingsBox?.getSettings();
    if (settings != null) {
      state =
          state.copyWith(uiSettings: settings.uiSettings ?? UISettingsModel());
    }
  }

  void updateUISettings(UISettingsModel settings) {
    state = state.copyWith(uiSettings: settings);
    _settingsBox?.updateUISettings(settings);
  }
}

class UISettingsScreen extends ConsumerWidget {
  const UISettingsScreen({super.key});

  static final anime_media.Media animeMedia = anime_media.Media(
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(uiSettingsProvider);

    if (settingsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildContent(context, ref);
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    // final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate([
              SettingsSection(
                compact: true,
                context: context,
                title: 'Layout',
                items: [
                  SettingsItem(
                    compact: true,
                    onTap: () => _showDefaultTabDialog(context, ref),
                    icon: Iconsax.home,
                    title: 'Default Tab',
                    description: 'Set the tab shown on app launch',
                  ),
                  SettingsItem(
                    compact: true,
                    onTap: () {},
                    icon: Iconsax.grid_3,
                    title: 'Layout Style',
                    description: 'Choose between grid or list view',
                    disabled: true,
                  ),
                ],
              ),
              SettingsSection(
                compact: true,
                context: context,
                title: 'Content Display',
                items: [
                  SettingsItem(
                    compact: true,
                    icon: Iconsax.card,
                    title: 'Card Style',
                    description: 'Customize card appearance',
                    onTap: () => _showCardStyleDialog(context, ref),
                  ),
                ],
              ),
              SettingsSection(
                compact: true,
                context: context,
                title: 'Immersive Mode',
                items: [
                  SettingsSwitch(
                    compact: true,
                    icon: Icons.fullscreen,
                    title: 'Enable Immersive Mode',
                    description:
                        'Toggle immersive mode for a distraction-free experience',
                    value:
                        ref.watch(uiSettingsProvider).uiSettings.immersiveMode,
                    onChanged: (value) {
                      final currentSettings =
                          ref.read(uiSettingsProvider).uiSettings;
                      ref.read(uiSettingsProvider.notifier).updateUISettings(
                            currentSettings.copyWith(
                              immersiveMode: value,
                            ),
                          );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ]),
          ),
        ],
      ),
    );
  }

  void _showDefaultTabDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.read(uiSettingsProvider);
    final List<String> tabs = ["Home", "Watchlist", "Browse"];

    ValueNotifier<String> selectedTab = ValueNotifier(
        tabs.contains(settings.uiSettings.defaultTab)
            ? settings.uiSettings.defaultTab
            : 'Home');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Default tab'),
          content: ValueListenableBuilder<String>(
            valueListenable: selectedTab,
            builder: (context, value, child) {
              return DropdownButtonFormField<String>(
                value: value,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                ),
                dropdownColor: colorScheme.surfaceContainerHighest,
                icon: Icon(Iconsax.arrow_down_1, color: colorScheme.onSurface),
                style: TextStyle(color: colorScheme.onSurface),
                onChanged: (newValue) => selectedTab.value = newValue!,
                items: tabs.map((tab) {
                  return DropdownMenuItem<String>(
                    value: tab,
                    child: Text(
                      tab,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () {
                ref.read(uiSettingsProvider.notifier).updateUISettings(
                      settings.uiSettings
                          .copyWith(defaultTab: selectedTab.value),
                    );
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  void _showCardStyleDialog(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.read(uiSettingsProvider);
    final List<String> cardStyles = [
      'Card',
      'Compact',
      'Poster',
      'Glass',
      'Neon',
      'Minimal',
      'Cinematic',
    ];
    ValueNotifier<String> selectedStyle = ValueNotifier(
      cardStyles.contains(settings.uiSettings.cardStyle)
          ? settings.uiSettings.cardStyle
          : 'Card',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Card Style'),
          content: ValueListenableBuilder<String>(
            valueListenable: selectedStyle,
            builder: (context, value, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: value,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                    ),
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    icon: Icon(Iconsax.arrow_down_1,
                        color: colorScheme.onSurface),
                    style: TextStyle(color: colorScheme.onSurface),
                    onChanged: (newValue) => selectedStyle.value = newValue!,
                    items: cardStyles.map((style) {
                      return DropdownMenuItem<String>(
                        value: style,
                        child: Text(
                          style,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildCardPreview(context, value),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: TextStyle(color: colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () {
                ref.read(uiSettingsProvider.notifier).updateUISettings(
                      settings.uiSettings
                          .copyWith(cardStyle: selectedStyle.value),
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    elevation: 0,
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.transparent,
                    duration: const Duration(seconds: 5),
                    content: AwesomeSnackbarContent(
                      title: 'Restart required',
                      message: 'You need to restart to avoid UI glitches once',
                      contentType: ContentType.warning,
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardPreview(BuildContext context, String style) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedAnimeCard(
            anime: animeMedia,
            tag: 'preview_$style',
            mode: style,
          ),
        ],
      ),
    );
  }
}
