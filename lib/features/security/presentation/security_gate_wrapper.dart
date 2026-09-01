import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/security/presentation/app_lock_screen.dart';
import 'package:shonenx/shared/providers/app_lock_provider.dart';

class SecurityGateWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const SecurityGateWrapper({super.key, required this.child});

  @override
  ConsumerState<SecurityGateWrapper> createState() =>
      _SecurityGateWrapperState();
}

class _SecurityGateWrapperState extends ConsumerState<SecurityGateWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        ref.read(appLockProvider.notifier).recordPaused();
        break;
      case AppLifecycleState.resumed:
        ref.read(appLockProvider.notifier).checkAndLockOnResume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: lockState.isLocked
          ? const AppLockScreen(key: ValueKey('app_lock_screen'))
          : KeyedSubtree(
              key: const ValueKey('app_main_content'),
              child: widget.child,
            ),
    );
  }
}
