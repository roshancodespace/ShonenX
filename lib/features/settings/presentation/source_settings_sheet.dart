import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/network/cf_client.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/media_source.dart';
import 'package:shonenx/source_engine/providers/source_settings_provider.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class SourceSettingsSheet extends ConsumerStatefulWidget {
  final SourceInfo source;
  final List<SourceSetting> schema;

  const SourceSettingsSheet({
    super.key,
    required this.source,
    required this.schema,
  });

  @override
  ConsumerState<SourceSettingsSheet> createState() =>
      _SourceSettingsSheetState();
}

class _SourceSettingsSheetState extends ConsumerState<SourceSettingsSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.schema.isNotEmpty) {
        final notifier = ref.read(
          sourceSettingsProvider(widget.source.id).notifier,
        );
        notifier.syncSchemaDefaults(widget.schema);
      }
    });
  }

  MediaSource? _getMediaSource() {
    try {
      if (widget.source.mediaType == MediaType.ANIME) {
        return ref.read(animeSourceProvider(widget.source)) as MediaSource;
      } else {
        return ref.read(mangaSourceProvider(widget.source)) as MediaSource;
      }
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.source;
    final schema = widget.schema;
    final settingsMap = ref.watch(sourceSettingsProvider(source.id));
    final notifier = ref.read(sourceSettingsProvider(source.id).notifier);
    final mediaSource = _getMediaSource();
    final theme = Theme.of(context);
    final hasBaseUrl = source.baseUrl != null && source.baseUrl!.isNotEmpty;

    return AppBottomSheet(
      title: '${source.name} Settings',
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        shrinkWrap: true,
        children: [
          if (hasBaseUrl || source.type == SourceType.extension) ...[
            _buildCloudflareCard(context, source),
            const SizedBox(height: 12),
          ],
          if (schema.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
              child: Center(
                child: Text(
                  'No additional configuration settings are required for this source.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ] else ...[
            ...schema.map(
              (setting) => _buildSettingTile(
                context,
                setting,
                settingsMap,
                notifier,
                mediaSource,
                source,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCloudflareCard(BuildContext context, SourceInfo source) {
    final theme = Theme.of(context);
    final host = source.baseUrl != null && source.baseUrl!.isNotEmpty
        ? (Uri.tryParse(source.baseUrl!)?.host ?? source.baseUrl!)
        : source.name;
    final hasClearance = CFClient.instance.hasClearanceForHost(host);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasClearance
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasClearance
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasClearance
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasClearance
                  ? Icons.verified_user_rounded
                  : Icons.security_rounded,
              color: hasClearance
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cloudflare Verification',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasClearance
                      ? 'Clearance cookies active for $host'
                      : 'Solve Turnstile / Bot challenge in WebView',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (hasClearance) ...[
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              tooltip: 'Clear clearance cookies',
              onPressed: () async {
                await CFClient.instance.clearCookiesForHost(host);
                setState(() {});
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cleared cookies for $host'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            const SizedBox(width: 4),
          ],
          FilledButton.tonal(
            onPressed: () async {
              final solved = await CFClient.solveForSource(context, source);
              if (solved && mounted) {
                setState(() {});
              }
            },
            child: Text(hasClearance ? 'Re-verify' : 'Solve'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    SourceSetting setting,
    Map<String, dynamic> settingsMap,
    SourceSettingsNotifier notifier,
    MediaSource? mediaSource,
    SourceInfo source,
  ) {
    final theme = Theme.of(context);
    final currentValue = settingsMap[setting.id] ?? setting.defaultValue;

    bool isEnabled = true;
    String? displaySubtitle = setting.description;

    if (source.id == 'animepahe') {
      final useWebviewBypass = settingsMap['use_webview_bypass'] ?? true;
      if (setting.id == 'cf_bypass_proxy' && useWebviewBypass == true) {
        isEnabled = false;
        displaySubtitle = 'Inactive (In-app Cloudflare Bypass is enabled)';
      }
    }

    if (setting.isBoolean) {
      return SettingsSwitchTile(
        icon: Icons.toggle_on_outlined,
        title: setting.name,
        subtitle: displaySubtitle,
        value: currentValue as bool? ?? false,
        onChanged: isEnabled
            ? (val) {
                notifier.updateSetting(
                  setting.id,
                  val,
                  mediaSource: mediaSource,
                );
              }
            : null,
      );
    } else if (setting.isSelect) {
      return SettingsActionTile(
        icon: Icons.list_alt_rounded,
        title: setting.name,
        subtitle: currentValue?.toString() ?? 'Default',
        onTap: isEnabled
            ? () {
                _showSelectSheet(
                  context,
                  title: setting.name,
                  options: setting.options ?? [],
                  currentValue: currentValue?.toString() ?? '',
                  onChanged: (val) {
                    notifier.updateSetting(
                      setting.id,
                      val,
                      mediaSource: mediaSource,
                    );
                  },
                );
              }
            : null,
      );
    } else if (setting.isText) {
      final textSubtitle = isEnabled
          ? (currentValue?.toString() ?? displaySubtitle)
          : '${currentValue?.toString() ?? ""}\n(Inactive - In-app Cloudflare Bypass is active)';

      return SettingsActionTile(
        icon: Icons.text_fields_rounded,
        title: setting.name,
        subtitle: textSubtitle,
        foregroundColor: isEnabled
            ? null
            : theme.colorScheme.onSurface.withValues(alpha: 0.38),
        onTap: isEnabled
            ? () {
                _showTextEditSheet(
                  context,
                  title: setting.name,
                  currentValue: currentValue?.toString() ?? '',
                  onChanged: (val) {
                    notifier.updateSetting(
                      setting.id,
                      val,
                      mediaSource: mediaSource,
                    );
                  },
                );
              }
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Disable "In-app Cloudflare Bypass" to use a custom proxy.',
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
      );
    } else if (setting.isMultiSelect) {
      final List<String> currentList = (currentValue as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      return SettingsActionTile(
        icon: Icons.checklist_rtl_rounded,
        title: setting.name,
        subtitle: currentList.isEmpty ? 'None' : currentList.join(', '),
        onTap: isEnabled
            ? () {
                _showMultiSelectSheet(
                  context,
                  title: setting.name,
                  options: setting.options ?? [],
                  currentValues: currentList,
                  onChanged: (val) {
                    notifier.updateSetting(
                      setting.id,
                      val,
                      mediaSource: mediaSource,
                    );
                  },
                );
              }
            : null,
      );
    }

    return const SizedBox.shrink();
  }

  void _showSelectSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    AppBottomSheet.showSelector<String>(
      context: context,
      title: title,
      items: options,
      itemLabel: (item) => item,
      selectedValue: currentValue,
      onChanged: onChanged,
    );
  }

  void _showTextEditSheet(
    BuildContext context, {
    required String title,
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    final controller = TextEditingController(text: currentValue);
    AppBottomSheet.show(
      context: context,
      title: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              onChanged(controller.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required List<String> currentValues,
    required ValueChanged<List<String>> onChanged,
  }) {
    List<String> selected = List.from(currentValues);

    AppBottomSheet.show(
      context: context,
      title: title,
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: options.map((option) {
                      final isSelected = selected.contains(option);
                      return CheckboxListTile(
                        title: Text(option),
                        value: isSelected,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selected.add(option);
                            } else {
                              if (selected.length > 1) {
                                selected.remove(option);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'At least one option must be selected.',
                                    ),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  onChanged(selected);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
