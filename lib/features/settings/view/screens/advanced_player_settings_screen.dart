import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/settings/view/widgets/settings_section.dart';
import 'package:shonenx/features/settings/view_model/player_notifier.dart';
import 'package:shonenx/features/settings/view/widgets/settings_item.dart';

class AdvancedPlayerSettingsScreen extends ConsumerStatefulWidget {
  const AdvancedPlayerSettingsScreen({super.key});

  @override
  ConsumerState<AdvancedPlayerSettingsScreen> createState() =>
      _AdvancedPlayerSettingsScreenState();
}

class _AdvancedPlayerSettingsScreenState
    extends ConsumerState<AdvancedPlayerSettingsScreen> {
  late TextEditingController _controller;
  final Map<String, String> _currentMap = {};

  @override
  void initState() {
    super.initState();
    final settings = ref.read(playerSettingsProvider);
    _currentMap.addAll(settings.mpvSettings);
    _controller = TextEditingController(text: _textFromMap());
    _controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChange);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChange() {}

  String _textFromMap() {
    return _currentMap.entries.map((e) => '${e.key}=${e.value}').join('\n');
  }

  void _syncMapToText() {
    final text = _textFromMap();
    if (_controller.text != text) {
      _controller.text = text;
    }
  }

  void _updateKey(String key, String? value) {
    setState(() {
      if (value == null || value.isEmpty || value == 'null') {
        _currentMap.remove(key);
      } else {
        _currentMap[key] = value;
      }
      _syncMapToText();
    });
  }

  void _save() {
    final text = _controller.text;
    final map = <String, String>{};
    const splitter = LineSplitter();
    for (final line in splitter.convert(text)) {
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      final parts = line.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        if (key.isNotEmpty) {
          map[key] = value;
        }
      }
    }

    ref
        .read(playerSettingsProvider.notifier)
        .updateSettings((prev) => prev.copyWith(mpvSettings: map));

    context.pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved. If not applied restart app.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton.filledTonal(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        title: const Text('Settings'),
        forceMaterialTransparency: true,
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save'),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          children: [
            SettingsSection(
              title: 'Common Configuration',
              titleColor: colorScheme.primary,
              children: [
                DropdownSettingsItem(
                  title: 'Hardware Decoding',
                  description: 'hwdec',
                  icon: Icon(Icons.memory, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  value: _currentMap['hwdec'] ?? 'auto',
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Auto')),
                    DropdownMenuItem(
                      value: 'no',
                      child: Text('Disabled (Software)'),
                    ),
                    DropdownMenuItem(
                      value: 'mediacodec',
                      child: Text('MediaCodec'),
                    ),
                    DropdownMenuItem(
                      value: 'mediacodec-copy',
                      child: Text('MediaCodec (Copy)'),
                    ),
                  ],
                  onChanged: (v) => _updateKey('hwdec', v),
                ),
                DropdownSettingsItem(
                  title: 'Video Output',
                  description: 'vo',
                  icon: Icon(Icons.monitor, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  value: _currentMap['vo'] ?? 'gpu',
                  items: const [
                    DropdownMenuItem(value: 'gpu', child: Text('GPU')),
                    DropdownMenuItem(
                      value: 'null',
                      child: Text('Null (No Video)'),
                    ),
                  ],
                  onChanged: (v) => _updateKey('vo', v),
                ),
                DropdownSettingsItem(
                  title: 'GPU Context',
                  description: 'gpu-context',
                  icon: Icon(
                    Icons.settings_system_daydream,
                    color: colorScheme.primary,
                  ),
                  accent: colorScheme.primary,
                  value: _currentMap['gpu-context'] ?? 'auto',
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Auto')),
                    DropdownMenuItem(value: 'android', child: Text('Android')),
                    DropdownMenuItem(value: 'wayland', child: Text('Wayland')),
                    DropdownMenuItem(value: 'x11', child: Text('X11')),
                  ],
                  onChanged: (v) => _updateKey('gpu-context', v),
                ),
                DropdownSettingsItem(
                  title: 'Quality Profile',
                  description: 'profile',
                  icon: Icon(Icons.high_quality, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  value: _currentMap['profile'] ?? 'fast',
                  items: const [
                    DropdownMenuItem(
                      value: 'fast',
                      child: Text('Fast (Recommended)'),
                    ),
                    DropdownMenuItem(
                      value: 'high-quality',
                      child: Text('High Quality'),
                    ),
                    DropdownMenuItem(value: 'gpu-hq', child: Text('GPU HQ')),
                  ],
                  onChanged: (v) => _updateKey('profile', v),
                ),
                ToggleableSettingsItem(
                  title: 'Debanding',
                  description: 'deband',
                  icon: Icon(Icons.blur_linear, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  value: _currentMap['deband'] == 'yes',
                  onChanged: (v) => _updateKey('deband', v ? 'yes' : 'no'),
                ),
                ToggleableSettingsItem(
                  title: 'Interpolation',
                  description: 'interpolation (smooth motion)',
                  icon: Icon(Icons.animation, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  value: _currentMap['interpolation'] == 'yes',
                  onChanged: (v) =>
                      _updateKey('interpolation', v ? 'yes' : 'no'),
                ),
                DropdownSettingsItem(
                  title: 'Upscaling Algorithm',
                  description: 'scale',
                  icon: Icon(Icons.aspect_ratio, color: colorScheme.primary),
                  accent: colorScheme.primary,
                  value: _currentMap['scale'] ?? 'bilinear',
                  items: const [
                    DropdownMenuItem(
                      value: 'bilinear',
                      child: Text('Bilinear (Fast)'),
                    ),
                    DropdownMenuItem(
                      value: 'spline36',
                      child: Text('Spline36'),
                    ),
                    DropdownMenuItem(value: 'lanczos', child: Text('Lanczos')),
                    DropdownMenuItem(
                      value: 'ewa_lanczossharp',
                      child: Text('EWA Lanczos Sharp'),
                    ),
                  ],
                  onChanged: (v) => _updateKey('scale', v),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SettingsSection(
              title: 'Raw Configuration',
              titleColor: colorScheme.primary,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.errorContainer.withOpacity(0.5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Warning: Incorrect settings may cause instability. Use "key=value" format.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _controller,
                    minLines: 5,
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'hwdec=auto\nvo=gpu',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                    onChanged: (value) {
                      const splitter = LineSplitter();
                      for (final line in splitter.convert(value)) {
                        final parts = line.split('=');
                        if (parts.length >= 2) {
                          final k = parts[0].trim();
                          final v = parts.sublist(1).join('=').trim();
                          if (_currentMap.containsKey(k) &&
                              _currentMap[k] != v) {
                            setState(() {
                              _currentMap[k] = v;
                            });
                          }
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
