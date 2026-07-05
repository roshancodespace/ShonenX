import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'runtime_setup_sheet.dart';

class ExtensionGuideSheet extends ConsumerWidget {
  const ExtensionGuideSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExtensionGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isRuntimeReady = bridge.AnymeXRuntimeBridge.controller.isReady.value;

    return AppBottomSheet(
      title: 'Extensions Guide',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRuntimeBanner(context, ref, cs, textTheme, isRuntimeReady),
            const SizedBox(height: 20),
            Text(
              'SUPPORTED REPOSITORIES',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            _buildMinimalItem(
              context: context,
              title: 'Aniyomi (Anime)',
              badge: 'Recommended',
              badgeColor: Colors.amber.shade700,
              icon: Icons.play_circle_outline_rounded,
              description:
                  'High-speed video streaming extensions curated specifically for anime sources.',
            ),
            _buildMinimalItem(
              context: context,
              title: 'Tachiyomi / Keiyoushi (Manga)',
              badge: 'Recommended',
              badgeColor: Colors.blue.shade700,
              icon: Icons.menu_book_rounded,
              description:
                  'Vast catalog of manga extensions with multi-language support.',
            ),
            _buildMinimalItem(
              context: context,
              title: 'CloudStream',
              badge: 'Multi-Source',
              badgeColor: Colors.teal.shade700,
              icon: Icons.cloud_queue_rounded,
              description:
                  'Versatile multi-source streaming extensions and scrapers.',
            ),
            _buildMinimalItem(
              context: context,
              title: 'Mangayomi',
              badge: 'All-in-One',
              badgeColor: Colors.purple.shade700,
              icon: Icons.all_inclusive_rounded,
              description:
                  'Built-in engine supporting both anime and manga extensions natively.',
            ),
            const SizedBox(height: 20),
            Text(
              'PRO TIPS',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            _buildMinimalTip(
              context: context,
              icon: Icons.push_pin_outlined,
              title: 'Pin Default Source',
              content:
                  'Tap the pin icon on any installed extension to set it as your default streaming or reading source.',
            ),
            _buildMinimalTip(
              context: context,
              icon: Icons.folder_outlined,
              title: 'Language Groups',
              content:
                  'Extensions with multiple translations are grouped into folders. Tap to expand and install specific variants.',
            ),
            _buildMinimalTip(
              context: context,
              icon: Icons.system_update_alt_rounded,
              title: 'Runtime Bridge Updates',
              content:
                  'We only allow force updates for the runtime bridge. Always check releases from github.com/RyanYuuki/AnymeXExtensionRuntimeBridge/releases (e.g. v1.9.0) and restart ShonenX after updating!',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Got it!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRuntimeBanner(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
    TextTheme textTheme,
    bool isRuntimeReady,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isRuntimeReady
              ? [
                  Colors.green.withValues(alpha: 0.15),
                  Colors.green.withValues(alpha: 0.05),
                ]
              : [
                  cs.primaryContainer.withValues(alpha: 0.6),
                  cs.primaryContainer.withValues(alpha: 0.2),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRuntimeReady
              ? Colors.green.withValues(alpha: 0.4)
              : cs.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRuntimeReady
                      ? Colors.green.withValues(alpha: 0.2)
                      : cs.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRuntimeReady
                      ? Icons.verified_rounded
                      : Icons.memory_rounded,
                  color: isRuntimeReady ? Colors.green.shade600 : cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRuntimeReady
                          ? 'Runtime Bridge Active'
                          : 'Runtime Bridge Required',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      isRuntimeReady
                          ? 'Aniyomi & CloudStream engines are ready'
                          : 'Required for Aniyomi, Tachiyomi & CloudStream',
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'To keep ShonenX lightweight and fast, heavy native extension extractors run inside a dedicated runtime bridge. This modular separation guarantees app stability and security.',
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showRuntimeSetupSheet(context, ref);
              },
              icon: Icon(
                isRuntimeReady
                    ? Icons.settings_suggest_rounded
                    : Icons.download_rounded,
                size: 18,
                color: isRuntimeReady ? Colors.green.shade600 : cs.primary,
              ),
              label: Text(
                isRuntimeReady
                    ? 'Manage Runtime Bridge'
                    : 'Setup Runtime Bridge Now',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isRuntimeReady ? Colors.green.shade600 : cs.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isRuntimeReady
                      ? Colors.green.withValues(alpha: 0.5)
                      : cs.primary.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalItem({
    required BuildContext context,
    required String title,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required String description,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.primary.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalTip({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: cs.secondary.withValues(alpha: 0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
