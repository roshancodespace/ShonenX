import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // FIXED: Added to access kIsWeb
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/onboarding/providers/onboarding_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/source_engine/providers/inbuilt_sources_provider.dart';
import 'package:shonenx/shared/widgets/permission_sheet.dart';
import 'package:shonenx/shared/widgets/svg_icon.dart';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:shonenx/features/extensions/presentation/widgets/runtime_setup_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // FIXED: Added kIsWeb check to prevent UnsupportedError on Web
  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  int get _totalPages => _isMobile ? 5 : 4;

  void _nextPage() {
    // FIXED: Use actual PageController position instead of lagging _currentIndex state to prevent animation jitter on rapid taps
    if (_pageController.hasClients) {
      final int targetPage =
          (_pageController.page?.round() ?? _currentIndex) + 1;

      if (targetPage < _totalPages) {
        _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      } else {
        _finishOnboarding();
      }
    }
  }

  void _finishOnboarding() {
    ref.read(onboardingProvider.notifier).completeOnboarding();
    // FIXED: Added mounted check before using context.go to prevent "deactivated widget" exceptions
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              color: cs.surface,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildWelcomePage(theme, cs),
                      _buildThemePage(theme, cs),
                      _buildTrackersPage(theme, cs),
                      _buildExtensionsPage(theme, cs),
                      if (_isMobile) _buildNotificationsPage(theme, cs),
                    ],
                  ),
                ),
                _buildBottomControls(theme, cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme, ColorScheme cs) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(_totalPages, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    height: 8,
                    width: _currentIndex == index ? 32 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              FilledButton(
                onPressed: _nextPage,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _currentIndex == _totalPages - 1 ? 'Get Started' : 'Next',
                    key: ValueKey(_currentIndex == _totalPages - 1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme, ColorScheme cs) {
    return _buildPageLayout(
      title: 'Welcome to ShonenX',
      description:
          'Your premium, ad-free gateway to discovering and tracking the best anime and manga.',
      customIcon: SvgIcon(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 344 621" width="344" height="621"><g stroke-width="2" fill="none" stroke-linecap="butt"/><path d="M 159.2 515.84Q 166.12 520.83 167.49 521.49C 172.06 523.67 180.09 528.8 184.78 531.41Q 219.92 550.94 256.51 573.47A 1.26 1.25 -65 0 1 257.04 574.94C 255.87 578.46 254.22 582.5 252.75 585.21Q 244.45 600.59 237.19 614.43A 1.33 1.33 31.71 0 1 235.24 614.89C 227.06 608.94 218.45 604.55 210.01 599.29C 193.4 588.93 176.06 579.32 155.06 567.44Q 147.18 562.98 109.83 540.2C 97.04 532.4 86.29 526.57 73.9 519.4C 67.14 515.48 59.22 509.59 54.8 506.16Q 54.63 506.03 53.92 505.17A 0.91 0.91 67.15 0 1 54.52 503.69C 60.1 503.08 64.95 502.84 71.02 501.17Q 72.33 500.81 89.35 496.55Q 101.66 493.46 119.05 486.77Q 137.28 479.76 159.61 468.85Q 169.97 463.78 194.14 448.57Q 198.69 445.7 203.85 441.87C 219.98 429.89 235.19 416.97 246.26 404Q 250.1 399.5 260.39 386.16Q 280.24 360.41 289.24 329.69C 290.71 324.68 291.56 318.79 293.35 313.14A 0.5 0.49 88.01 0 0 292.7 312.53Q 290.93 313.24 289.53 314.32Q 275.18 325.41 259.57 331.8Q 253.98 334.09 246.22 336.73Q 239.58 339 232.5 340.59Q 212.63 345.05 192.01 345.14C 163.09 345.26 137.23 342.19 111.5 345.5Q 101.69 346.76 85.79 351.67C 80.44 353.33 73.16 356.98 69.08 359.11Q 63.45 362.04 54.21 367.96C 38.89 377.77 24.21 389.7 11.41 401.64A 0.81 0.8 -24.97 0 1 10.06 401.15Q 9.21 394.22 7.25 384.01C 5.72 376.06 5.82 365.35 5.83 356.96C 5.86 341.18 8.01 324.22 11.39 308.04Q 14.69 292.21 19.24 279.7C 22.19 271.57 25.72 262.08 29.61 254.31Q 32.87 247.81 35.45 242.42Q 39.76 233.38 50.97 216.26C 53.81 211.94 56.73 208.45 61.34 202.34Q 76.35 182.46 86.83 172.09Q 96.85 162.16 116.13 146.15Q 131.98 132.99 154.15 121.9Q 162.54 117.71 167.51 115.15Q 175.65 110.95 184.9 107.93A 0.32 0.32 54.25 0 0 184.99 107.37Q 182.33 105.39 178.73 103.35C 172.05 99.55 165.01 94.17 157.69 90.11Q 146.18 83.73 135.21 77.62Q 111.34 64.32 87.3 50.43Q 84.4 48.75 81.78 46.31A 0.63 0.62 -53.26 0 1 81.67 45.54Q 85.61 38.72 86.2 37.41Q 87.74 33.95 99.41 6.47A 1.75 1.74 27.99 0 1 101.97 5.69C 114.9 14.13 130.42 22.13 141.64 29.15C 151.11 35.08 168.97 44.59 182.1 52.6Q 190.98 58.01 199.78 62.68C 210.79 68.52 220.93 75.29 231.78 81.46Q 252.65 93.31 277 108.02Q 284.11 112.32 290.07 118.21A 0.91 0.91 47.25 0 1 290.02 119.55C 287.31 121.87 284.93 122.89 280.88 123.51Q 247.19 128.65 215.87 140.86Q 212.75 142.08 201.12 147.24C 181.62 155.89 163.5 166.89 146.05 179.81C 138.72 185.24 130.26 192.64 122.61 200.38C 114.38 208.71 105.26 217.66 97.8 227.79Q 83.36 247.43 73.61 265.09Q 64.38 281.83 59.62 297.32Q 54.45 314.15 54.24 315.49Q 53.81 318.24 53.72 319.52A 0.38 0.38 77.97 0 0 54.27 319.88Q 63.41 315.06 73.47 310.47Q 81.63 306.75 89.01 305.29Q 97.8 303.54 98.69 303.33Q 104.48 301.98 108.42 301.7C 113.46 301.34 123.39 299.54 130.57 299.45Q 149.37 299.21 168.51 300.3Q 184.06 301.19 199.89 300.28Q 217.38 299.27 230.8 295.3Q 255.83 287.87 275.41 273.42Q 297.99 256.74 317.97 233.19C 320.97 229.66 323.49 227 326.37 223.13Q 327.87 221.12 331.33 217.94A 0.78 0.78 40.63 0 1 332.29 217.87Q 333.59 218.76 334.03 220.38Q 337.96 234.72 338.76 240.26C 339.88 248.14 341.36 254.57 341.61 261.32Q 342.17 276.24 341.73 293.34Q 341.55 300.31 340.36 307.22Q 340.27 307.75 338.3 321.06Q 337.3 327.8 333.27 342.67Q 330.48 353.01 326 363.61Q 316.75 385.56 308.39 399.67Q 304.94 405.5 298.25 415.44Q 293.4 422.66 286.92 430.38Q 266.06 455.23 239.53 474.52Q 238.21 475.47 228.14 482.31C 214.59 491.51 200.62 498.95 184.69 505.92Q 176.14 509.67 169.38 511.59C 165.34 512.74 162.76 514.23 159.29 515.31A 0.3 0.3 -35.58 0 0 159.2 515.84Z" fill="#ff0000"/></svg>',
        size: 110,
        color: cs.primary,
      ),
      theme: theme,
      cs: cs,
      customWidget: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://discord.gg/Fp6HRPCsqe'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const SvgIcon(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
                    <path d="M0 0h24v24H0z" fill="none" />
                    <path fill="currentColor" d="M18.59 5.89c-1.23-.57-2.54-.99-3.92-1.23c-.17.3-.37.71-.5 1.04c-1.46-.22-2.91-.22-4.34 0c-.14-.33-.34-.74-.51-1.04c-1.38.24-2.69.66-3.92 1.23c-2.48 3.74-3.15 7.39-2.82 10.98c1.65 1.23 3.24 1.97 4.81 2.46c.39-.53.73-1.1 1.03-1.69c-.57-.21-1.11-.48-1.62-.79c.14-.1.27-.21.4-.31c3.13 1.46 6.52 1.46 9.61 0c.13.11.26.21.4.31c-.51.31-1.06.57-1.62.79c.3.59.64 1.16 1.03 1.69c1.57-.49 3.17-1.23 4.81-2.46c.39-4.17-.67-7.78-2.82-10.98Zm-9.75 8.78c-.94 0-1.71-.87-1.71-1.94s.75-1.94 1.71-1.94s1.72.87 1.71 1.94c0 1.06-.75 1.94-1.71 1.94m6.31 0c-.94 0-1.71-.87-1.71-1.94s.75-1.94 1.71-1.94s1.72.87 1.71 1.94c0 1.06-.75 1.94-1.71 1.94" />
                  </svg>
                ''',
                size: 30,
                color: Colors.white,
              ),
              label: const Text('Discord'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5865F2),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://github.com/roshancodespace/shonenx'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const SvgIcon(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 16 16">
                    <path d="M0 0h16v16H0z" fill="none" />
                    <g fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5">
                      <path d="m5.75 14.25s-.5-2 .5-3c0 0-2 0-3.5-1.5s-1-4.5 0-5.5c-.5-1.5.5-2.5.5-2.5s1.5 0 2.5 1c1-.5 3.5-.5 4.5 0 1-1 2.5-1 2.5-1s1 1 .5 2.5c1 1 1.5 4 0 5.5s-3.5 1.5-3.5 1.5c1 1 .5 3 .5 3" />
                      <path d="m5.25 13.75c-1.5.5-3-.5-3.5-1" />
                    </g>
                  </svg>
                ''',
                size: 24,
                color: Colors.white,
              ),
              label: const Text('GitHub'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF24292E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePage(ThemeData theme, ColorScheme cs) {
    final themePrefs = ref.watch(themePrefsProvider);
    final notifier = ref.read(themePrefsProvider.notifier);

    return _buildPageLayout(
      title: 'Choose Your Vibe',
      description:
          'Light or Dark mode? Tailor the app\'s look to perfectly match your environment.',
      icon: Icons.palette_rounded,
      theme: theme,
      cs: cs,
      customWidget: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              label: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('System'),
              ),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Light'),
              ),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Dark'),
              ),
            ),
          ],
          selected: {themePrefs.themeMode},
          onSelectionChanged: (Set<ThemeMode> newSelection) {
            notifier.updateTheme(
              (p) => p.copyWith(themeMode: newSelection.first),
            );
          },
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackersPage(ThemeData theme, ColorScheme cs) {
    final authTokens = ref.watch(authTokensProvider).value ?? {};
    final allTrackers = ref.watch(availableTrackersProvider);

    return _buildPageLayout(
      title: 'Sync Your Progress',
      description:
          'Link your AniList or MyAnimeList account to effortlessly sync your watch history across devices.',
      icon: Icons.sync_rounded,
      theme: theme,
      cs: cs,
      customWidget: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: allTrackers.whereType<RemoteTracker>().map((tracker) {
            final isLoggedIn = authTokens.containsKey(tracker.type);
            final profileName = tracker.type.getProfile(ref)?.username;

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: isLoggedIn
                  ? Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl:
                              tracker.type.getProfile(ref)?.avatarUrl ?? '',
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person_outline),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: tracker.type.getIconWidget(
                        color: cs.onSurface,
                        size: 32,
                      ),
                    ),
              title: Text(
                tracker.type.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                isLoggedIn ? 'Logged in as $profileName' : 'Not linked',
                style: TextStyle(
                  color: isLoggedIn ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: isLoggedIn
                      ? cs.errorContainer
                      : cs.primaryContainer,
                  foregroundColor: isLoggedIn
                      ? cs.onErrorContainer
                      : cs.onPrimaryContainer,
                ),
                onPressed: () {
                  if (isLoggedIn) {
                    ref.read(authTokensProvider.notifier).logout(tracker);
                  } else {
                    ref.read(authTokensProvider.notifier).login(tracker);
                  }
                },
                icon: Icon(isLoggedIn ? Icons.logout : Icons.login, size: 18),
                label: Text(isLoggedIn ? 'Unlink' : 'Link'),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildExtensionsPage(ThemeData theme, ColorScheme cs) {
    final inbuiltCount = ref.watch(inbuiltAnimeSourcesProvider).length;
    final isRuntimeReady = bridge.AnymeXRuntimeBridge.controller.isReady.value;

    final String description;
    if (inbuiltCount > 0) {
      description =
          'ShonenX includes $inbuiltCount inbuilt source(s) out of the box. You can significantly expand your library using community-built extensions.';
    } else {
      description =
          'ShonenX relies on powerful community-built extensions to fetch content. You can install extensions later in settings to start watching.';
    }

    return _buildPageLayout(
      title: 'Sources & Extensions',
      description: description,
      icon: Icons.extension_rounded,
      theme: theme,
      cs: cs,
      customWidget: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Extension Ecosystems',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• External Runtime Engines: Connect to Mangayomi, Aniyomi, CloudStream, Kotatsu, and Sora via the extension runtime bridge.\n• Inbuilt Sources: ShonenX also comes with custom native sources directly integrated into the app.\n\nNote: ShonenX uses a minimal customized fork of AnymeXExtensionRuntimeBridge originally created by RyanYuuki.',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.maxFinite,
              child: OutlinedButton.icon(
                onPressed: () => setState(() {
                  showRuntimeSetupSheet(
                    context,
                    ref,
                    onComplete: () {
                      if (mounted) setState(() {});
                    },
                  );
                }),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  isRuntimeReady
                      ? Icons.check_circle_rounded
                      : Icons.download_rounded,
                  color: isRuntimeReady ? Colors.green : cs.primary,
                ),
                label: Text(
                  isRuntimeReady
                      ? 'Runtime Bridge Installed'
                      : 'Setup Aniyomi & CloudStream',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isRuntimeReady ? Colors.green : cs.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsPage(ThemeData theme, ColorScheme cs) {
    return _buildPageLayout(
      title: 'Stay Updated',
      description:
          'Never miss an episode. Allow notifications to receive background download progress and timely release reminders.',
      icon: Icons.notifications_active_rounded,
      theme: theme,
      cs: cs,
      customWidget: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: FilledButton.icon(
          onPressed: () async {
            final notifGranted = await PermissionSheet.show(
              context,
              permission: Permission.notification,
              title: 'Allow Notifications',
              description:
                  'ShonenX needs notification access to keep you updated.',
              rationale:
                  'This allows the app to show background download progress and notify you when new episodes of your tracked anime are released.',
            );

            bool alarmGranted = false;
            if (Platform.isAndroid && mounted) {
              alarmGranted = await PermissionSheet.show(
                context,
                permission: Permission.scheduleExactAlarm,
                title: 'Exact Alarms',
                description:
                    'Allow ShonenX to schedule precise notifications for release reminders.',
                rationale:
                    'Android restricts background tasks. Exact alarm permission ensures you receive notifications at the exact minute an episode airs, rather than hours later.',
              );
            }

            if (mounted) {
              final String msg;
              if (Platform.isAndroid) {
                if (notifGranted && alarmGranted) {
                  msg = 'Notifications & Exact Alarms Enabled!';
                } else if (notifGranted) {
                  msg = 'Notifications Enabled (Exact Alarms Denied)';
                } else if (alarmGranted) {
                  msg = 'Exact Alarms Enabled (Notifications Denied)';
                } else {
                  msg = 'Permissions Denied';
                }
              } else {
                msg = notifGranted
                    ? 'Notifications Enabled!'
                    : 'Notifications Denied';
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.notifications_rounded),
          label: const Text(
            'Grant Permission',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildPageLayout({
    required String title,
    required String description,
    IconData? icon,
    Widget? customIcon,
    required ThemeData theme,
    required ColorScheme cs,
    Widget? customWidget,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 140,
                alignment: Alignment.center,
                child: customIcon ?? Icon(icon, size: 84, color: cs.primary),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              if (customWidget != null) customWidget,
            ],
          ),
        ),
      ),
    );
  }
}
