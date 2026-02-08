import 'package:dartotsu_extension_bridge/dartotsu_extension_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExtensionPreferenceScreen extends ConsumerStatefulWidget {
  final Source source;
  const ExtensionPreferenceScreen({super.key, required this.source});

  @override
  ConsumerState<ExtensionPreferenceScreen> createState() =>
      _ExtensionPreferenceScreenState();
}

class _ExtensionPreferenceScreenState
    extends ConsumerState<ExtensionPreferenceScreen> {
  List<SourcePreference> _preferences = [];

  @override
  void initState() {
    super.initState();
    _getPreferences();
  }

  Future<void> _getPreferences() async {
    final res = await widget.source.methods.getPreference();
    setState(() {
      _preferences = res;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.source.name ?? "Unknown")),
      body: ListView(
        children: [
          ..._preferences.map((e) {
            Widget titleText(String text) {
              return Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            }

            Widget subtitleText(String text) {
              return Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            }

            switch (e.type) {
              case 'checkBox':
                return CheckboxListTile(
                  title: titleText(e.checkBoxPreference!.title ?? ""),
                  subtitle: subtitleText(e.checkBoxPreference!.summary ?? ""),
                  value: e.checkBoxPreference!.value,
                  onChanged: (value) {
                    setState(() {
                      e.checkBoxPreference!.value = value!;
                    });
                    widget.source.methods.setPreference(e, value!);
                  },
                );
              case 'switch':
                return SwitchListTile(
                  title: titleText(e.switchPreferenceCompat!.title ?? ""),
                  subtitle: subtitleText(
                    e.switchPreferenceCompat!.summary ?? "",
                  ),
                  value: e.switchPreferenceCompat!.value ?? false,
                  onChanged: (value) {
                    setState(() {
                      e.switchPreferenceCompat!.value = value;
                    });
                    widget.source.methods.setPreference(e, value);
                  },
                );
              case 'list':
                final pref = e.listPreference!;
                final currentValueIndex = pref.valueIndex ?? 0;
                final entries = pref.entries ?? [];

                String summary = pref.summary ?? "";
                if (currentValueIndex >= 0 &&
                    currentValueIndex < entries.length) {
                  if (summary.contains("%s")) {
                    summary = summary.replaceAll(
                      "%s",
                      entries[currentValueIndex],
                    );
                  } else {
                    summary = entries[currentValueIndex];
                  }
                }

                return ListTile(
                  title: titleText(pref.title ?? ""),
                  subtitle: subtitleText(summary),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(pref.title ?? ""),
                          content: SingleChildScrollView(
                            child: RadioGroup<int>(
                              groupValue: pref.valueIndex,
                              onChanged: (value) {
                                Navigator.pop(context);
                                if (value != null) {
                                  setState(() {
                                    pref.valueIndex = value;
                                  });
                                  widget.source.methods.setPreference(
                                    e,
                                    pref.entryValues![value],
                                  );
                                }
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(entries.length, (
                                  index,
                                ) {
                                  return RadioListTile<int>(
                                    title: Text(entries[index]),
                                    value: index,
                                  );
                                }),
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              case 'multi_select':
                final pref = e.multiSelectListPreference!;
                final entries = pref.entries ?? [];
                final entryValues = pref.entryValues ?? [];
                final selectedValues = (pref.values ?? []).toSet();

                return ListTile(
                  title: titleText(pref.title ?? ""),
                  subtitle: subtitleText(pref.summary ?? ""),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(
                          builder: (context, setStateDialog) {
                            return AlertDialog(
                              title: Text(pref.title ?? ""),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(entries.length, (
                                    index,
                                  ) {
                                    final value = entryValues[index];
                                    final isSelected = selectedValues.contains(
                                      value,
                                    );
                                    return CheckboxListTile(
                                      title: Text(entries[index]),
                                      value: isSelected,
                                      onChanged: (checked) {
                                        setStateDialog(() {
                                          if (checked == true) {
                                            selectedValues.add(value);
                                          } else {
                                            selectedValues.remove(value);
                                          }
                                        });
                                      },
                                    );
                                  }),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    final newList = selectedValues.toList();
                                    setState(() {
                                      pref.values = newList;
                                    });
                                    widget.source.methods.setPreference(
                                      e,
                                      newList,
                                    );
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              case 'text':
                final pref = e.editTextPreference!;
                return ListTile(
                  title: titleText(pref.title ?? ""),
                  subtitle: subtitleText(pref.summary ?? ""),
                  onTap: () {
                    final controller = TextEditingController(text: pref.text);
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(pref.dialogTitle ?? pref.title ?? "Edit"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (pref.dialogMessage != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(pref.dialogMessage!),
                                ),
                              TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                final newValue = controller.text;
                                setState(() {
                                  pref.text = newValue;
                                });
                                widget.source.methods.setPreference(
                                  e,
                                  newValue,
                                );
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              default:
                return const SizedBox.shrink();
            }
          }),
        ],
      ),
    );
  }
}
