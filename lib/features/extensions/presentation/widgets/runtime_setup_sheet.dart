import 'dart:io';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:file_picker/file_picker.dart';
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
  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    final controller = bridge.AnymeXRuntimeBridge.controller;
    if (!controller.isReady.value) {
      final loaded = await bridge.AnymeXRuntimeBridge.isLoaded();
      if (!loaded) {
        await bridge.AnymeXRuntimeBridge.checkAndInitialize();
      }
      if (bridge.AnymeXRuntimeBridge.controller.isReady.value) {
        final extManager = Get.find<bridge.ExtensionManager>();
        await extManager.onRuntimeBridgeInitialization(force: false);
        ref.invalidate(extensionManagerProvider);
        ref.invalidate(availableAnimeSourcesProvider);
        ref.invalidate(availableMangaSourcesProvider);
        if (mounted) setState(() {});
        widget.onComplete?.call();
      }
    }
  }

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

  Future<void> _pickLocalApk() async {
    final controller = bridge.AnymeXRuntimeBridge.controller;
    controller.error.value = '';
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );
      if (result != null && result.files.single.path != null) {
        controller.updateStatus("Loading local APK...");
        controller.isDownloading.value = true;
        final success = await bridge.AnymeXRuntimeBridge.useLocalApk(
          result.files.single.path!,
        );
        if (success) {
          final extManager = Get.find<bridge.ExtensionManager>();
          await extManager.onRuntimeBridgeInitialization(force: true);
          ref.invalidate(extensionManagerProvider);
          ref.invalidate(availableAnimeSourcesProvider);
          ref.invalidate(availableMangaSourcesProvider);
          widget.onComplete?.call();
        } else {
          controller.setError("Failed to initialize from selected APK file.");
        }
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer.withValues(alpha: 0.4),
                  cs.secondaryContainer.withValues(alpha: 0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.primary.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.extension_rounded,
                        color: cs.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AnymeX Runtime Bridge',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Architecture: ${Platform.operatingSystem.toUpperCase()}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildBadge(context, 'Aniyomi (Anime & Manga)'),
                    _buildBadge(context, 'CloudStream (Movies & TV)'),
                    _buildBadge(context, 'Kotatsu (Manga)'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'IMPORTANT: Aniyomi, CloudStream, and Kotatsu extensions require the Runtime Bridge to execute source parsers. Separation is intentional — it avoids bundling heavy native dependencies directly into the app.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.45,
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
                    Uri.parse(
                      'https://github.com/RyanYuuki/AnymeXExtensionRuntimeBridge',
                    ),
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
                      style: TextStyle(
                        color: cs.onErrorContainer,
                        fontSize: 13,
                      ),
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
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 26,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Runtime Bridge Ready',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'All native extension ecosystems are initialized.',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _startSetup(force: true),
                          icon: const Icon(Icons.system_update_alt_rounded),
                          label: const Text('Force Update'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
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
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (Platform.isAndroid) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickLocalApk,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.folder_open_rounded, size: 18),
                          label: const Text(
                            'Select Local APK',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          controller.updateStatus(
                            "Scanning disk for runtime...",
                          );
                          await bridge.AnymeXRuntimeBridge.checkAndInitialize();
                          if (!controller.isReady.value) {
                            controller.setError(
                              "No existing runtime found on disk.",
                            );
                          } else {
                            final extManager =
                                Get.find<bridge.ExtensionManager>();
                            await extManager.onRuntimeBridgeInitialization(
                              force: false,
                            );
                            ref.invalidate(extensionManagerProvider);
                            ref.invalidate(availableAnimeSourcesProvider);
                            ref.invalidate(availableMangaSourcesProvider);
                            widget.onComplete?.call();
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text(
                          'Scan Disk',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
    );
  }
}
