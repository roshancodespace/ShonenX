import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/discovery_mode_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

abstract final class _Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

class HeaderActionButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Widget Function(BuildContext context, Color color)? iconBuilder;
  final VoidCallback? onTap;
  final String tooltip;
  final bool active;
  final double? borderRadius;
  final Color? backgroundColor;
  final double buttonSize;
  final double iconSize;

  const HeaderActionButton({
    super.key,
    this.icon,
    this.iconWidget,
    this.iconBuilder,
    this.onTap,
    required this.tooltip,
    this.active = false,
    this.borderRadius,
    this.backgroundColor,
    this.buttonSize = 40,
    this.iconSize = 20,
  }) : assert(icon != null || iconWidget != null || iconBuilder != null);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(borderRadius ?? GlobalUI.uiRoundness);
    final iconColor = active ? cs.onPrimaryContainer : cs.onSurfaceVariant;

    final Widget child =
        iconBuilder?.call(context, iconColor) ??
        iconWidget ??
        Icon(icon, size: iconSize, color: iconColor);

    final bg =
        backgroundColor ??
        (active ? cs.primaryContainer : cs.surfaceContainerHighest);

    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeHeader extends ConsumerWidget {
  final HomeHeaderStyle? styleOverride;
  final bool isPreview;

  const HomeHeader({super.key, this.styleOverride, this.isPreview = false});

  ({String label, IconData icon}) _timeOfDay(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return (label: context.l10n.homeGoodMorning, icon: Icons.wb_twilight);
    }
    if (hour < 17) {
      return (
        label: context.l10n.homeGoodAfternoon,
        icon: Icons.wb_sunny_outlined,
      );
    }
    return (
      label: context.l10n.homeGoodEvening,
      icon: Icons.dark_mode_outlined,
    );
  }

  void _onProfileTap(BuildContext context, TrackerType type) {
    if (isPreview) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => TrackerProfileSheet(trackerType: type),
    );
  }

  void _onDiscoveryTap(BuildContext context) {
    if (isPreview) return;
    DiscoveryModeSheet.show(context);
  }

  void _onCalendarTap(BuildContext context) {
    if (isPreview) return;
    context.pushCalendar();
  }

  void _onSettingsTap(BuildContext context) {
    if (isPreview) return;
    context.pushSettings();
  }

  Widget _avatar(
    ThemeData theme, {
    required String? url,
    required double size,
    required double radius,
    bool circular = false,
    bool ring = false,
    double ringWidth = 2,
    double ringGap = 2,
    Color? ringColor,
  }) {
    final cs = theme.colorScheme;
    final innerRadius = circular ? size / 2 : radius;

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(innerRadius),
      child: TrackerAvatarWidget(imageUrl: url, size: size),
    );

    if (!ring) return image;

    final pad = ringWidth + ringGap;
    return Container(
      padding: EdgeInsets.all(ringGap),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(innerRadius + pad),
        border: Border.all(color: ringColor ?? cs.primary, width: ringWidth),
      ),
      child: image,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final HomeHeaderStyle style =
        styleOverride ??
        ref.watch(uiPrefsProvider.select((s) => s.homeHeaderStyle));
    final profiles = ref.watch(trackerProfileProvider);
    final trackerType = ref.watch(primaryTrackerProvider.select((s) => s.type));
    final roundness = GlobalUI.uiRoundness.clamp(0.0, 20.0);

    final rawName = profiles[trackerType]?.username;
    final username = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (isPreview ? 'Shonen' : 'Guest');
    final avatarUrl = profiles[trackerType]?.avatarUrl;

    return switch (style) {
      HomeHeaderStyle.classic => _buildClassic(
        context,
        ref,
        theme,
        roundness,
        trackerType,
        username,
        avatarUrl,
      ),
      HomeHeaderStyle.minimal => _buildMinimal(
        context,
        ref,
        theme,
        roundness,
        trackerType,
        username,
        avatarUrl,
      ),
      HomeHeaderStyle.material => _buildMaterial(
        context,
        ref,
        theme,
        trackerType,
        username,
        avatarUrl,
      ),
      HomeHeaderStyle.prominent => _buildProminent(
        context,
        ref,
        theme,
        roundness,
        trackerType,
        username,
        avatarUrl,
      ),
      HomeHeaderStyle.docked => _buildDocked(
        context,
        ref,
        theme,
        roundness,
        trackerType,
        username,
        avatarUrl,
      ),
    };
  }

  Widget _buildClassic(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double roundness,
    TrackerType trackerType,
    String username,
    String? avatarUrl,
  ) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final greeting = _timeOfDay(context).label;
    final avatarRadius = (roundness * 0.8).clamp(8.0, 18.0);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _onProfileTap(context, trackerType),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _avatar(
                  theme,
                  url: avatarUrl,
                  size: 46,
                  radius: avatarRadius,
                  ring: true,
                  ringWidth: 1.5,
                  ringColor: cs.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(width: _Gap.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        greeting,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: _Gap.sm),
        _buildActionButtons(
          context,
          radius: (roundness * 0.7).clamp(8.0, 16.0),
        ),
      ],
    );
  }

  Widget _buildMinimal(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double roundness,
    TrackerType trackerType,
    String username,
    String? avatarUrl,
  ) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final radius = roundness.clamp(6.0, 12.0);

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _onProfileTap(context, trackerType),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _avatar(theme, url: avatarUrl, size: 32, radius: radius),
                const SizedBox(width: _Gap.sm + 2),
                Flexible(
                  child: Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: _Gap.sm),
                Text(
                  trackerType.displayName,
                  maxLines: 1,
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: _Gap.sm),
        _buildActionButtons(
          context,
          radius: radius,
          size: 36,
          iconSize: 20,
          ghost: true,
          gap: 0,
        ),
      ],
    );
  }

  Widget _buildMaterial(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    TrackerType trackerType,
    String username,
    String? avatarUrl,
  ) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    const inset = 6.0;
    const inner = 40.0;
    const pill = BorderRadius.all(Radius.circular(100));

    return Row(
      children: [
        Expanded(
          child: Material(
            color: cs.surfaceContainerHigh,
            borderRadius: pill,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _onProfileTap(context, trackerType),
              child: Padding(
                padding: const EdgeInsets.all(inset),
                child: Row(
                  children: [
                    _avatar(
                      theme,
                      url: avatarUrl,
                      size: inner,
                      radius: inner / 2,
                      circular: true,
                    ),
                    const SizedBox(width: _Gap.md),
                    Expanded(
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: _Gap.sm),
                    // Same height as the avatar (40) and no trailing spacer, so
                    // the chip sits 6px from the pill edge on every side.
                    Container(
                      height: inner,
                      padding: const EdgeInsets.symmetric(horizontal: _Gap.lg),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: pill,
                      ),
                      child: Text(
                        trackerType.displayName,
                        style: tt.labelLarge?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: _Gap.sm),
        Container(
          padding: const EdgeInsets.all(inset),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: pill,
          ),
          child: _buildActionButtons(
            context,
            radius: 100,
            size: inner,
            iconSize: 20,
            ghost: true,
            gap: _Gap.xs,
          ),
        ),
      ],
    );
  }

  Widget _buildProminent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double roundness,
    TrackerType trackerType,
    String username,
    String? avatarUrl,
  ) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final tod = _timeOfDay(context);
    final groupRadius = (roundness * 0.9).clamp(10.0, 20.0);
    const groupInset = _Gap.xs;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _onProfileTap(context, trackerType),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                _avatar(
                  theme,
                  url: avatarUrl,
                  size: 48,
                  radius: 24,
                  circular: true,
                  ring: true,
                  ringWidth: 2,
                  ringGap: 3,
                ),
                const SizedBox(width: _Gap.md + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(tod.icon, size: 14, color: cs.primary),
                          const SizedBox(width: _Gap.xs + 2),
                          Flexible(
                            child: Text(
                              tod.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.labelMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: _Gap.sm),
        Container(
          padding: const EdgeInsets.all(groupInset),
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            // concentric: outer = inner + inset
            borderRadius: BorderRadius.circular(groupRadius + groupInset),
          ),
          child: _buildActionButtons(
            context,
            radius: groupRadius,
            size: 36,
            iconSize: 20,
            ghost: true,
            gap: _Gap.xs,
          ),
        ),
      ],
    );
  }

  Widget _buildDocked(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double roundness,
    TrackerType trackerType,
    String username,
    String? avatarUrl,
  ) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final tod = _timeOfDay(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _Gap.lg,
          vertical: _Gap.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _onProfileTap(context, trackerType),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    _avatar(
                      theme,
                      url: avatarUrl,
                      size: 40,
                      radius: 20,
                      circular: true,
                      ring: true,
                      ringWidth: 1.5,
                      ringGap: 0,
                      ringColor: cs.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: _Gap.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tod.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: _Gap.sm),
            _buildActionButtons(
              context,
              radius: (roundness * 0.7).clamp(8.0, 14.0),
              size: 36,
              iconSize: 20,
              ghost: true,
              gap: _Gap.xs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, {
    required double radius,
    double size = 40,
    double iconSize = 20,
    bool ghost = false,
    double gap = _Gap.sm,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final cs = Theme.of(context).colorScheme;
            final prefs = ref.watch(discoveryPrefsProvider);

            if (prefs.mode == MetadataMode.tracker) {
              final type = ref.watch(metadataSourceProvider).type;
              final isAuto = prefs.metadataTrackerId == null;
              final tooltip = isAuto
                  ? 'Discovery mode: Auto (${type.displayName})'
                  : 'Discovery mode: ${type.displayName}';

              return HeaderActionButton(
                tooltip: tooltip,
                borderRadius: radius,
                buttonSize: size,
                iconSize: iconSize,
                onTap: () => _onDiscoveryTap(context),
                active: true,
                backgroundColor: ghost
                    ? cs.primary.withValues(alpha: 0.14)
                    : null,
                iconBuilder: (context, color) =>
                    type.getIconWidget(size: iconSize, color: color),
              );
            }

            return HeaderActionButton(
              tooltip: 'Discovery mode: Extensions',
              borderRadius: radius,
              buttonSize: size,
              iconSize: iconSize,
              onTap: () => _onDiscoveryTap(context),
              backgroundColor: ghost ? Colors.transparent : null,
              icon: Icons.extension_outlined,
            );
          },
        ),
        SizedBox(width: gap),
        HeaderActionButton(
          tooltip: context.l10n.homeAiringToday,
          borderRadius: radius,
          buttonSize: size,
          iconSize: iconSize,
          backgroundColor: ghost ? Colors.transparent : null,
          onTap: () => _onCalendarTap(context),
          icon: Icons.calendar_month_outlined,
        ),
        SizedBox(width: gap),
        HeaderActionButton(
          tooltip: context.l10n.navSettings,
          borderRadius: radius,
          buttonSize: size,
          iconSize: iconSize,
          backgroundColor: ghost ? Colors.transparent : null,
          onTap: () => _onSettingsTap(context),
          icon: Icons.settings_outlined,
        ),
      ],
    );
  }
}
