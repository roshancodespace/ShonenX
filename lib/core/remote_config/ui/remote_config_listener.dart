import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/remote_config/providers/remote_config_provider.dart';
import 'package:shonenx/core/remote_config/ui/remote_config_ui.dart';

class RemoteConfigListener extends ConsumerWidget {
  final Widget child;

  const RemoteConfigListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(remoteConfigStateProvider);
    final config = configAsync.value;

    if (config != null && !config.applicationEnabled) {
      return RemoteConfigUI.buildApplicationDisabledScreen(context);
    }

    return child;
  }
}
