import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/discovery_mode_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

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
    this.buttonSize = 36,
    this.iconSize = 20,
  }) : assert(icon != null || iconWidget != null || iconBuilder != null);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final radius = BorderRadius.circular(borderRadius ?? GlobalUI.uiRoundness);
    final iconColor = active ? cs.onPrimaryContainer : cs.onSurface;

    final Widget childWidget = iconBuilder != null
        ? iconBuilder!(context, iconColor)
        : (iconWidget ?? Icon(icon, size: iconSize, color: iconColor));

    final effectiveBgColor =
        backgroundColor ??
        (active
            ? cs.primaryContainer
            : cs.surfaceContainerHighest.withValues(alpha: 0.5));

    return Tooltip(
      message: tooltip,
      child: Material(
        color: effectiveBgColor,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: Center(child: childWidget),
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

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _onProfileTap(BuildContext context, TrackerType trackerType) {
    if (isPreview) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (_) => TrackerProfileSheet(trackerType: trackerType),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final HomeHeaderStyle style =
        styleOverride ??
        ref.watch(uiPrefsProvider.select((s) => s.homeHeaderStyle));
    final profiles = ref.watch(trackerProfileProvider);
    final primaryTrackerType = ref.watch(
      primaryTrackerProvider.select((s) => s.type),
    );
    final uiRoundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );

    final rawUsername = profiles[primaryTrackerType]?.username;
    final username = (rawUsername != null && rawUsername.isNotEmpty)
        ? rawUsername
        : (isPreview ? 'Shonen' : 'Guest');
    final avatarUrl = profiles[primaryTrackerType]?.avatarUrl;

    return switch (style) {
      HomeHeaderStyle.classic => _buildClassic(
        context,
        ref,
        theme,
        uiRoundness,
        primaryTrackerType,
        username,
        avatarUrl,
      ),
      HomeHeaderStyle.minimal => _buildMinimal(
        context,
        ref,
        theme,
        uiRoundness,
        primaryTrackerType,
        username,
        avatarUrl,
      ),
      HomeHeaderStyle.material => _buildMaterial(
        context,
        ref,
        theme,
        uiRoundness,
        primaryTrackerType,
        username,
        avatarUrl,
      ),
      HomeHeaderStyle.prominent => _buildProminent(
        context,
        ref,
        theme,
        uiRoundness,
        primaryTrackerType,
        username,
        avatarUrl,
      ),
    };
  }

  // Classic Style
  Widget _buildClassic(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double uiRoundness,
    TrackerType primaryTrackerType,
    String username,
    String? avatarUrl,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _onProfileTap(context, primaryTrackerType),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(uiRoundness),
                    color: theme.colorScheme.primaryContainer,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
                    child: TrackerAvatarWidget(imageUrl: avatarUrl, size: 48),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome back',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
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
        _buildActionButtons(context, ref, theme, uiRoundness),
      ],
    );
  }

  // Minimal Style
  Widget _buildMinimal(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double uiRoundness,
    TrackerType primaryTrackerType,
    String username,
    String? avatarUrl,
  ) {
    final cs = theme.colorScheme;
    final compactRadius = uiRoundness.clamp(6.0, 14.0);

    return Row(
      children: [
        GestureDetector(
          onTap: () => _onProfileTap(context, primaryTrackerType),
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(compactRadius),
                child: TrackerAvatarWidget(imageUrl: avatarUrl, size: 34),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                primaryTrackerType.displayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _buildActionButtons(
          context,
          ref,
          theme,
          compactRadius,
          buttonSize: 32,
          iconSize: 18,
          ghost: true,
        ),
      ],
    );
  }

  // Segmented Pill Style
  Widget _buildMaterial(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double uiRoundness,
    TrackerType primaryTrackerType,
    String username,
    String? avatarUrl,
  ) {
    final cs = theme.colorScheme;
    final pillRadius = BorderRadius.circular(100.0);

    return Row(
      children: [
        Expanded(
          child: Material(
            color: cs.surfaceContainerHigh,
            borderRadius: pillRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _onProfileTap(context, primaryTrackerType),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    ClipOval(
                      child: TrackerAvatarWidget(imageUrl: avatarUrl, size: 36),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        primaryTrackerType.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildActionButtons(
          context,
          ref,
          theme,
          100,
          buttonSize: 36,
          iconSize: 18,
          gap: 6.0,
        ),
      ],
    );
  }

  // Prominent Style
  Widget _buildProminent(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double uiRoundness,
    TrackerType primaryTrackerType,
    String username,
    String? avatarUrl,
  ) {
    final cs = theme.colorScheme;
    final timeGreeting = _getTimeGreeting();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _onProfileTap(context, primaryTrackerType),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primary, width: 2.0),
                  ),
                  child: ClipOval(
                    child: TrackerAvatarWidget(imageUrl: avatarUrl, size: 50),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 13,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeGreeting,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 21,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4), // Uniform padding
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(uiRoundness),
          ),
          child: _buildActionButtons(
            context,
            ref,
            theme,
            uiRoundness * 0.7,
            buttonSize: 32,
            iconSize: 18,
            ghost: true,
            gap: 4.0,
          ),
        ),
      ],
    );
  }

  // Action Buttons Row
  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    double borderRadius, {
    double buttonSize = 36,
    double iconSize = 20,
    bool ghost = false,
    double gap = 8.0,
  }) {
    final cs = theme.colorScheme;
    final ghostBg = Colors.transparent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer(
          builder: (context, ref, _) {
            final prefs = ref.watch(discoveryPrefsProvider);
            final isTracker = prefs.mode == MetadataMode.tracker;

            if (isTracker) {
              final metadataTracker = ref.watch(metadataSourceProvider);
              final trackerType = metadataTracker.type;
              final isAuto = prefs.metadataTrackerId == null;
              final tooltip = isAuto
                  ? 'Discovery Mode: Auto (${trackerType.displayName})'
                  : 'Discovery Mode: ${trackerType.displayName}';

              return HeaderActionButton(
                tooltip: tooltip,
                borderRadius: borderRadius,
                buttonSize: buttonSize,
                iconSize: iconSize,
                onTap: () => _onDiscoveryTap(context),
                backgroundColor: ghost
                    ? cs.primary.withValues(alpha: 0.15)
                    : null,
                iconBuilder: (context, color) =>
                    trackerType.getIconWidget(size: iconSize, color: color),
                active: true,
              );
            } else {
              return HeaderActionButton(
                tooltip: 'Discovery Mode: Extensions',
                borderRadius: borderRadius,
                buttonSize: buttonSize,
                iconSize: iconSize,
                onTap: () => _onDiscoveryTap(context),
                backgroundColor: ghost ? ghostBg : null,
                icon: Icons.extension_rounded,
                active: false,
              );
            }
          },
        ),
        SizedBox(width: gap),
        HeaderActionButton(
          tooltip: 'Airing Calendar',
          borderRadius: borderRadius,
          buttonSize: buttonSize,
          iconSize: iconSize,
          backgroundColor: ghost ? ghostBg : null,
          onTap: () => _onCalendarTap(context),
          icon: Icons.calendar_month_outlined,
        ),
        SizedBox(width: gap),
        HeaderActionButton(
          tooltip: 'Settings',
          borderRadius: borderRadius,
          buttonSize: buttonSize,
          iconSize: iconSize,
          backgroundColor: ghost ? ghostBg : null,
          onTap: () => _onSettingsTap(context),
          icon: Icons.settings_outlined,
        ),
      ],
    );
  }
}
