import 'package:flutter/material.dart';

enum SheetPhysicsMode {
  hammer(displayName: 'Hammer', icon: Icons.gavel_rounded),
  slideUp(displayName: 'Slide Up', icon: Icons.swipe_up_rounded);

  final String displayName;
  final IconData icon;

  const SheetPhysicsMode({required this.displayName, required this.icon});

  bool get hasTilt => this == SheetPhysicsMode.hammer;

  double get initialTilt => hasTilt ? 0.32 : 0.0;

  AnimationStyle get sheetAnimationStyle {
    switch (this) {
      case SheetPhysicsMode.hammer:
        return const AnimationStyle(
          duration: Duration(milliseconds: 380),
          reverseDuration: Duration(milliseconds: 280),
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInCubic,
        );
      case SheetPhysicsMode.slideUp:
        return const AnimationStyle(
          duration: Duration(milliseconds: 320),
          reverseDuration: Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
    }
  }

  static SheetPhysicsMode fromJson(String? value) {
    if (value == null) return SheetPhysicsMode.hammer;
    return SheetPhysicsMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SheetPhysicsMode.slideUp,
    );
  }
}
