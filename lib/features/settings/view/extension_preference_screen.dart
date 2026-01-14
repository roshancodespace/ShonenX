import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core_new/eval/model/source_preference.dart';
import 'package:shonenx/core_new/models/source.dart';
import 'package:shonenx/core_new/providers/extension_preference_provider.dart';
import 'package:shonenx/core_new/providers/get_source_preference.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/main.dart';
import 'package:isar_community/isar.dart';

final sourcePreferencesStreamProvider = StreamProvider.autoDispose
    .family<void, int>((ref, sourceId) {
      return isar.sourcePreferences
          .filter()
          .sourceIdEqualTo(sourceId)
          .watchLazy();
    });

class ExtensionPreferenceScreen extends ConsumerWidget {
  final Source source;

  const ExtensionPreferenceScreen({super.key, required this.source});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sourcePreferencesStreamProvider(source.id!));
    final extPrefs = getSourcePreference(
      source: source,
    ).map((e) => getSourcePreferenceEntry(e.key!, source.id!)).toList();

    final theme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
          style: IconButton.styleFrom(
            backgroundColor: theme.primary.withOpacity(0.1),
            foregroundColor: theme.primary,
          ),
        ),
        title: Text(
          '${source.name} Preferences',
          style: TextStyle(fontWeight: FontWeight.bold, color: theme.onSurface),
        ),
        forceMaterialTransparency: true,
      ),
      body: extPrefs.isEmpty
          ? _buildEmptyState(context, theme)
          : _buildPreferencesList(context, extPrefs, theme),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Iconsax.setting_2, size: 40, color: theme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No Settings Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This extension doesn\'t have any configurable preferences.',
            style: TextStyle(
              fontSize: 14,
              color: theme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesList(
    BuildContext context,
    List<SourcePreference> extPrefs,
    ColorScheme theme,
  ) {
    final Map<String, List<SourcePreference>> groupedPrefs = _groupPreferences(
      extPrefs,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: groupedPrefs.entries.map((entry) {
          final categoryName = entry.key;
          final preferences = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: SettingsSection(
              title: categoryName,
              titleColor: theme.primary,
              roundness: 16,
              children: preferences
                  .map((pref) => _buildSettingsItem(context, pref, theme))
                  .toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<SourcePreference>> _groupPreferences(
    List<SourcePreference> prefs,
  ) {
    return {'General': prefs};
  }

  BaseSettingsItem _buildSettingsItem(
    BuildContext context,
    SourcePreference preference,
    ColorScheme theme,
  ) {
    if (preference.editTextPreference != null) {
      return _buildEditTextSettingsItem(
        context,
        preference,
        preference.editTextPreference!,
        theme,
      );
    } else if (preference.checkBoxPreference != null) {
      return _buildCheckBoxSettingsItem(
        context,
        preference,
        preference.checkBoxPreference!,
        theme,
      );
    } else if (preference.switchPreferenceCompat != null) {
      return _buildSwitchSettingsItem(
        context,
        preference,
        preference.switchPreferenceCompat!,
        theme,
      );
    } else if (preference.listPreference != null) {
      return _buildListSettingsItem(
        context,
        preference,
        preference.listPreference!,
        theme,
      );
    } else if (preference.multiSelectListPreference != null) {
      return _buildMultiSelectSettingsItem(
        context,
        preference,
        preference.multiSelectListPreference!,
        theme,
      );
    }

    // Fallback for unknown preference types
    return NormalSettingsItem(
      icon: const Icon(Iconsax.setting),
      accent: theme.primary,
      title: 'Unknown Setting',
      description: 'This setting type is not supported yet.',
    );
  }

  NormalSettingsItem _buildEditTextSettingsItem(
    BuildContext context,
    SourcePreference preference,
    EditTextPreference pref,
    ColorScheme theme,
  ) {
    return NormalSettingsItem(
      icon: const Icon(Iconsax.edit),
      accent: theme.primary,
      title: pref.title ?? 'Text Setting',
      description: pref.summary ?? 'Tap to edit text value',
      onTap: () => _showEditTextDialog(context, preference, pref),
    );
  }

  ToggleableSettingsItem _buildCheckBoxSettingsItem(
    BuildContext context,
    SourcePreference preference,
    CheckBoxPreference pref,
    ColorScheme theme,
  ) {
    return ToggleableSettingsItem(
      icon: const Icon(Iconsax.tick_square),
      accent: theme.primary,
      title: pref.title ?? 'Checkbox Setting',
      description: pref.summary ?? 'Toggle this option',
      value: pref.value ?? false,
      onChanged: (value) {
        pref.value = value;
        setPreferenceSetting(preference, source);
      },
    );
  }

  ToggleableSettingsItem _buildSwitchSettingsItem(
    BuildContext context,
    SourcePreference preference,
    SwitchPreferenceCompat pref,
    ColorScheme theme,
  ) {
    return ToggleableSettingsItem(
      icon: const Icon(Iconsax.toggle_on),
      accent: theme.primary,
      title: pref.title ?? 'Switch Setting',
      description: pref.summary ?? 'Toggle this switch',
      value: pref.value ?? false,
      onChanged: (value) {
        pref.value = value;
        setPreferenceSetting(preference, source);
      },
    );
  }

  DropdownSettingsItem _buildListSettingsItem(
    BuildContext context,
    SourcePreference preference,
    ListPreference pref,
    ColorScheme theme,
  ) {
    final currentValue =
        pref.valueIndex != null &&
            pref.entries != null &&
            pref.valueIndex! < pref.entries!.length
        ? pref.entries![pref.valueIndex!]
        : 'Select option';

    return DropdownSettingsItem(
      icon: const Icon(Iconsax.menu_1),
      accent: theme.primary,
      title: pref.title ?? 'List Setting',
      description: 'Current: $currentValue',
      layoutType: SettingsItemLayout.horizontal,
      value: currentValue,
      items: (pref.entries ?? []).map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: (value) {
        if (value != null && pref.entries != null) {
          final index = pref.entries!.indexOf(value);
          if (index != -1) {
            pref.valueIndex = index;
            setPreferenceSetting(preference, source);
          }
        }
      },
    );
  }

  NormalSettingsItem _buildMultiSelectSettingsItem(
    BuildContext context,
    SourcePreference preference,
    MultiSelectListPreference pref,
    ColorScheme theme,
  ) {
    final selectedCount = pref.values?.length ?? 0;
    final totalCount = pref.entries?.length ?? 0;

    return NormalSettingsItem(
      icon: const Icon(Iconsax.tick_circle),
      accent: theme.primary,
      title: pref.title ?? 'Multi-Select Setting',
      description: '$selectedCount of $totalCount selected',
      onTap: () => _showMultiSelectDialog(context, preference, pref),
    );
  }

  Future<void> _showEditTextDialog(
    BuildContext context,
    SourcePreference preference,
    EditTextPreference pref,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => ModernEditTextDialog(
        text: pref.value ?? '',
        onChanged: (value) {
          pref.value = value;
          setPreferenceSetting(preference, source);
        },
        dialogTitle: pref.dialogTitle ?? pref.title ?? 'Edit Text',
        dialogMessage: pref.dialogMessage ?? pref.summary ?? '',
      ),
    );
  }

  void _showMultiSelectDialog(
    BuildContext context,
    SourcePreference preference,
    MultiSelectListPreference pref,
  ) {
    List<String> indexList = List.from(pref.values ?? []);
    final theme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: theme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                pref.title ?? 'Multi-Select',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.onSurface,
                ),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pref.entries?.length ?? 0,
                  itemBuilder: (context, index) {
                    if (pref.entries == null || index >= pref.entries!.length) {
                      return const SizedBox.shrink();
                    }

                    final isSelected = indexList.contains(
                      pref.entryValues?[index],
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.primary.withOpacity(0.3)
                              : theme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: CheckboxListTile(
                        value: isSelected,
                        title: Text(
                          pref.entries![index],
                          style: TextStyle(
                            color: theme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        activeColor: theme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (pref.entryValues != null &&
                                index < pref.entryValues!.length) {
                              if (indexList.contains(
                                pref.entryValues![index],
                              )) {
                                indexList.remove(pref.entryValues![index]);
                              } else {
                                indexList.add(pref.entryValues![index]);
                              }
                              pref.values = indexList;
                            }
                          });
                          setPreferenceSetting(preference, source);
                        },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close', style: TextStyle(color: theme.primary)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ModernEditTextDialog extends StatefulWidget {
  final String text;
  final String dialogTitle;
  final String dialogMessage;
  final Function(String) onChanged;

  const ModernEditTextDialog({
    super.key,
    required this.text,
    required this.onChanged,
    required this.dialogTitle,
    required this.dialogMessage,
  });

  @override
  State<ModernEditTextDialog> createState() => _ModernEditTextDialogState();
}

class _ModernEditTextDialogState extends State<ModernEditTextDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: theme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.dialogTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.onSurface,
            ),
          ),
          if (widget.dialogMessage.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.dialogMessage,
              style: TextStyle(
                fontSize: 14,
                color: theme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ],
      ),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.outline.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: theme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(color: theme.onSurface),
        maxLines: null,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: theme.onSurface.withOpacity(0.6)),
          ),
        ),
        FilledButton(
          onPressed: () {
            widget.onChanged(_controller.text);
            Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: theme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
