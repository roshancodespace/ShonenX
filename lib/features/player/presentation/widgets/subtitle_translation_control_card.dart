import 'package:flutter/material.dart';
import 'package:shonenx/features/player/domain/subtitle_translation_models.dart';
import 'package:shonenx/features/player/providers/subtitle_translation_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class SubtitleTranslationControlCard extends StatelessWidget {
  final RuntimeTranslationState translationState;
  final SubtitleTranslationConfig translationConfig;
  final bool hasActiveSub;
  final ValueChanged<String> onSelectTargetLanguage;
  final VoidCallback onDisableTranslation;
  final VoidCallback onOpenSettings;

  const SubtitleTranslationControlCard({
    super.key,
    required this.translationState,
    required this.translationConfig,
    required this.hasActiveSub,
    required this.onSelectTargetLanguage,
    required this.onDisableTranslation,
    required this.onOpenSettings,
  });

  String _getLanguageDisplayName(String? code) {
    if (code == null) return 'Off';
    return kSupportedSubtitleLanguages[code] ?? code.toUpperCase();
  }

  void _showLanguagePicker(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Target Language',
      titleIcon: Icons.language_rounded,
      child: _QuickLanguagePicker(
        selectedLang: translationState.targetLanguage ??
            translationConfig.defaultTargetLanguage,
        onSelect: (code) {
          Navigator.pop(context);
          onSelectTargetLanguage(code);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTranslating = translationState.isTranslating;
    final isTranslated = translationState.isEnabled &&
        translationState.translatedCues != null &&
        !isTranslating;
    final targetLang = translationState.targetLanguage ??
        translationConfig.defaultTargetLanguage;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isTranslated
            ? cs.primary.withValues(alpha: 0.08)
            : cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(
              Icons.translate_rounded,
              size: 20,
              color: isTranslated ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text(
              isTranslating
                  ? 'Translating (${(translationState.progress * 100).toInt()}%)...'
                  : (isTranslated
                      ? 'Translated (${_getLanguageDisplayName(targetLang)})'
                      : 'Translate Subtitles'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isTranslated ? FontWeight.w600 : FontWeight.w500,
                color: isTranslated ? cs.primary : cs.onSurface,
              ),
            ),
            subtitle: isTranslating && translationState.activeProviderName != null
                ? Text(
                    'Via ${translationState.activeProviderName}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  )
                : (translationState.error != null && !isTranslating
                    ? Text(
                        'Failed: ${translationState.error}',
                        style: TextStyle(fontSize: 11, color: cs.error),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTranslated)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    tooltip: 'Revert to original',
                    visualDensity: VisualDensity.compact,
                    onPressed: onDisableTranslation,
                  ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: hasActiveSub ? () => _showLanguagePicker(context) : null,
                  child: Text(
                    isTranslated
                        ? 'Change'
                        : (hasActiveSub
                            ? _getLanguageDisplayName(targetLang)
                            : 'No track'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  tooltip: 'Settings',
                  visualDensity: VisualDensity.compact,
                  onPressed: onOpenSettings,
                ),
              ],
            ),
          ),
          if (isTranslating)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: translationState.progress > 0
                      ? translationState.progress
                      : null,
                  minHeight: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickLanguagePicker extends StatefulWidget {
  final String selectedLang;
  final ValueChanged<String> onSelect;

  const _QuickLanguagePicker({
    required this.selectedLang,
    required this.onSelect,
  });

  @override
  State<_QuickLanguagePicker> createState() => _QuickLanguagePickerState();
}

class _QuickLanguagePickerState extends State<_QuickLanguagePicker> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final filtered = kSupportedSubtitleLanguages.entries.where((e) {
      if (_filter.isEmpty) return true;
      final q = _filter.toLowerCase();
      return e.key.toLowerCase().contains(q) ||
          e.value.toLowerCase().contains(q);
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search languages...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => setState(() => _filter = val),
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final entry = filtered[index];
              final isSelected = entry.key == widget.selectedLang;

              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: cs.primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                title: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
                onTap: () => widget.onSelect(entry.key),
              );
            },
          ),
        ),
      ],
    );
  }
}
