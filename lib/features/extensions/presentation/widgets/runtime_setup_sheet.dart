import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:url_launcher/url_launcher.dart';

void showRuntimeSetupSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onComplete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => RuntimeSetupSheet(onComplete: onComplete),
  );
}

class RuntimeSetupSheet extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;

  const RuntimeSetupSheet({super.key, this.onComplete});

  @override
  ConsumerState<RuntimeSetupSheet> createState() => _RuntimeSetupSheetState();
}

class _RuntimeSetupSheetState extends ConsumerState<RuntimeSetupSheet> {
  Future<void> _startSetup({bool force = false}) async {
    final controller = bridge.AnymeXRuntimeBridge.controller;
    controller.error.value = '';
    try {
      await bridge.AnymeXRuntimeBridge.setupRuntime(force: force);
      if (controller.isReady.value) {
        final extManager = Get.find<bridge.ExtensionManager>();
        await extManager.onRuntimeBridgeInitialization(force: true);
        ref.invalidate(extensionManagerProvider);
        ref.invalidate(availableAnimeSourcesProvider);
        ref.invalidate(availableMangaSourcesProvider);
        widget.onComplete?.call();
      }
    } catch (e) {
      controller.setError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final controller = bridge.AnymeXRuntimeBridge.controller;

    return AppBottomSheet(
      title: 'Extension Runtime Setup',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.extension_rounded, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aniyomi & CloudStream Runtime',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'IMPORTANT: Aniyomi and CloudStream extensions will NOT work without loading the Runtime Bridge first. Separation is intentional — it avoids bundling heavy native dependencies (like the JVM or JRE) directly into your app.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.code_rounded, size: 20, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ShonenX uses a minimal customized fork of AnymeXExtensionRuntimeBridge originally created by RyanYuuki.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  tooltip: 'Open GitHub Repository',
                  onPressed: () => launchUrl(
                    Uri.parse('https://github.com/RyanYuuki/AnymeXExtensionRuntimeBridge'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Obx(() {
            final isDownloading = controller.isDownloading.value;
            final isReady = controller.isReady.value;
            final error = controller.error.value;
            final status = controller.status.value;
            final progress = controller.downloadProgress.value;
            final sizeInfo = controller.sizeInfo.value;

            if (isDownloading) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          status,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (sizeInfo.isNotEmpty)
                        Text(
                          sizeInfo,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress > 0 ? progress : null,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }

            if (error.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      error,
                      style: TextStyle(color: cs.onErrorContainer, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _startSetup(force: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Setup'),
                  ),
                ],
              );
            }

            if (isReady) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Runtime Bridge is installed and ready!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _startSetup(force: true),
                          icon: const Icon(Icons.system_update_alt_rounded),
                          label: const Text('Force Update'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return FilledButton.icon(
              onPressed: () => _startSetup(),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text(
                'Download & Setup Runtime',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            );
          }),
        ],
      ),
    );
  }
}
