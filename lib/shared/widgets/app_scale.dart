import 'package:flutter/widgets.dart';

class AppScaleScope extends InheritedWidget {
  final double scale;

  const AppScaleScope({
    super.key,
    required this.scale,
    required super.child,
  });

  static double of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppScaleScope>()
            ?.scale ??
        1.0;
  }

  @override
  bool updateShouldNotify(AppScaleScope oldWidget) =>
      oldWidget.scale != scale;
}

class AppScale extends StatelessWidget {
  final double scale;
  final Widget child;

  const AppScale({
    super.key,
    required this.scale,
    required this.child,
  });

  double _autoScale(MediaQueryData data) {
    final dpr = data.devicePixelRatio;
    final physicalWidth = data.size.width * dpr;
    final physicalHeight = data.size.height * dpr;
    final physicalLongest =
        physicalWidth > physicalHeight ? physicalWidth : physicalHeight;
    final physicalShortest =
        physicalWidth > physicalHeight ? physicalHeight : physicalWidth;

    if (physicalLongest >= 3840 && physicalShortest >= 2160) {
      return 0.5;
    }

    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final autoScale = _autoScale(mediaQuery);
    final effectiveScale = (scale * autoScale).clamp(0.5, 1.0) as double;
    final scaledText = TextScaler.linear(
      mediaQuery.textScaler.textScaleFactor * effectiveScale,
    );

    return AppScaleScope(
      scale: effectiveScale,
      child: MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: scaledText,
          navigationMode: NavigationMode.directional,
        ),
        child: child,
      ),
    );
  }
}
