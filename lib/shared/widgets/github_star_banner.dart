import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shonenx/shared/providers/storage_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const String _kGithubStarDismissedKey =
    'github_star_recovery_banner_dismissed_v1';
const String kShonenXRepoUrl = 'https://github.com/roshancodespace/shonenx';
const String kShonenXDiscordUrl = 'https://discord.gg/Fp6HRPCsqe';

final githubStarBannerDismissedProvider =
    NotifierProvider<GithubStarBannerDismissedNotifier, bool>(
      GithubStarBannerDismissedNotifier.new,
    );

class GithubStarBannerDismissedNotifier extends Notifier<bool> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  bool build() {
    return _prefs.getBool(_kGithubStarDismissedKey) ?? false;
  }

  void dismiss() {
    _prefs.setBool(_kGithubStarDismissedKey, true);
    state = true;
  }

  void reset() {
    _prefs.setBool(_kGithubStarDismissedKey, false);
    state = false;
  }
}

class _StarColors {
  final Color container;
  final Color accent;
  final Color onAccent;
  final Color accentSoft;

  const _StarColors._(
    this.container,
    this.accent,
    this.onAccent,
    this.accentSoft,
  );

  factory _StarColors.of(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _StarColors._(
      Color.alphaBlend(
        Colors.amber.withValues(alpha: isDark ? 0.16 : 0.24),
        cs.surfaceContainerLow,
      ),
      isDark ? Colors.amber.shade300 : Colors.amber.shade800,
      isDark ? Colors.black87 : Colors.white,
      Colors.amber.withValues(alpha: isDark ? 0.14 : 0.22),
    );
  }
}

WidgetStateProperty<OutlinedBorder> _morphShape({
  double rest = 28,
  double pressed = 12,
}) {
  return WidgetStateProperty.resolveWith((states) {
    final r = states.contains(WidgetState.pressed) ? pressed : rest;
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
  });
}

class _CookiePainter extends CustomPainter {
  final Color color;
  static const int _scallops = 9;
  const _CookiePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.width / 2 * 0.88;
    final amp = size.width / 2 * 0.12;
    final path = Path();
    const steps = 240;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps * 2 * math.pi;
      final rad = base + amp * math.cos(_scallops * t);
      final p = Offset(c.dx + rad * math.cos(t), c.dy + rad * math.sin(t));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CookiePainter old) => old.color != color;
}

class GithubStarBanner extends ConsumerWidget {
  final EdgeInsetsGeometry? margin;
  final bool asSliver;

  const GithubStarBanner({super.key, this.margin, this.asSliver = false});
  const GithubStarBanner.sliver({super.key, this.margin}) : asSliver = true;

  static Future<void> launchGithub() async {
    final uri = Uri.parse(kShonenXRepoUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<void> launchDiscord() async {
    final uri = Uri.parse(kShonenXDiscordUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static void showDetailsDialog(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final colors = _StarColors.of(context);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        elevation: 0,
        backgroundColor: cs.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CustomPaint(
                painter: _CookiePainter(colors.accent),
                child: Icon(
                  Icons.star_rounded,
                  color: colors.onAccent,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Help us recover stars!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'A small mishap happened: the ShonenX repository was briefly toggled to private by mistake. '
          'Because of GitHub\'s policy, changing a repository to private automatically drops all its stars and watchers to 0.\n\n'
          'If you love using ShonenX, your star on GitHub is the single biggest motivation and visibility boost for the project. '
          'It only takes 5 seconds and helps us rebuild what was lost! ❤️',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: cs.onSurfaceVariant,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(githubStarBannerDismissedProvider.notifier).dismiss();
              Navigator.of(ctx).pop();
            },
            child: const Text('Already starred'),
          ),
          FilledButton.icon(
            style: ButtonStyle(
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(colors.accent),
              foregroundColor: WidgetStatePropertyAll(colors.onAccent),
              shape: _morphShape(),
              minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
            ),
            onPressed: () {
              launchGithub();
              ref.read(githubStarBannerDismissedProvider.notifier).dismiss();
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.star_rounded, size: 20),
            label: const Text(
              'Star on GitHub',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDismissed = ref.watch(githubStarBannerDismissedProvider);
    final notifier = ref.read(githubStarBannerDismissedProvider.notifier);

    final cs = Theme.of(context).colorScheme;
    final colors = _StarColors.of(context);

    final banner = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => SizeTransition(
            sizeFactor: anim,
            axisAlignment: -1,
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: isDismissed
              ? const SizedBox.shrink(key: ValueKey('star-banner-hidden'))
              : TweenAnimationBuilder<double>(
                  key: const ValueKey('star-banner-visible'),
                  tween: Tween(begin: 0.92, end: 1),
                  duration: const Duration(milliseconds: 550),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) => Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: child,
                  ),
                  child: Padding(
                    padding: margin ?? const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Material(
                      color: colors.container,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => showDetailsDialog(context, ref),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -28,
                              bottom: -34,
                              child: Transform.rotate(
                                angle: -0.28,
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 150,
                                  color: colors.accentSoft,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                10,
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: CustomPaint(
                                          painter: _CookiePainter(
                                            colors.accent,
                                          ),
                                          child: Icon(
                                            Icons.star_rounded,
                                            color: colors.onAccent,
                                            size: 28,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Help ShonenX get its stars back!',
                                              style: TextStyle(
                                                fontSize: 17,
                                                height: 1.15,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.4,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              'Repo went private by accident — stars reset to 0',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                        ),
                                        tooltip: 'Dismiss',
                                        visualDensity: VisualDensity.compact,
                                        color: cs.onSurfaceVariant,
                                        onPressed: notifier.dismiss,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 56),
                                    child: Text(
                                      'GitHub wiped every star when the repo flipped to private. '
                                      'If ShonenX has helped you, re-starring takes 5 seconds and means everything! ❤️',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: cs.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      FilledButton.icon(
                                        style: ButtonStyle(
                                          elevation:
                                              const WidgetStatePropertyAll(0),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                colors.accent,
                                              ),
                                          foregroundColor:
                                              WidgetStatePropertyAll(
                                                colors.onAccent,
                                              ),
                                          shape: _morphShape(),
                                          minimumSize:
                                              const WidgetStatePropertyAll(
                                                Size(0, 46),
                                              ),
                                          padding: const WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                              horizontal: 20,
                                            ),
                                          ),
                                          textStyle:
                                              const WidgetStatePropertyAll(
                                                TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                        ),
                                        onPressed: () {
                                          launchGithub();
                                          notifier.dismiss();
                                        },
                                        icon: const Icon(
                                          Icons.star_rounded,
                                          size: 19,
                                        ),
                                        label: const Text('Re-star on GitHub'),
                                      ),
                                      FilledButton.tonalIcon(
                                        style: ButtonStyle(
                                          elevation:
                                              const WidgetStatePropertyAll(0),
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                                cs.surface.withValues(
                                                  alpha: 0.7,
                                                ),
                                              ),
                                          foregroundColor:
                                              WidgetStatePropertyAll(
                                                cs.onSurface,
                                              ),
                                          shape: _morphShape(),
                                          minimumSize:
                                              const WidgetStatePropertyAll(
                                                Size(0, 46),
                                              ),
                                          padding: const WidgetStatePropertyAll(
                                            EdgeInsets.symmetric(
                                              horizontal: 18,
                                            ),
                                          ),
                                          textStyle:
                                              const WidgetStatePropertyAll(
                                                TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                        ),
                                        onPressed: launchDiscord,
                                        icon: const Icon(
                                          Icons.forum_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Discord'),
                                      ),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: cs.onSurfaceVariant,
                                          minimumSize: const Size(0, 46),
                                          shape: const StadiumBorder(),
                                          textStyle: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: () {
                                          notifier.dismiss();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Thank you so much for your support! ❤️',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Text('Already starred'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );

    if (asSliver) {
      return SliverToBoxAdapter(child: banner);
    }
    return banner;
  }
}
