import 'dart:io';

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/utils/permissions.dart';

import 'package:shonenx/main.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/registery/anime_source_registery_provider.dart';
import 'package:shonenx/features/anime/view/widgets/card/anime_card_mode.dart';
import 'package:shonenx/features/anime/view/widgets/spotlight/spotlight_card_mode.dart';
import 'package:shonenx/features/auth/view/auth_button.dart';
import 'package:shonenx/features/settings/view/screens/anime_sources_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/home_settings_screen.dart';
import 'package:shonenx/features/settings/view/screens/ui_settings_screen.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view_model/theme_notifier.dart';
import 'package:shonenx/features/settings/view_model/ui_notifier.dart';
import 'package:shonenx/shared/providers/update_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = Platform.isAndroid ? 8 : 7;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await sharedPrefs.setBool('is_onboarded', true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(_totalPages, (index) {
                  final isActive = index <= _currentPage;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutExpo,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isActive
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
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildAuthStep(context),
                  _buildThemeStep(context, ref),
                  _buildSourceStep(context, ref),
                  _buildCardModeStep(context, ref),
                  _buildSpotlightModeStep(context, ref),
                  _buildHomeLayoutStep(context, ref),
                  if (Platform.isAndroid) _buildPermissionsStep(context, ref),
                  _buildUpdatesStep(context, ref),
                ],
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton.icon(
                      onPressed: _previousPage,
                      icon: const Icon(Iconsax.arrow_left_2),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 80),
                  FilledButton.icon(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    label: Text(
                      _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                    ),
                    icon: Icon(
                      _currentPage == _totalPages - 1
                          ? Iconsax.tick_circle
                          : Iconsax.arrow_right_3,
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

  Widget _buildHeader(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          'Welcome to\nShonenX',
          'Your ultimate anime destination. Sign in to sync your progress.',
        ),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: AccountAuthenticationSection(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeStep(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeSettingsProvider);
    final themeNotifier = ref.read(themeSettingsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            context,
            'Customize\nAppearance',
            'Make ShonenX truly yours.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SettingsSection(
                  title: 'Theme',
                  titleColor: colorScheme.primary,
                  children: [
                    SegmentedToggleSettingsItem<dynamic>(
                      accent: colorScheme.primary,
                      iconColor: colorScheme.primary,
                      title: 'Mode',
                      description: 'Select base theme',
                      selectedValue: theme.themeMode == 'light'
                          ? 1
                          : theme.themeMode == 'dark'
                          ? 2
                          : 0,
                      onValueChanged: (index) {
                        final mode = index == 0
                            ? 'system'
                            : index == 1
                            ? 'light'
                            : 'dark';
                        themeNotifier.updateSettings(
                          (p) => p.copyWith(themeMode: mode),
                        );
                      },
                      children: const {
                        0: Icon(Iconsax.monitor),
                        1: Icon(Iconsax.sun_1),
                        2: Icon(Iconsax.moon),
                      },
                      labels: const {0: 'System', 1: 'Light', 2: 'Dark'},
                      icon: const Icon(Iconsax.color_swatch),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SettingsSection(
                  title: 'Palette',
                  titleColor: colorScheme.primary,
                  children: [
                    if (theme.themeMode == 'dark' ||
                        (theme.themeMode == 'system' &&
                            Theme.of(context).brightness == Brightness.dark))
                      ToggleableSettingsItem(
                        icon: Icon(
                          Iconsax.colorfilter,
                          color: colorScheme.primary,
                        ),
                        accent: colorScheme.primary,
                        title: 'True Black',
                        description: 'OLED optimization',
                        value: theme.amoled,
                        onChanged: (v) => themeNotifier.updateSettings(
                          (p) => p.copyWith(amoled: v),
                        ),
                      ),
                    NormalSettingsItem(
                      icon: Icon(
                        Iconsax.colors_square,
                        color: colorScheme.primary,
                      ),
                      accent: colorScheme.primary,
                      title: 'Color Scheme',
                      description: _formatSchemeName(theme.flexScheme ?? ''),
                      onTap: () =>
                          _showColorSchemeSheet(context, ref, themeNotifier),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceStep(BuildContext context, WidgetRef ref) {
    final selectedAnimeSource = ref.watch(selectedAnimeProvider);
    final animeSources = ref.read(animeSourceRegistryProvider).keys.toList();
    final providerStatus = ref.watch(providerStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          'Select\nSource',
          'Choose your content provider.',
        ),
        Expanded(
          child: providerStatus.when(
            data: (statusData) => ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: animeSources.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final provider = animeSources[index];
                final status = statusData[provider]?['status'] as String?;
                final isSelected =
                    selectedAnimeSource?.providerName == provider.toLowerCase();

                return SelectableSettingsItem(
                  icon: Icon(_getStatusIcon(status)),
                  iconColor: _getStatusColor(status),
                  accent: _getStatusColor(status),
                  title: provider.toUpperCase(),
                  description: status?.toUpperCase() ?? 'UNKNOWN',
                  isInSelectionMode: true,
                  isSelected: isSelected,
                  onTap: () => ref
                      .read(selectedProviderKeyProvider.notifier)
                      .select(provider),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }

  Widget _buildCardModeStep(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, 'Card\nStyle', 'Choose the look of anime cards.'),
        Expanded(
          child: StyleSelector(
            isSpotlight: false,
            initialStyle: ref.read(
              uiSettingsProvider.select((s) => s.cardStyle.name),
            ),
            onChanged: (val) {
              ref
                  .read(uiSettingsProvider.notifier)
                  .updateSettings(
                    (s) =>
                        s.copyWith(cardStyle: AnimeCardMode.values.byName(val)),
                  );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpotlightModeStep(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          'Spotlight\nStyle',
          'Choose the featured banner style.',
        ),
        Expanded(
          child: StyleSelector(
            isSpotlight: true,
            initialStyle: ref.read(
              uiSettingsProvider.select((s) => s.spotlightCardStyle.name),
            ),
            onChanged: (val) {
              ref
                  .read(uiSettingsProvider.notifier)
                  .updateSettings(
                    (s) => s.copyWith(
                      spotlightCardStyle: SpotlightCardMode.values.byName(val),
                    ),
                  );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHomeLayoutStep(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          'Home\nLayout',
          'Use ShonenX with your own preferred home layout.',
        ),
        Expanded(child: HomeSettingsScreen(noAppBar: true)),
      ],
    );
  }

  Widget _buildUpdatesStep(BuildContext context, WidgetRef ref) {
    final isAuto = ref.watch(automaticUpdatesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          'Final\nTouches',
          'Keep ShonenX fresh and up to date.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ToggleableSettingsItem(
            icon: Icon(Iconsax.refresh, color: colorScheme.primary),
            accent: colorScheme.primary,
            title: 'Automatic Updates',
            description: 'Check for new features on startup',
            value: isAuto,
            onChanged: (val) =>
                ref.read(automaticUpdatesProvider.notifier).toggle(),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionsStep(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          context,
          'Grant\nPermissions',
          'Allow access to storage to download anime and support extensions.',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ToggleableSettingsItem(
            icon: Icon(Iconsax.folder_open, color: colorScheme.primary),
            accent: colorScheme.primary,
            title: 'Storage Access',
            description:
                'Allow access to storage to download anime and support extensions.',
            value: Permissions.storage,
            onChanged: (val) async {
              if (val == false) return;
              await Permissions.requestStoragePermission();
              setState(() {});
            },
          ),
        ),
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 16),
        //   child: ToggleableSettingsItem(
        //     icon: Icon(Iconsax.gallery, color: colorScheme.primary),
        //     accent: colorScheme.primary,
        //     title: 'Photos & Videos',
        //     description:
        //         'Allow access to photos and videos for media management.',
        //     value: Permissions.photos && Permissions.videos,
        //     onChanged: (val) async {
        //       if (val == false) return;
        //       await Permissions.requestMediaPermissions();
        //       setState(() {});
        //     },
        //   ),
        // ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ToggleableSettingsItem(
            icon: Icon(Iconsax.notification, color: colorScheme.primary),
            accent: colorScheme.primary,
            title: 'Notification Access',
            description:
                'Allow access to notifications to get notified about new anime news.',
            value: Permissions.notification,
            onChanged: (val) async {
              if (val == false) return;
              await Permissions.requestNotificationPermission();
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  void _showColorSchemeSheet(
    BuildContext context,
    WidgetRef ref,
    ThemeSettingsNotifier themeNotifier,
  ) {
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
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: FlexScheme.values.length,
                      itemBuilder: (context, index) {
                        final scheme = FlexScheme.values[index];
                        final isSelected = theme.flexScheme == scheme.name;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => themeNotifier.updateSettings(
                              (p) => p.copyWith(flexScheme: scheme.name),
                            ),
                            leading: _buildMinimalPreview(scheme),
                            title: Text(_formatSchemeName(scheme.name)),
                            trailing: isSelected
                                ? Icon(
                                    Iconsax.tick_circle,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            tileColor: isSelected
                                ? Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer
                                : null,
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
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          children: [
            Expanded(flex: 2, child: Container(color: colors.primary)),
            Expanded(
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

  String _formatSchemeName(String name) => name
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
      .join(' ');

  Color _getStatusColor(String? status) => status?.toLowerCase() == 'online'
      ? Colors.green
      : status?.toLowerCase() == 'offline'
      ? Colors.red
      : Colors.orange;

  IconData _getStatusIcon(String? status) => status?.toLowerCase() == 'online'
      ? Iconsax.health
      : status?.toLowerCase() == 'offline'
      ? Iconsax.danger
      : Iconsax.warning_2;
}
