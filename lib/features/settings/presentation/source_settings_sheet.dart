import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/providers/source_settings_provider.dart';

class SourceSettingsSheet extends ConsumerWidget {
  final SourceInfo source;
  final List<SourceSetting> schema;

  const SourceSettingsSheet({
    super.key,
    required this.source,
    required this.schema,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsMap = ref.watch(sourceSettingsProvider(source.id));
    final notifier = ref.read(sourceSettingsProvider(source.id).notifier);

    return AppBottomSheet(
      title: '${source.name} Settings',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: schema.length,
              itemBuilder: (context, index) {
                final setting = schema[index];
                final currentValue =
                    settingsMap[setting.id] ?? setting.defaultValue;

                if (setting.isBoolean) {
                  return SettingsSwitchTile(
                    icon: Icons.toggle_on_outlined,
                    title: setting.name,
                    subtitle: setting.description,
                    value: currentValue as bool? ?? false,
                    onChanged: (val) {
                      notifier.updateSetting(setting.id, val);
                    },
                  );
                } else if (setting.isSelect) {
                  return SettingsActionTile(
                    icon: Icons.list_alt_rounded,
                    title: setting.name,
                    subtitle: currentValue?.toString() ?? 'Default',
                    onTap: () {
                      _showSelectSheet(
                        context,
                        title: setting.name,
                        options: setting.options ?? [],
                        currentValue: currentValue?.toString() ?? '',
                        onChanged: (val) {
                          notifier.updateSetting(setting.id, val);
                        },
                      );
                    },
                  );
                } else if (setting.isText) {
                  return SettingsActionTile(
                    icon: Icons.text_fields_rounded,
                    title: setting.name,
                    subtitle: currentValue?.toString() ?? setting.description,
                    onTap: () {
                      _showTextEditSheet(
                        context,
                        title: setting.name,
                        currentValue: currentValue?.toString() ?? '',
                        onChanged: (val) {
                          notifier.updateSetting(setting.id, val);
                        },
                      );
                    },
                  );
                } else if (setting.isMultiSelect) {
                  final List<String> currentList =
                      (currentValue as List<dynamic>?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      [];

                  return SettingsActionTile(
                    icon: Icons.checklist_rtl_rounded,
                    title: setting.name,
                    subtitle: currentList.isEmpty
                        ? 'None'
                        : currentList.join(', '),
                    onTap: () {
                      _showMultiSelectSheet(
                        context,
                        title: setting.name,
                        options: setting.options ?? [],
                        currentValues: currentList,
                        onChanged: (val) {
                          notifier.updateSetting(setting.id, val);
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSelectSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              ...options.map((option) {
                final isSelected = option == currentValue;
                return ListTile(
                  title: Text(option),
                  trailing: isSelected ? const Icon(Icons.check) : null,
                  onTap: () {
                    onChanged(option);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showTextEditSheet(
    BuildContext context, {
    required String title,
    required String currentValue,
    required ValueChanged<String> onChanged,
  }) {
    final controller = TextEditingController(text: currentValue);
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
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
            ),
          ),
        );
      },
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  ...options.map((option) {
                    final isSelected = selected.contains(option);
                    return CheckboxListTile(
                      title: Text(option),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            selected.add(option);
                          } else {
                            // Enforce at least 1 selection if user unchecks the last one
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
                  }),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        onChanged(selected);
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
