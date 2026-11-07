import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/data/translation/subtitle_cache_service.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';
import 'package:shonenx/features/player/providers/subtitle_translation_prefs_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';

class SubtitleTranslationSettingsSheet extends ConsumerStatefulWidget {
  const SubtitleTranslationSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show(
      context: context,
      title: 'Subtitle Translation',
      titleIcon: Icons.translate_rounded,
      child: const SubtitleTranslationSettingsSheet(),
    );
  }

  @override
  ConsumerState<SubtitleTranslationSettingsSheet> createState() =>
      _SubtitleTranslationSettingsSheetState();
}

class _SubtitleTranslationSettingsSheetState
    extends ConsumerState<SubtitleTranslationSettingsSheet> {
  int _cacheSizeBytes = 0;
  bool _isLoadingCache = true;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    try {
      final size = await SubtitleCacheService.getCacheSizeBytes();
      if (mounted) {
        setState(() {
          _cacheSizeBytes = size;
          _isLoadingCache = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingCache = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(subtitleTranslationPrefsProvider);
    final notifier = ref.read(subtitleTranslationPrefsProvider.notifier);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSection(
            title: 'General',
            children: [
              SettingsSwitchTile(
                icon: Icons.translate_rounded,
                title: 'Enable Translation',
                value: config.enabled,
                onChanged: notifier.setEnabled,
              ),
              SettingsSwitchTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Auto-Translate',
                subtitle:
                    'Translate when preferred subtitle language is missing',
                value: config.autoTranslateIfPreferredMissing,
                onChanged: config.enabled
                    ? notifier.setAutoTranslateIfPreferredMissing
                    : null,
              ),
              SettingsDropdownTile<String>(
                icon: Icons.language_rounded,
                title: 'Target Language',
                value: config.defaultTargetLanguage,
                items: kSupportedSubtitleLanguages.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: config.enabled
                    ? (val) {
                        if (val != null) notifier.setDefaultTargetLanguage(val);
                      }
                    : null,
              ),
              SettingsDropdownTile<TranslationStrategy>(
                icon: Icons.download_for_offline_rounded,
                title: 'Strategy',
                value: config.strategy,
                items: const [
                  DropdownMenuItem(
                    value: TranslationStrategy.bulk,
                    child: Text('Bulk (Pre-load full episode)'),
                  ),
                  DropdownMenuItem(
                    value: TranslationStrategy.onDemand,
                    child: Text('On-Demand (Live chunks)'),
                  ),
                ],
                onChanged: config.enabled
                    ? (val) {
                        if (val != null) notifier.setStrategy(val);
                      }
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 12),

          SettingsSection(
            title: 'Provider Priority',
            children: [
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: config.providerPriority.length,
                buildDefaultDragHandles: false,
                onReorder: notifier.reorderProviders,
                itemBuilder: (context, index) {
                  final type = config.providerPriority[index];
                  final isEnabled = config.providerEnabled[type] ?? false;

                  return ListTile(
                    key: ValueKey(type.name),
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: cs.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      '${index + 1}. ${type.displayName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      _getProviderSubtitle(type, config),
                      style: TextStyle(
                        fontSize: 11,
                        color: _isProviderReady(type, config)
                            ? cs.onSurfaceVariant
                            : cs.error,
                      ),
                    ),
                    trailing: Switch.adaptive(
                      value: isEnabled,
                      onChanged: (val) =>
                          notifier.setProviderEnabled(type, val),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          SettingsSection(
            title: 'API Keys',
            children: [
              SettingsActionTile(
                icon: Icons.bolt_rounded,
                title: 'Google Gemini',
                subtitle: config.geminiApiKey.isNotEmpty
                    ? '${config.geminiModel} (Configured)'
                    : 'Set API Key',
                onTap: () => _showGeminiDialog(context, config, notifier),
              ),
              SettingsActionTile(
                icon: Icons.menu_book_rounded,
                title: 'DeepL',
                subtitle: config.deeplApiKey.isNotEmpty
                    ? (config.deeplUsePro ? 'Pro API' : 'Free API')
                    : 'Set Auth Key',
                onTap: () => _showDeepLDialog(context, config, notifier),
              ),
              SettingsActionTile(
                icon: Icons.smart_toy_rounded,
                title: 'OpenAI-Compatible',
                subtitle: config.openaiApiKey.isNotEmpty
                    ? config.openaiModel
                    : 'Set API Key & URL',
                onTap: () => _showOpenAIDialog(context, config, notifier),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SettingsSection(
            title: 'Storage',
            children: [
              SettingsActionTile(
                icon: Icons.storage_rounded,
                title: 'Clear Cache',
                subtitle: _isLoadingCache
                    ? 'Calculating...'
                    : _formatBytes(_cacheSizeBytes),
                trailing: TextButton(
                  onPressed: _cacheSizeBytes == 0
                      ? null
                      : () => _confirmClearCache(context),
                  child: Text('Clear', style: TextStyle(color: cs.error)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getProviderSubtitle(
    TranslationProviderType type,
    SubtitleTranslationConfig config,
  ) {
    switch (type) {
      case TranslationProviderType.google:
        return 'Free (No key needed)';
      case TranslationProviderType.gemini:
        return config.geminiApiKey.trim().isNotEmpty
            ? 'Configured (${config.geminiModel})'
            : 'Key missing';
      case TranslationProviderType.deepl:
        return config.deeplApiKey.trim().isNotEmpty
            ? 'Configured (${config.deeplUsePro ? "Pro" : "Free"})'
            : 'Key missing';
      case TranslationProviderType.openai:
        return config.openaiApiKey.trim().isNotEmpty
            ? 'Configured (${config.openaiModel})'
            : 'Key missing';
    }
  }

  bool _isProviderReady(
    TranslationProviderType type,
    SubtitleTranslationConfig config,
  ) {
    switch (type) {
      case TranslationProviderType.google:
        return true;
      case TranslationProviderType.gemini:
        return config.geminiApiKey.trim().isNotEmpty;
      case TranslationProviderType.deepl:
        return config.deeplApiKey.trim().isNotEmpty;
      case TranslationProviderType.openai:
        return config.openaiApiKey.trim().isNotEmpty;
    }
  }

  Future<void> _showGeminiDialog(
    BuildContext context,
    SubtitleTranslationConfig config,
    SubtitleTranslationPrefsNotifier notifier,
  ) async {
    final keyController = TextEditingController(text: config.geminiApiKey);
    final modelController = TextEditingController(text: config.geminiModel);

    await AppDialog.show(
      context: context,
      title: 'Google Gemini',
      maxWidth: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: keyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'AIzaSy...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: modelController,
            decoration: InputDecoration(
              labelText: 'Model',
              hintText: 'gemini-2.5-flash',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            notifier.setGeminiApiKey(keyController.text.trim());
            notifier.setGeminiModel(
              modelController.text.trim().isNotEmpty
                  ? modelController.text.trim()
                  : 'gemini-2.5-flash',
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _showDeepLDialog(
    BuildContext context,
    SubtitleTranslationConfig config,
    SubtitleTranslationPrefsNotifier notifier,
  ) async {
    final keyController = TextEditingController(text: config.deeplApiKey);
    bool usePro = config.deeplUsePro;

    await AppDialog.show(
      context: context,
      title: 'DeepL API',
      maxWidth: 420,
      child: StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Auth Key',
                  hintText: 'xxxxxxxx-xxxx-xxxx-xxxx:fx',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use DeepL Pro API'),
                value: usePro,
                onChanged: (val) => setDialogState(() => usePro = val),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            notifier.setDeeplApiKey(keyController.text.trim());
            notifier.setDeeplUsePro(usePro);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _showOpenAIDialog(
    BuildContext context,
    SubtitleTranslationConfig config,
    SubtitleTranslationPrefsNotifier notifier,
  ) async {
    final urlController = TextEditingController(text: config.openaiBaseUrl);
    final keyController = TextEditingController(text: config.openaiApiKey);
    final modelController = TextEditingController(text: config.openaiModel);

    await AppDialog.show(
      context: context,
      title: 'OpenAI-Compatible API',
      maxWidth: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            decoration: InputDecoration(
              labelText: 'Base URL',
              hintText: 'https://api.openai.com/v1',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: keyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'API Key',
              hintText: 'sk-...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: modelController,
            decoration: InputDecoration(
              labelText: 'Model',
              hintText: 'gpt-4o-mini',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            notifier.setOpenaiBaseUrl(urlController.text.trim());
            notifier.setOpenaiApiKey(keyController.text.trim());
            notifier.setOpenaiModel(
              modelController.text.trim().isNotEmpty
                  ? modelController.text.trim()
                  : 'gpt-4o-mini',
            );
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final confirmed = await AppDialog.show<bool>(
      context: context,
      title: 'Clear Cache',
      maxWidth: 380,
      child: const Text('Delete all saved offline translations?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear'),
        ),
      ],
    );

    if (confirmed == true) {
      await SubtitleCacheService.clearAllCache();
      await _loadCacheSize();
    }
  }
}
