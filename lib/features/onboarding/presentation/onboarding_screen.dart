import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // FIXED: Added to access kIsWeb
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:collection/collection.dart';
import 'package:shonenx/features/discovery/domain/models/home_section.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/discovery/providers/home_layout_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_category.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/shared/models/unified_media.dart';
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
  int get _totalPages => _isMobile ? 6 : 5;

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
                      _buildDiscoveryGuidePage(theme, cs),
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
        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
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
            FilledButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://buymeacoffee.com/roshan.codespace'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const SvgIcon(
                '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 512 512">
                    <path d="M0 0h512v512H0z" fill="none" />
                    <path fill="#fd0" d="M268.4 236.5c-18.4 7.9-39.3 16.8-66.3 16.8c-11.3 0-22.6-1.6-33.5-4.6l18.7 192.1c.7 8 4.3 15.5 10.2 21s13.7 8.5 21.7 8.5c0 0 26.5 1.4 35.4 1.4c9.5 0 38.1-1.4 38.1-1.4c8.1 0 15.8-3 21.7-8.5s9.6-12.9 10.2-21l20-212.2c-9-3.1-18-5.1-28.2-5.1c-17.4-.1-31.6 6-48 13" />
                    <path fill="#0d0c22" d="m431.3 136.8l-2.8-14.2c-2.5-12.7-8.3-24.8-21.4-29.4c-4.2-1.5-9-2.1-12.2-5.2s-4.2-7.8-4.9-12.2c-1.4-8.1-2.7-16.1-4.1-24.2c-1.2-6.9-2.2-14.7-5.4-21c-4.1-8.5-12.7-13.5-21.2-16.8c-4.4-1.6-8.8-3-13.4-4.1C324.6 4.1 302.2 2 280.3.8c-26.3-1.5-52.7-1-78.9 1.3c-19.5 1.8-40.1 3.9-58.7 10.7c-6.8 2.5-13.8 5.4-18.9 10.7c-6.3 6.4-8.4 16.4-3.8 24.4c3.3 5.7 8.9 9.7 14.8 12.4q11.55 5.1 24 7.8c22.9 5.1 46.7 7.1 70.1 7.9c26 1 52 .2 77.8-2.5c6.4-.7 12.8-1.5 19.1-2.5c7.5-1.2 12.3-11 10.1-17.8c-2.6-8.2-9.8-11.3-17.8-10.1c-1.2.2-2.4.4-3.5.5l-.9.1c-2.7.3-5.4.7-8.2 1c-5.6.6-11.3 1.1-16.9 1.5c-12.7.9-25.4 1.3-38 1.3c-12.5 0-24.9-.4-37.4-1.2c-5.7-.4-11.3-.8-17-1.4c-2.6-.3-5.1-.6-7.7-.9l-2.4-.3l-.5-.1l-2.5-.4c-5.2-.8-10.3-1.7-15.4-2.8c-.5-.1-1-.4-1.3-.8s-.5-.9-.5-1.5c0-.5.2-1 .5-1.5c.3-.4.8-.7 1.3-.8h.1c4.4-.9 8.9-1.7 13.4-2.5c1.5-.2 3-.5 4.5-.7c2.8-.2 5.6-.7 8.4-1c24.3-2.5 48.7-3.4 73.1-2.6c11.8.3 23.7 1 35.5 2.2c2.5.3 5.1.5 7.6.8c1 .1 1.9.3 2.9.4l2 .3c5.7.8 11.4 1.9 17 3.1c8.4 1.8 19.1 2.4 22.8 11.6c1.2 2.9 1.7 6.1 2.4 9.2l.8 3.9v.2c2 9.2 3.9 18.4 5.9 27.6q.15 1.05 0 2.1c-.1.7-.4 1.3-.8 1.9s-.9 1-1.5 1.4s-1.3.6-1.9.7h-.1l-1.2.2l-1.2.2c-3.8.5-7.6 1-11.3 1.4c-7.5.8-14.9 1.6-22.4 2.2c-14.9 1.2-29.7 2-44.7 2.4q-11.4.3-22.8.3c-30.2 0-60.4-1.8-90.5-5.3c-3.3-.4-6.5-.8-9.8-1.2c2.5.3-1.8-.2-2.7-.4c-2.1-.3-4.1-.6-6.2-.9c-6.9-1-13.8-2.3-20.8-3.4c-8.4-1.4-16.4-.7-23.9 3.4c-6.2 3.4-11.2 8.6-14.4 14.9c-3.3 6.8-4.2 14.1-5.7 21.4s-3.7 15.1-2.9 22.5c1.9 16.1 13.1 29.1 29.2 32c15.2 2.8 30.5 5 45.8 6.9c60.2 7.4 121 8.3 181.4 2.6l14.7-1.5c1.5-.2 3.1 0 4.5.5q2.25.75 3.9 2.4t2.4 3.9c.5 1.5.7 3 .5 4.5l-1.5 14.9c-3.1 30-6.2 60.1-9.2 90.1c-3.2 31.5-6.4 63.1-9.7 94.6c-.9 8.9-1.8 17.8-2.8 26.6c-.9 8.7-1 17.8-2.7 26.4c-2.6 13.6-11.8 21.9-25.2 25c-12.3 2.8-24.9 4.3-37.5 4.4c-14 .1-27.9-.5-41.9-.5c-14.9.1-33.2-1.3-44.7-12.4c-10.1-9.8-11.5-25-12.9-38.2c-1.8-17.5-3.7-35-5.5-52.4L158 284.7l-6.6-62.9c-.1-1-.2-2.1-.3-3.1c-.8-7.5-6.1-14.8-14.5-14.5c-7.2.3-15.3 6.4-14.5 14.5l4.9 46.6l10 96.4c2.9 27.4 5.7 54.8 8.6 82.2c.6 5.2 1.1 10.5 1.6 15.8c3.1 28.7 25.1 44.1 52.2 48.5c15.8 2.5 32.1 3.1 48.1 3.3c20.6.3 41.4 1.1 61.7-2.6c30-5.5 52.6-25.6 55.8-56.7c.9-9 1.8-18 2.8-27c3.1-29.7 6.1-59.4 9.1-89.2l10-97.1l4.6-44.5c.2-2.2 1.2-4.3 2.7-5.9s3.5-2.7 5.7-3.2c8.6-1.7 16.8-4.5 22.9-11.1c10-10.1 11.9-23.7 8.5-37.4m-323.1 9.6c.1-.1-.1 1.1-.2 1.6c-.1-.8 0-1.5.2-1.6m.8 6.5c.1 0 .3.2.5.6c-.3-.4-.6-.6-.5-.6m.8 1.1c.3.5.5.8 0 0m1.7 1.3l.1.1s-.1 0-.1-.1m288.2-2c-3.1 2.9-7.7 4.3-12.3 5c-51.5 7.6-103.8 11.5-155.9 9.8c-37.3-1.3-74.2-5.4-111.1-10.6c-3.6-.5-7.5-1.2-10-3.8c-4.7-5-2.4-15.2-1.2-21.2c1.1-5.6 3.3-13 9.9-13.8c10.3-1.2 22.3 3.1 32.6 4.7c12.3 1.9 24.7 3.4 37.1 4.5c52.9 4.8 106.7 4.1 159.4-3c9.6-1.3 19.2-2.8 28.7-4.5c8.5-1.5 17.9-4.4 23 4.4c3.5 6 4 14 3.4 20.8c-.1 2.9-1.4 5.7-3.6 7.7" />
                  </svg>
                ''',
              ),
              label: const Text('Support'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFDD00),
                foregroundColor: Colors.black87,
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

  Widget _buildDiscoveryGuidePage(ThemeData theme, ColorScheme cs) {
    final discPrefs = ref.watch(discoveryPrefsProvider);
    final homeSections = ref.watch(userHomeLayoutProvider);
    final layoutNotifier = ref.read(userHomeLayoutProvider.notifier);

    final isTrackerMode = discPrefs.mode == MetadataMode.tracker;

    final hasContinue = homeSections.any(
      (s) => s.type == HomeSectionType.continueMedia,
    );
    final hasTrending = homeSections.any(
      (s) => s.trackerCategory == TrackerCategory.trending,
    );
    final hasUpcoming = homeSections.any(
      (s) => s.trackerCategory == TrackerCategory.upcoming,
    );
    final hasPopular = homeSections.any(
      (s) => s.trackerCategory == TrackerCategory.popular,
    );
    final hasTopRated = homeSections.any(
      (s) => s.trackerCategory == TrackerCategory.topRated,
    );

    bool hasLibraryStatus(TrackedStatus status) {
      return homeSections.any(
        (s) =>
            s.type == HomeSectionType.libraryStatus &&
            s.libraryStatus == status,
      );
    }

    final selectableStatuses = [
      TrackedStatus.watching,
      TrackedStatus.planning,
      TrackedStatus.completed,
      TrackedStatus.paused,
      TrackedStatus.dropped,
    ];

    return _buildPageLayout(
      title: 'Initial Home & Discovery Setup',
      description:
          'Customize your initial Home Feed layout and pick your preferred discovery engine.',
      icon: Icons.dashboard_customize_rounded,
      theme: theme,
      cs: cs,
      customWidget: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DISCOVERY ENGINE',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<MetadataMode>(
              segments: const [
                ButtonSegment(
                  value: MetadataMode.tracker,
                  label: Text('Tracker Feeds'),
                  icon: Icon(Icons.cloud_rounded),
                ),
                ButtonSegment(
                  value: MetadataMode.source,
                  label: Text('Source Mode'),
                  icon: Icon(Icons.extension_rounded),
                ),
              ],
              selected: {discPrefs.mode},
              onSelectionChanged: (val) {
                ref.read(discoveryPrefsProvider.notifier).setMode(val.first);
              },
            ),
            const SizedBox(height: 6),
            Text(
              isTrackerMode
                  ? '• Tracker Mode: Shows discovery rows (Trending, Popular, etc.) powered by AniList/MAL metadata.'
                  : '• Source Mode: Directly queries installed extension sources for discovery rows on your home feed.',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 20),

            Text(
              'CONTINUE SECTION',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  avatar: const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 16,
                  ),
                  label: const Text('Continue Watching / Reading'),
                  selected: hasContinue,
                  onSelected: (val) {
                    if (val) {
                      layoutNotifier.addSection(
                        const HomeSection(
                          id: 'continue_anime',
                          title: 'Continue Watching',
                          type: HomeSectionType.continueMedia,
                          targetMediaType: MediaType.ANIME,
                        ),
                      );
                    } else {
                      final target = homeSections.firstWhereOrNull(
                        (s) => s.type == HomeSectionType.continueMedia,
                      );
                      if (target != null) {
                        layoutNotifier.removeSection(target.id);
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'LIBRARY SECTIONS (BY STATUS)',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectableStatuses.map((status) {
                final isSelected = hasLibraryStatus(status);
                return FilterChip(
                  avatar: const Icon(
                    Icons.collections_bookmark_rounded,
                    size: 16,
                  ),
                  label: Text(status.getLabel()),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      layoutNotifier.addSection(
                        HomeSection(
                          id: 'library_${status.name}_anime',
                          title: '${status.getLabel()} Anime',
                          type: HomeSectionType.libraryStatus,
                          libraryStatus: status,
                          targetMediaType: MediaType.ANIME,
                        ),
                      );
                    } else {
                      final targets = homeSections
                          .where(
                            (s) =>
                                s.type == HomeSectionType.libraryStatus &&
                                (s.libraryStatus == status ||
                                    s.libraryStatus == null),
                          )
                          .toList();
                      for (final t in targets) {
                        layoutNotifier.removeSection(t.id);
                      }
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text(
              'TRACKER DISCOVERY CATEGORIES',
              style: theme.textTheme.labelMedium?.copyWith(
                color: isTrackerMode
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.38),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            if (!isTrackerMode)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.extension_outlined,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'In Source Mode, discovery sections are dynamically loaded from active extensions. Switch to Tracker Feeds to customize tracker categories.',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    avatar: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                    ),
                    label: const Text('Trending'),
                    selected: hasTrending,
                    onSelected: (val) {
                      if (val) {
                        layoutNotifier.addSection(
                          const HomeSection(
                            id: 'trending_anime',
                            title: 'Trending Anime',
                            type: HomeSectionType.discovery,
                            trackerCategory: TrackerCategory.trending,
                            targetMediaType: MediaType.ANIME,
                          ),
                        );
                      } else {
                        final target = homeSections.firstWhereOrNull(
                          (s) => s.trackerCategory == TrackerCategory.trending,
                        );
                        if (target != null) {
                          layoutNotifier.removeSection(target.id);
                        }
                      }
                    },
                  ),
                  FilterChip(
                    avatar: const Icon(Icons.rocket_launch_rounded, size: 16),
                    label: const Text('Upcoming'),
                    selected: hasUpcoming,
                    onSelected: (val) {
                      if (val) {
                        layoutNotifier.addSection(
                          const HomeSection(
                            id: 'upcoming_anime',
                            title: 'Upcoming Anime',
                            type: HomeSectionType.discovery,
                            trackerCategory: TrackerCategory.upcoming,
                            targetMediaType: MediaType.ANIME,
                          ),
                        );
                      } else {
                        final target = homeSections.firstWhereOrNull(
                          (s) => s.trackerCategory == TrackerCategory.upcoming,
                        );
                        if (target != null) {
                          layoutNotifier.removeSection(target.id);
                        }
                      }
                    },
                  ),
                  FilterChip(
                    avatar: const Icon(Icons.emoji_events_rounded, size: 16),
                    label: const Text('Popular'),
                    selected: hasPopular,
                    onSelected: (val) {
                      if (val) {
                        layoutNotifier.addSection(
                          const HomeSection(
                            id: 'popular_anime',
                            title: 'Popular Anime',
                            type: HomeSectionType.discovery,
                            trackerCategory: TrackerCategory.popular,
                            targetMediaType: MediaType.ANIME,
                          ),
                        );
                      } else {
                        final target = homeSections.firstWhereOrNull(
                          (s) => s.trackerCategory == TrackerCategory.popular,
                        );
                        if (target != null) {
                          layoutNotifier.removeSection(target.id);
                        }
                      }
                    },
                  ),
                  FilterChip(
                    avatar: const Icon(Icons.star_rounded, size: 16),
                    label: const Text('Top Rated'),
                    selected: hasTopRated,
                    onSelected: (val) {
                      if (val) {
                        layoutNotifier.addSection(
                          const HomeSection(
                            id: 'top_rated_anime',
                            title: 'Top Rated Anime',
                            type: HomeSectionType.discovery,
                            trackerCategory: TrackerCategory.topRated,
                            targetMediaType: MediaType.ANIME,
                          ),
                        );
                      } else {
                        final target = homeSections.firstWhereOrNull(
                          (s) => s.trackerCategory == TrackerCategory.topRated,
                        );
                        if (target != null) {
                          layoutNotifier.removeSection(target.id);
                        }
                      }
                    },
                  ),
                ],
              ),
          ],
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
