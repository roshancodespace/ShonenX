import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/features/anime/view_model/player_provider.dart';

class SettingsSheetContent extends ConsumerWidget {
  final VoidCallback onDismiss;
  const SettingsSheetContent({super.key, required this.onDismiss});

  void _showDialog(
    BuildContext context, {
    required Widget Function(BuildContext) builder,
  }) {
    showDialog(context: context, builder: builder).then((_) {
      if (!context.mounted) return;
      if (Navigator.of(context).canPop()) onDismiss();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Settings", style: Theme.of(context).textTheme.headlineSmall),
            const Divider(height: 24),
            ListTile(
              leading: const Icon(Iconsax.speedometer),
              title: const Text("Playback Speed"),
              trailing: Text(
                "${ref.watch(playerStateProvider.select((p) => p.playbackSpeed))}x",
              ),
              onTap: () =>
                  _showDialog(context, builder: (ctx) => const SpeedDialog()),
            ),
            ListTile(
              leading: const Icon(Iconsax.crop),
              title: const Text("Video Fit"),
              trailing: Text(
                _fitModeToString(
                  ref.watch(playerStateProvider.select((p) => p.fit)),
                ),
              ),
              onTap: () =>
                  _showDialog(context, builder: (ctx) => const FitDialog()),
            ),
          ],
        ),
      ),
    );
  }
}

class SpeedDialog extends ConsumerStatefulWidget {
  const SpeedDialog({super.key});

  @override
  ConsumerState<SpeedDialog> createState() => _SpeedDialogState();
}

class _SpeedDialogState extends ConsumerState<SpeedDialog> {
  late double _selectedSpeed;

  @override
  void initState() {
    super.initState();
    _selectedSpeed = ref.read(playerStateProvider).playbackSpeed;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Playback Speed"),
      content: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children: [0.5, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
            .map(
              (speed) => ChoiceChip(
                label: Text("${speed}x"),
                selected: _selectedSpeed == speed,
                onSelected: (isSelected) {
                  if (isSelected) setState(() => _selectedSpeed = speed);
                },
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            ref.read(playerStateProvider.notifier).setSpeed(_selectedSpeed);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}

class FitDialog extends ConsumerStatefulWidget {
  const FitDialog({super.key});

  @override
  ConsumerState<FitDialog> createState() => _FitDialogState();
}

class _FitDialogState extends ConsumerState<FitDialog> {
  late BoxFit _selectedFit;
  static const fitModes = [BoxFit.contain, BoxFit.cover, BoxFit.fill];

  @override
  void initState() {
    super.initState();
    _selectedFit = ref.read(playerStateProvider).fit;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Video Fit"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: fitModes
            .map(
              (fit) => RadioListTile<BoxFit>(
                title: Text(_fitModeToString(fit)),
                value: fit,
                groupValue: _selectedFit,
                onChanged: (value) {
                  if (value != null) setState(() => _selectedFit = value);
                },
              ),
            )
            .toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            ref.read(playerStateProvider.notifier).setFit(_selectedFit);
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
    );
  }
}

String _fitModeToString(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'Contain';
    case BoxFit.cover:
      return 'Cover';
    case BoxFit.fill:
      return 'Fill';
    default:
      return 'Fit';
  }
}
