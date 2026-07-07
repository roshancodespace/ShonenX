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
                  'Check GitHub releases for updates and always restart ShonenX after force updating the runtime!',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isRuntimeReady ? Icons.verified_rounded : Icons.memory_rounded,
              color: isRuntimeReady ? Colors.green : cs.primary,
              size: 24,
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
                      color: isRuntimeReady ? Colors.green : cs.primary,
                    ),
                  ),
                  Text(
                    isRuntimeReady
                        ? 'Ready for Aniyomi & CloudStream extensions.'
                        : 'Required to run Aniyomi & CloudStream extensions.',
                    style: textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                showRuntimeSetupSheet(context, ref);
              },
              child: Text(isRuntimeReady ? 'Manage' : 'Setup Now'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
      ],
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
