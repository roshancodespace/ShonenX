import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';

class NavBarThemeData {
  // Bar Container
  final double? blurSigma;
  final BoxDecoration barDecoration;
  final double Function(double size)
  barRadius; // Takes the height/width of the bar

  // Item active/inactive colors
  final Color activeIconColor;
  final Color inactiveIconColor;
  final Color activeTextColor;

  // Item background
  final BoxDecoration activeItemDecoration;
  final BoxDecoration inactiveItemDecoration;
  final double Function(double size) itemRadius;

  // Minimal style special properties
  final bool showDotIndicator;
  final bool isMaterial3;

  // Animations
  final double activeScale;

  // Download button specifics
  final BoxDecoration downloadButtonDecoration;
  final Color downloadIconColor;

  const NavBarThemeData({
    this.blurSigma,
    required this.barDecoration,
    required this.barRadius,
    required this.activeIconColor,
    required this.inactiveIconColor,
    required this.activeTextColor,
    required this.activeItemDecoration,
    required this.inactiveItemDecoration,
    required this.itemRadius,
    this.showDotIndicator = false,
    this.isMaterial3 = false,
    this.activeScale = 1.15,
    required this.downloadButtonDecoration,
    required this.downloadIconColor,
  });

  static NavBarThemeData resolve(
    NavBarStyle style,
    ColorScheme cs,
    bool isActiveItem,
    bool isDownloadActive,
  ) {
    switch (style) {
      case NavBarStyle.minimal:
        return _minimal(cs, isActiveItem, isDownloadActive);
      case NavBarStyle.frosted:
        return _frosted(cs, isActiveItem, isDownloadActive);
      case NavBarStyle.material:
        return _material(cs, isActiveItem, isDownloadActive);
      case NavBarStyle.docked:
        return _docked(cs, isActiveItem, isDownloadActive);
      case NavBarStyle.classic:
        return _classic(cs, isActiveItem, isDownloadActive);
    }
  }

  static NavBarThemeData _docked(
    ColorScheme cs,
    bool isActiveItem,
    bool isDownloadActive,
  ) {
    return NavBarThemeData(
      blurSigma: null, // Solid, no blur
      barRadius: (size) => 0.0, // Sharp corners
      itemRadius: (size) => GlobalUI.uiRoundness,
      barDecoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      activeIconColor: cs.primary,
      inactiveIconColor: cs.onSurfaceVariant,
      activeTextColor: cs.primary,
      activeItemDecoration: const BoxDecoration(color: Colors.transparent),
      inactiveItemDecoration: const BoxDecoration(color: Colors.transparent),
      showDotIndicator: true,
      activeScale: 1.1,
      downloadButtonDecoration: BoxDecoration(
        color: isDownloadActive ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      downloadIconColor: isDownloadActive
          ? cs.onPrimaryContainer
          : cs.onSurfaceVariant,
    );
  }

  static NavBarThemeData _classic(
    ColorScheme cs,
    bool isActiveItem,
    bool isDownloadActive,
  ) {
    return NavBarThemeData(
      blurSigma: 14.0, // Slight blur for classic
      barRadius: (size) => GlobalUI.uiRoundness,
      itemRadius: (size) =>
          (GlobalUI.uiRoundness - 8.0).clamp(0.0, double.infinity),
      barDecoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.75),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
      ),
      activeIconColor: cs.onPrimary,
      inactiveIconColor: cs.onSurfaceVariant,
      activeTextColor: cs.onPrimary,
      activeItemDecoration: BoxDecoration(color: cs.primary),
      inactiveItemDecoration: const BoxDecoration(color: Colors.transparent),
      downloadButtonDecoration: BoxDecoration(
        color: isDownloadActive
            ? cs.primary
            : cs.surface.withValues(alpha: 0.75),
        border: Border.all(
          color: isDownloadActive
              ? cs.primary
              : cs.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      downloadIconColor: isDownloadActive ? cs.onPrimary : cs.onSurfaceVariant,
    );
  }

  static NavBarThemeData _minimal(
    ColorScheme cs,
    bool isActiveItem,
    bool isDownloadActive,
  ) {
    return NavBarThemeData(
      blurSigma: 12.0,
      barRadius: (size) => GlobalUI.uiRoundness,
      itemRadius: (size) =>
          (GlobalUI.uiRoundness - 8.0).clamp(0.0, double.infinity),
      barDecoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.95),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
        ],
      ),
      activeIconColor: cs.primary,
      inactiveIconColor: cs.onSurfaceVariant.withValues(alpha: 0.5),
      activeTextColor: cs.primary,
      activeItemDecoration: const BoxDecoration(color: Colors.transparent),
      inactiveItemDecoration: const BoxDecoration(color: Colors.transparent),
      showDotIndicator: true,
      activeScale: 1.10, // Slightly less scale for minimal
      downloadButtonDecoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.95),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.2),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
        ],
      ),
      downloadIconColor: isDownloadActive
          ? cs.primary
          : cs.onSurfaceVariant.withValues(alpha: 0.5),
    );
  }

  static NavBarThemeData _frosted(
    ColorScheme cs,
    bool isActiveItem,
    bool isDownloadActive,
  ) {
    return NavBarThemeData(
      blurSigma: 24.0, // Heavy blur
      barRadius: (size) => GlobalUI.uiRoundness,
      itemRadius: (size) =>
          (GlobalUI.uiRoundness - 8.0).clamp(0.0, double.infinity),
      barDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      activeIconColor: Colors.white,
      inactiveIconColor: Colors.white54,
      activeTextColor: Colors.white,
      activeItemDecoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      inactiveItemDecoration: const BoxDecoration(color: Colors.transparent),
      downloadButtonDecoration: BoxDecoration(
        color: isDownloadActive
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDownloadActive ? 0.3 : 0.15),
          width: isDownloadActive ? 0.5 : 0.8,
        ),
      ),
      downloadIconColor: isDownloadActive ? Colors.white : Colors.white54,
    );
  }

  static NavBarThemeData _material(
    ColorScheme cs,
    bool isActiveItem,
    bool isDownloadActive,
  ) {
    return NavBarThemeData(
      blurSigma: null,
      barRadius: (size) => 100.0,
      itemRadius: (size) => 100.0,
      barDecoration: BoxDecoration(color: cs.surfaceContainerHigh),
      activeIconColor: cs.onSecondaryContainer,
      inactiveIconColor: cs.onSurfaceVariant,
      activeTextColor: cs.onSecondaryContainer,
      activeItemDecoration: BoxDecoration(color: cs.secondaryContainer),
      inactiveItemDecoration: const BoxDecoration(color: Colors.transparent),
      isMaterial3: true,
      activeScale: 1.0, // No bounce
      downloadButtonDecoration: BoxDecoration(
        color: isDownloadActive
            ? cs.secondaryContainer
            : cs.surfaceContainerHigh,
      ),
      downloadIconColor: isDownloadActive
          ? cs.onSecondaryContainer
          : cs.onSurfaceVariant,
    );
  }
}
