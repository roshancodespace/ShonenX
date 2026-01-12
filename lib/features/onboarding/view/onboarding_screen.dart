import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_config.dart';
import 'package:shonenx/features/auth/view/auth_button.dart';
import 'package:shonenx/features/settings/view/anime_sources_settings_screen.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view_model/theme_notifier.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/shared/providers/update_provider.dart';
import 'package:shonenx/shared/widgets/focusable_tap.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;
  final ScrollController _themeScrollController = ScrollController();
  final ScrollController _sourceScrollController = ScrollController();
  final FocusNode _authFocusNode = FocusNode();
  final FocusNode _themeFocusNode = FocusNode();
  final FocusNode _sourceFocusNode = FocusNode();
  final FocusNode _cardStyleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resetPageFocus());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _themeScrollController.dispose();
    _sourceScrollController.dispose();
    _authFocusNode.dispose();
    _themeFocusNode.dispose();
    _sourceFocusNode.dispose();
    _cardStyleFocusNode.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final box = Hive.box('onboard');
    await box.put('is_onboarded', true);
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= _currentPage
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _resetPageFocus());
                },
                children: [
                  _buildAuthStep(context),
                  _buildThemeStep(context, ref),
                  _buildSourceStep(context, ref),
                  _buildCardModeStep(context, ref),
                  _buildUpdatesStep(context, ref),
                ],
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    _buildNavButton(
                      context,
                      label: 'Back',
                      onTap: _previousPage,
                      filled: false,
                    )
                  else
                    const SizedBox(width: 64), // Spacer

                  _buildNavButton(
                    context,
                    label: _currentPage == _totalPages - 1 ? 'Finish' : 'Next',
                    onTap: _nextPage,
                    filled: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetPageFocus() {
    if (!mounted) return;
    switch (_currentPage) {
      case 0:
        FocusScope.of(context).requestFocus(_authFocusNode);
        break;
      case 1:
        if (_themeScrollController.hasClients) {
          _themeScrollController.jumpTo(0);
        }
        FocusScope.of(context).requestFocus(_themeFocusNode);
        break;
      case 2:
        if (_sourceScrollController.hasClients) {
          _sourceScrollController.jumpTo(0);
        }
        FocusScope.of(context).requestFocus(_sourceFocusNode);
        break;
      case 3:
        FocusScope.of(context).requestFocus(_cardStyleFocusNode);
        break;
    }
  }

  Widget _buildStepHeader(BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    required bool filled,
  }) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(12);
    final background = filled
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final foreground = filled
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return FocusableTap(
      onTap: onTap,
      borderRadius: radius,
      focusBorderColor: theme.colorScheme.primary,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: filled
              ? null
              : Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Step 1: Authentication
  Widget _buildAuthStep(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildStepHeader(
            context,
            'Welcome to ShonenX',
            'Sign in to sync your progress or continue as a guest.',
          ),
          const SizedBox(height: 32),
          AccountAuthenticationSection(
            autofocusFirst: true,
            initialFocusNode: _authFocusNode,
          ),
        ],
      ),
    );
  }

  // Step 2: Theme
  Widget _buildThemeStep(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeSettingsProvider);
    final themeNotifier = ref.read(themeSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      controller: _themeScrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildStepHeader(
            context,
            'Customize Look',
            'Make the app truly yours.',
          ),
          const SizedBox(height: 20),
          SettingsSection(
            title: 'Appearance',
            titleColor: colorScheme.primary,
            children: [
              SegmentedToggleSettingsItem<int>(
                accent: colorScheme.primary,
                iconColor: colorScheme.primary,
                title: 'Theme Mode',
                description: 'Choose your preferred theme',
                focusNode: _themeFocusNode,
                autofocusSegments: true,
                selectedValue: theme.themeMode == 'light'
                    ? 1
                    : theme.themeMode == 'dark'
                        ? 2
                        : 0,
                onValueChanged: (index) {
                  final newMode = index == 0
                      ? 'system'
                      : index == 1
                          ? 'light'
                          : 'dark';
                  themeNotifier.updateSettings(
                      (prev) => prev.copyWith(themeMode: newMode));
                },
                children: const {
                  0: Icon(Iconsax.monitor),
                  1: Icon(Iconsax.sun_1),
                  2: Icon(Iconsax.moon),
                },
                labels: const {
                  0: 'System',
                  1: 'Light',
                  2: 'Dark',
                },
                icon: const Icon(Iconsax.color_swatch),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'Colors',
            titleColor: colorScheme.primary,
            children: [
              if (theme.themeMode == 'dark' ||
                  (theme.themeMode == 'system' && isCurrentlyDark))
                ToggleableSettingsItem(
                  icon: Icon(Iconsax.colorfilter, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  title: 'AMOLED Dark',
                  description: 'Use pure black for dark backgrounds',
                  value: theme.amoled,
                  onChanged: (value) {
                    themeNotifier
                        .updateSettings((prev) => prev.copyWith(amoled: value));
                  },
                ),
              NormalSettingsItem(
                icon: Icon(Iconsax.colors_square, color: colorScheme.primary),
                accent: colorScheme.primary,
                title: 'Color Scheme',
                description: _formatSchemeName(theme.flexScheme ?? ''),
                onTap: () => _showColorSchemeSheet(context, ref, themeNotifier),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Source Selection
  Widget _buildSourceStep(BuildContext context, WidgetRef ref) {
    final selectedAnimeSource = ref.watch(selectedAnimeProvider);
    final animeSources = ref.read(animeSourceRegistryProvider).keys.toList();
    final providerStatus = ref.watch(providerStatusProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildStepHeader(
            context,
            'Select Source',
            'Choose your preferred anime provider.',
          ),
          Expanded(
            child: providerStatus.when(
              data: (statusData) => ListView.builder(
                controller: _sourceScrollController,
                itemCount: animeSources.length,
                itemBuilder: (context, index) {
                  final provider = animeSources[index];
                  final statusInfo = statusData[provider];
                  final status = statusInfo?['status'] as String?;
                  final isSelected = selectedAnimeSource?.providerName ==
                      provider.toLowerCase();
                  final isFirst = index == 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SelectableSettingsItem(
                      icon: Icon(_getStatusIcon(status)),
                      iconColor: _getStatusColor(status),
                      accent: _getStatusColor(status),
                      title: provider.toUpperCase(),
                      description:
                          'Status: ${status?.toUpperCase() ?? 'UNKNOWN'}',
                      isInSelectionMode: true,
                      isSelected: isSelected,
                      autofocus: isFirst,
                      focusNode: isFirst ? _sourceFocusNode : null,
                      onTap: () {
                        ref
                            .read(selectedProviderKeyProvider.notifier)
                            .select(provider);
                      },
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Failed to load status: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Card Mode
  Widget _buildCardModeStep(BuildContext context, WidgetRef ref) {
    final cardStyles = AnimeCardMode.values.map((e) => e.name).toList();
    final currentStyle = ref.watch(uiSettingsProvider).cardStyle;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildStepHeader(
            context,
            'Card Style',
            'Choose how anime cards look.',
          ),
          const SizedBox(height: 20),

          // Enhanced Preview
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer.withOpacity(0.5),
                    colorScheme.secondaryContainer.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.eye, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE PREVIEW',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: _buildLivePreview(currentStyle),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Wrap Selector
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: cardStyles.map((style) {
              final isSelected = currentStyle == style;
              final radius = BorderRadius.circular(20);
              return FocusableTap(
                onTap: () {
                  ref.read(uiSettingsProvider.notifier).updateSettings(
                        (prev) => prev.copyWith(cardStyle: style),
                      );
                },
                autofocus: isSelected,
                focusNode: isSelected ? _cardStyleFocusNode : null,
                borderRadius: radius,
                focusBorderColor: colorScheme.primary,
                child: ChoiceChip(
                  label: Text(style.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref.read(uiSettingsProvider.notifier).updateSettings(
                            (prev) => prev.copyWith(cardStyle: style),
                          );
                    }
                  },
                  labelStyle: TextStyle(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  selectedColor: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: radius,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Step 5: Updates
  Widget _buildUpdatesStep(BuildContext context, WidgetRef ref) {
    final isAuto = ref.watch(automaticUpdatesProvider);
    final updateNotifier = ref.read(automaticUpdatesProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildStepHeader(
            context,
            'Stay Updated',
            'Keep your app up to date automatically.',
          ),
          const SizedBox(height: 32),
          ToggleableSettingsItem(
            icon: Icon(Icons.replay_outlined, color: colorScheme.primary),
            accent: colorScheme.primary,
            title: 'Automatic updates',
            description: 'Automatically check for latest release',
            value: isAuto,
            onChanged: (val) => updateNotifier.toggle(),
          ),
        ],
      ),
    );
  }

  // Helpers
  Widget _buildLivePreview(String cardStyle) {
    final mode = AnimeCardMode.values.firstWhere((e) => e.name == cardStyle,
        orElse: () => AnimeCardMode.defaults);
    final anime = UniversalMedia(
      id: '21',
      title: UniversalTitle(
        english: "One Piece",
        romaji: "One Piece",
        native: "One Piece",
      ),
      format: 'TV',
      averageScore: 88,
      status: 'RELEASING',
      genres: ['Action', 'Adventure', 'Comedy'],
      episodes: 1000,
      season: 'Fall',
      coverImage: UniversalCoverImage(
        large:
            'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg',
        medium:
            'https://cdn.noitatnemucod.net/thumbnail/300x400/100/bcd84731a3eda4f4a306250769675065.jpg',
      ),
    );
    return AnimatedAnimeCard(anime: anime, tag: 'preview', mode: mode);
  }

  void _showColorSchemeSheet(BuildContext context, WidgetRef ref,
      ThemeSettingsNotifier themeNotifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = ref.watch(themeSettingsProvider);

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 12),
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Color Scheme',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: FlexScheme.values.length,
                      itemBuilder: (context, index) {
                        final scheme = FlexScheme.values[index];
                        final isSelected = theme.flexScheme == scheme.name;

                        final radius = BorderRadius.circular(12);
                        return FocusableTap(
                          onTap: () {
                            themeNotifier.updateSettings(
                              (prev) => prev.copyWith(flexScheme: scheme.name),
                            );
                          },
                          autofocus: isSelected,
                          borderRadius: radius,
                          child: ListTile(
                            leading: _buildMinimalPreview(scheme),
                            title: Text(_formatSchemeName(scheme.name)),
                            trailing: isSelected
                                ? Icon(Iconsax.tick_circle,
                                    color:
                                        Theme.of(context).colorScheme.primary)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: radius,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMinimalPreview(FlexScheme scheme) {
    final colors = FlexThemeData.light(scheme: scheme).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          children: [
            Expanded(flex: 2, child: Container(color: colors.primary)),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(child: Container(color: colors.secondary)),
                  Expanded(child: Container(color: colors.tertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatSchemeName(String name) {
    return name
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'online':
        return Colors.green;
      case 'degraded':
        return Colors.orange;
      case 'offline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Iconsax.info_circle;
    switch (status.toLowerCase()) {
      case 'online':
        return Iconsax.health;
      case 'degraded':
        return Iconsax.warning_2;
      case 'offline':
        return Iconsax.danger;
      default:
        return Iconsax.info_circle;
    }
  }
}
