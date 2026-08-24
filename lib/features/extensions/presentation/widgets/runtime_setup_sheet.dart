import 'dart:io';
import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart'
    as bridge;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/core/updates/models/github_release.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/features/extensions/providers/runtime_update_provider.dart';
import 'package:shonenx/source_engine/utils/source_invalidation.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> showRuntimeSetupSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onComplete,
}) {
  return showModalBottomSheet(
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
        if (!mounted) return;
        ref.invalidateAllSources();
        if (mounted) setState(() {});
        widget.onComplete?.call();
      }
    }
  }

  Future<void> _selectRelease() async {
    final controller = bridge.AnymeXRuntimeBridge.controller;
    controller.updateStatus("Fetching releases...");
    controller.isDownloading.value = true;

    try {
      final http = HTTP();
      final response = await http.get(
        'https://api.github.com/repos/RyanYuuki/AnymeXExtensionRuntimeBridge/releases',
      );

      controller.isDownloading.value = false;

      if (!mounted) return;

      if (response.json is! List) {
        throw Exception("Failed to parse releases");
      }

      final jsonList = (response.json as List)
          .whereType<Map<String, dynamic>>();
      final releases = jsonList.map(GitHubRelease.fromJson).toList();

      final selected = await showModalBottomSheet<GitHubRelease>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AppBottomSheet(
          title: 'Select Release',
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: ListView.builder(
              itemCount: releases.length,
              itemBuilder: (context, index) {
                final release = releases[index];
                final name = release.name.isNotEmpty
                    ? release.name
                    : release.tagName;
                final dateStr = release.publishedAt
                    .toIso8601String()
                    .split('T')
                    .first;

                return ListTile(
                  title: Text(name),
                  subtitle: Text(dateStr),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, release),
                );
              },
            ),
          ),
        ),
      );

      if (selected != null && mounted) {
        final tagName = selected.tagName;
        final isAndroid = Platform.isAndroid;
        final assetName = isAndroid
            ? 'anymex_runtime_host.apk'
            : 'anymex_desktop_runtime.jar';

        final asset = selected.assets.firstWhereOrNull(
          (a) => a.name == assetName,
        );

        final downloadUrl = (asset != null && asset.downloadUrl.isNotEmpty)
            ? asset.downloadUrl
            : 'https://github.com/RyanYuuki/AnymeXExtensionRuntimeBridge/releases/download/$tagName/$assetName';

        await _startSetup(
          force: true,
          version: tagName.replaceAll('v', ''),
          customDownloadUrl: downloadUrl,
        );
      }
    } catch (e) {
      controller.isDownloading.value = false;
      controller.setError(e.toString());
    }
  }

  Future<void> _startSetup({
    bool force = false,
    String? version,
    String? customDownloadUrl,
  }) async {
    final controller = bridge.AnymeXRuntimeBridge.controller;
    controller.error.value = '';
    try {
      await bridge.AnymeXRuntimeBridge.setupRuntime(
        force: force,
        customDownloadUrl: customDownloadUrl,
      );
      if (controller.isReady.value) {
        try {
          final latest =
              version ?? await ref.read(runtimeUpdateProvider.future);
          if (latest != null) {
            bridge.AnymeXRuntimeBridge.setInstalledRelease(latest, 'v$latest');
          }
        } catch (_) {}

        final extManager = Get.find<bridge.ExtensionManager>();
        await extManager.onRuntimeBridgeInitialization(force: true);
        if (!mounted) return;
        ref.invalidateAllSources();
        ref.invalidate(runtimeUpdateProvider);
        ref.read(enabledExtensionManagersProvider.notifier).enableAll([
          'aniyomi',
          'cloudstream',
          'kotatsu',
        ]);
        if (mounted && force) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Runtime updated! Please restart ShonenX for changes to take effect.',
              ),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 5),
            ),
          );
        }
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
          if (!mounted) return;
          ref.invalidateAllSources();
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
      title: 'Runtime Bridge Setup',
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.extension_rounded, color: cs.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AnymeX Runtime (${Platform.operatingSystem.toUpperCase()})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Required for Aniyomi, CloudStream & Kotatsu extensions.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

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
                    Text(
                      error,
                      style: TextStyle(color: cs.error, fontSize: 13),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Runtime Installed & Active',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'v${bridge.AnymeXRuntimeBridge.installedVersion}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse(
                              'https://github.com/RyanYuuki/AnymeXExtensionRuntimeBridge/releases',
                            ),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: const Text(
                            'Releases',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Always restart ShonenX after force updating the runtime.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Consumer(
                      builder: (context, ref, _) {
                        final updateAsync = ref.watch(runtimeUpdateProvider);
                        final updateVersion = updateAsync.value;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _startSetup(
                                      force: true,
                                      version: updateVersion,
                                    ),
                                    icon: const Icon(
                                      Icons.system_update_alt_rounded,
                                    ),
                                    label: Text(
                                      updateVersion != null
                                          ? 'Update Available (v$updateVersion)'
                                          : 'Force Update',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      foregroundColor: updateVersion != null
                                          ? cs.primary
                                          : null,
                                      side: updateVersion != null
                                          ? BorderSide(color: cs.primary)
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selectRelease,
                                    icon: const Icon(Icons.list_alt_rounded),
                                    label: const Text('Select Release'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Done'),
                              ),
                            ),
                          ],
                        );
                      },
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text(
                      'Download & Setup Runtime',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(
                              Icons.folder_open_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Select APK',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            controller.updateStatus("Scanning disk...");
                            await bridge
                                .AnymeXRuntimeBridge.checkAndInitialize();
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
            const SizedBox(height: 16),
            Center(
              child: InkWell(
                onTap: () => launchUrl(
                  Uri.parse(
                    'https://github.com/RyanYuuki/AnymeXExtensionRuntimeBridge',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    'Powered by AnymeXExtensionRuntimeBridge (RyanYuuki)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.outline,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
