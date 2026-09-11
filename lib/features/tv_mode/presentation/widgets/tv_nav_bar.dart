import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/router/app_navigator.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';
import 'package:shonenx/features/discovery/presentation/widgets/sheets/discovery_mode_sheet.dart';
import 'package:shonenx/features/discovery/providers/discovery_prefs_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/presentation/widgets/tracker_profile_sheet.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';

class TvNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const TvNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          children: [
            const Text(
              'ShonenX TV',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 32),
            _TvTabItem(
              label: 'Home',
              isSelected: selectedIndex == 0,
              onTap: () => onTabSelected(0),
            ),
            const SizedBox(width: 12),
            _TvTabItem(
              label: 'Discover',
              isSelected: selectedIndex == 1,
              onTap: () => onTabSelected(1),
            ),
            const SizedBox(width: 12),
            _TvTabItem(
              label: 'Library',
              isSelected: selectedIndex == 2,
              onTap: () => onTabSelected(2),
            ),
            const SizedBox(width: 12),
            _TvTabItem(
              label: 'Settings',
              isSelected: false,
              onTap: () => context.pushSettings(),
            ),
            const Spacer(),
            const _TvDiscoveryModeButton(),
            const SizedBox(width: 12),
            const _TvProfileButton(),
          ],
        ),
      ),
    );
  }
}

class _TvDiscoveryModeButton extends ConsumerWidget {
  const _TvDiscoveryModeButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(discoveryPrefsProvider);
    final isTracker = prefs.mode == MetadataMode.tracker;
    final cs = ColorScheme.of(context);
    final radius = GlobalUI.uiRoundness;

    final String label;
    if (isTracker) {
      final metadataTracker = ref.watch(metadataSourceProvider);
      final trackerType = metadataTracker.type;
      label = prefs.metadataTrackerId == null
          ? 'Auto (${trackerType.displayName})'
          : trackerType.displayName;
    } else {
      label = 'Extensions';
    }

    return AppFocusHover(
      onTap: () => DiscoveryModeSheet.show(context),
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;
        final fgColor = isFocused ? cs.surface : cs.onSurface;
        final iconColor = isFocused ? cs.surface : cs.primary;

        return InkWell(
          onTap: () => DiscoveryModeSheet.show(context),
          borderRadius: BorderRadius.circular(radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isFocused
                  ? cs.onSurface
                  : (isHovered
                        ? cs.surfaceContainerHighest
                        : cs.surfaceContainerHighest.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(radius),
              border: isFocused
                  ? Border.all(
                      color: cs.primary,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    )
                  : Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.25),
                      width: 1,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTracker)
                  ref
                      .watch(metadataSourceProvider)
                      .type
                      .getIconWidget(size: 16, color: iconColor)
                else
                  Icon(Icons.extension_rounded, size: 16, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TvProfileButton extends ConsumerWidget {
  const _TvProfileButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profiles = ref.watch(trackerProfileProvider);
    final primaryTrackerType = ref.watch(
      primaryTrackerProvider.select((s) => s.type),
    );
    final profile = profiles[primaryTrackerType];
    final cs = ColorScheme.of(context);
    final radius = GlobalUI.uiRoundness;

    final username = profile?.username.isNotEmpty == true
        ? profile!.username
        : 'Guest';
    final avatarUrl = profile?.avatarUrl;

    void openProfile() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => TrackerProfileSheet(trackerType: primaryTrackerType),
      );
    }

    return AppFocusHover(
      onTap: openProfile,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;
        final fgColor = isFocused ? cs.surface : cs.onSurface;

        return InkWell(
          onTap: openProfile,
          borderRadius: BorderRadius.circular(radius),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isFocused
                  ? cs.onSurface
                  : (isHovered
                        ? cs.surfaceContainerHighest
                        : cs.surfaceContainerHighest.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(radius),
              border: isFocused
                  ? Border.all(
                      color: cs.primary,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    )
                  : Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.25),
                      width: 1,
                    ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    (radius * 0.5).clamp(2.0, 16.0),
                  ),
                  child: TrackerAvatarWidget(imageUrl: avatarUrl, size: 26),
                ),
                const SizedBox(width: 8),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TvTabItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TvTabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TvTabItem> createState() => _TvTabItemState();
}

class _TvTabItemState extends State<_TvTabItem> {
  @override
  Widget build(BuildContext context) {
    final cs = ColorScheme.of(context);
    final radius = GlobalUI.uiRoundness;
    return AppFocusHover(
      onTap: widget.onTap,
      builder: (context, isFocused, isHovered) {
        return InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isFocused
                  ? cs.onSurface
                  : widget.isSelected
                  ? cs.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              border: isFocused
                  ? Border.all(
                      color: cs.primary,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    )
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: isFocused
                    ? cs.surface
                    : widget.isSelected
                    ? cs.onPrimary
                    : cs.onSurfaceVariant,
                fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
