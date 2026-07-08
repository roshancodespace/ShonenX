import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'extension_beginner_sheet.dart';
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
      title: 'Extensions Quick Guide',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRuntimeBanner(context, ref, cs, textTheme, isRuntimeReady),
            const SizedBox(height: 20),
            Text(
              'QUICK STEPS',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            _buildGuideStep(
              context: context,
              stepNumber: '1',
              title: 'Add Repositories & Install',
              description:
                  'Add repository URLs to discover and install external extensions from supported runtime engines (Mangayomi, Aniyomi, CloudStream, etc.).',
              icon: Icons.add_circle_outline_rounded,
            ),
            _buildGuideStep(
              context: context,
              stepNumber: '2',
              title: 'Pin Your Default Source',
              description:
                  'Tap the pin icon on any installed extension or inbuilt source to set it as your default streaming or reading provider.',
              icon: Icons.push_pin_outlined,
            ),
            _buildGuideStep(
              context: context,
              stepNumber: '3',
              title: 'Filter by Engine & Language',
              description:
                  'Use the capsule pills right above the tabs to organize sources by specific language or extension engine.',
              icon: Icons.filter_list_rounded,
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.pop(context);
                ExtensionBeginnerSheet.show(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: cs.errorContainer,
                foregroundColor: cs.onErrorContainer,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.help_outline_rounded),
              label: const Text(
                'Retarded? Interactive Beginner Guide',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
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
                        ? 'Extension Runtime Active'
                        : 'Extension Runtime Required',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isRuntimeReady ? Colors.green : cs.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRuntimeReady
                        ? 'External engines (Mangayomi, Aniyomi, CloudStream, etc.) are connected via runtime bridge.'
                        : 'Set up the runtime bridge to enable external extension engines.',
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

  Widget _buildGuideStep({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
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
}
