import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

enum AppCardPosition { single, first, middle, last }

extension AppCardPositionRadius on AppCardPosition {
  BorderRadius get expressiveRadius {
    const outer = Radius.circular(24.0);
    const inner = Radius.circular(8.0);
    return switch (this) {
      AppCardPosition.single => const BorderRadius.all(outer),
      AppCardPosition.first => const BorderRadius.vertical(
        top: outer,
        bottom: inner,
      ),
      AppCardPosition.middle => const BorderRadius.all(inner),
      AppCardPosition.last => const BorderRadius.vertical(
        top: inner,
        bottom: outer,
      ),
    };
  }
}

class AppCardScope extends InheritedWidget {
  final SettingsStyle style;
  final AppCardPosition position;

  const AppCardScope({
    super.key,
    required this.style,
    required this.position,
    required super.child,
  });

  static AppCardScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppCardScope>();

  static BorderRadius radiusOf(BuildContext context, {bool pressed = false}) {
    final scope = maybeOf(context);
    if (scope?.style == SettingsStyle.classic) {
      return BorderRadius.circular(10.0);
    }
    if (pressed) return BorderRadius.circular(24.0);
    return (scope?.position ?? AppCardPosition.single).expressiveRadius;
  }

  @override
  bool updateShouldNotify(AppCardScope oldWidget) =>
      style != oldWidget.style || position != oldWidget.position;
}

/// Groups a list of cards/tiles with M3 Expressive connected radii & 3px gaps
/// in [SettingsStyle.expressive], or clean compact rows in [SettingsStyle.classic].
class AppCardGroup extends ConsumerWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AppCardGroup({super.key, required this.children, this.padding});

  AppCardPosition _positionOf(int index) {
    if (children.length == 1) return AppCardPosition.single;
    if (index == 0) return AppCardPosition.first;
    if (index == children.length - 1) return AppCardPosition.last;
    return AppCardPosition.middle;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (children.isEmpty) return const SizedBox.shrink();
    final style = ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding:
          padding ??
          (isClassic
              ? const EdgeInsets.symmetric(horizontal: 10)
              : const EdgeInsets.symmetric(horizontal: 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              isClassic
                  ? Divider(
                      height: 1,
                      indent: 64,
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    )
                  : const SizedBox(height: 3.0),
            AppCardScope(
              style: style,
              position: _positionOf(i),
              child: children[i],
            ),
          ],
        ],
      ),
    );
  }
}

/// Interactive surface container that inherits [AppCardScope] radius & style.
class AppCardSurface extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const AppCardSurface({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.color,
    this.padding,
  });

  @override
  ConsumerState<AppCardSurface> createState() => _AppCardSurfaceState();
}

class _AppCardSurfaceState extends ConsumerState<AppCardSurface> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scope = AppCardScope.maybeOf(context);
    final style =
        scope?.style ??
        ref.watch(uiPrefsProvider.select((s) => s.settingsStyle));
    final isClassic = style == SettingsStyle.classic;

    final radius = isClassic
        ? BorderRadius.circular(10.0)
        : (_pressed
              ? BorderRadius.circular(24.0)
              : (scope?.position ?? AppCardPosition.single).expressiveRadius);

    final base = isClassic
        ? (widget.color ?? Colors.transparent)
        : (widget.color ?? cs.surfaceContainerHigh);
    final overlay = _pressed ? 0.12 : (_hovered ? 0.08 : 0.0);
    final fill = overlay == 0
        ? base
        : (base == Colors.transparent
              ? cs.onSurface.withValues(alpha: overlay)
              : Color.alphaBlend(cs.onSurface.withValues(alpha: overlay), base));

    final body = widget.padding != null
        ? Padding(padding: widget.padding!, child: widget.child)
        : widget.child;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(color: fill, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        child: widget.onTap == null && widget.onLongPress == null
            ? body
            : InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                borderRadius: radius,
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                onHighlightChanged: (v) => setState(() => _pressed = v),
                onHover: (v) => setState(() => _hovered = v),
                child: body,
              ),
      ),
    );
  }
}

