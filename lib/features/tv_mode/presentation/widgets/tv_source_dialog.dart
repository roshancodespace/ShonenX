import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';

import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

class TvSourceDialog {
  static Future<void> show(
    BuildContext context, {
    required UnifiedMedia media,
    SourceInfo? currentSource,
  }) {
    return AppDialog.show(
      context: context,
      title: 'Select Source Provider',
      icon: const Icon(Icons.tune_rounded),
      maxWidth: 680,
      wrapScrollable: false,
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: _TvSourceSelector(media: media, currentSource: currentSource),
    );
  }
}

class _TvSourceSelector extends ConsumerWidget {
  final UnifiedMedia media;
  final SourceInfo? currentSource;

  const _TvSourceSelector({required this.media, this.currentSource});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sourcesAsync = ref.watch(media.type.availableSourcesProvider);
    final radius = GlobalUI.uiRoundness;

    return sourcesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 10),
              Text(
                'Failed to load sources: $err',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
      data: (sources) {
        if (sources.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'No sources available for ${media.type.name}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final Map<String, List<SourceInfo>> groupedSources = {};
        for (final source in sources) {
          groupedSources.putIfAbsent(source.name, () => []).add(source);
        }

        for (final name in groupedSources.keys) {
          if (groupedSources[name]!.length > 1) {
            groupedSources[name]!.removeWhere(
              (s) => s.lang?.toLowerCase() == 'all',
            );
          }
        }
        final groupList = groupedSources.values.toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: groupList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final group = groupList[index];
            if (group.length == 1) {
              final source = group.first;
              final isSelected = currentSource?.id == source.id;
              return _SourceCard(
                source: source,
                isSelected: isSelected,
                radius: radius,
                cs: cs,
                onTap: () => _selectSource(context, ref, source),
              );
            }

            return _TvSourceGroupCard(
              sources: group,
              currentSource: currentSource,
              radius: radius,
              cs: cs,
              onSelectSource: (source) => _selectSource(context, ref, source),
            );
          },
        );
      },
    );
  }

  Future<void> _selectSource(
    BuildContext context,
    WidgetRef ref,
    SourceInfo source,
  ) async {
    final notifier = ref.read(
      mediaPreferenceProvider(MediaArgs.fromMedia(media)).notifier,
    );
    await notifier.updateSource(source);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _SourceCard extends StatelessWidget {
  final SourceInfo source;
  final bool isSelected;
  final double radius;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _SourceCard({
    required this.source,
    required this.isSelected,
    required this.radius,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppFocusHover(
      onTap: onTap,
      scaleFactor: 1.02,
      builder: (context, isFocused, isHovered) {
        final active = isFocused || isHovered;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : isSelected
                ? cs.primary.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: active
                  ? Colors.white
                  : isSelected
                  ? cs.primary.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
              width: active ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.black.withValues(alpha: 0.08)
                      : isSelected
                      ? cs.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(
                    (radius * 0.6).clamp(0.0, radius),
                  ),
                ),
                child: source.iconUrl != null && source.iconUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: source.iconUrl!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.extension_rounded,
                          size: 18,
                          color: active
                              ? Colors.black
                              : (isSelected ? cs.primary : Colors.white70),
                        ),
                      )
                    : Icon(
                        Icons.extension_rounded,
                        size: 18,
                        color: active
                            ? Colors.black
                            : (isSelected ? cs.primary : Colors.white70),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      source.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active ? Colors.black : Colors.white,
                        fontWeight: isSelected || active
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (source.lang != null && source.lang!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? Colors.black.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                (radius * 0.4).clamp(0.0, radius),
                              ),
                            ),
                            child: Text(
                              source.lang!.toUpperCase(),
                              style: TextStyle(
                                color: active ? Colors.black87 : Colors.white60,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: active ? Colors.black : cs.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: active ? Colors.white : Colors.black,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TvSourceGroupCard extends StatefulWidget {
  final List<SourceInfo> sources;
  final SourceInfo? currentSource;
  final double radius;
  final ColorScheme cs;
  final ValueChanged<SourceInfo> onSelectSource;

  const _TvSourceGroupCard({
    required this.sources,
    required this.currentSource,
    required this.radius,
    required this.cs,
    required this.onSelectSource,
  });

  @override
  State<_TvSourceGroupCard> createState() => _TvSourceGroupCardState();
}

class _TvSourceGroupCardState extends State<_TvSourceGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hasSelected = widget.sources.any(
      (s) => s.id == widget.currentSource?.id,
    );
    final defaultVariant = widget.sources.firstWhere(
      (s) =>
          s.lang?.toLowerCase() == 'en' || s.lang?.toLowerCase() == 'english',
      orElse: () => widget.sources.first,
    );
    final activeVariant = hasSelected ? widget.currentSource! : defaultVariant;
    final isSelected = widget.currentSource?.id == activeVariant.id;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFocusHover(
          onTap: () => widget.onSelectSource(activeVariant),
          scaleFactor: 1.02,
          builder: (context, isFocused, isHovered) {
            final active = isFocused || isHovered;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white
                    : isSelected
                    ? widget.cs.primary.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(widget.radius),
                border: Border.all(
                  color: active
                      ? Colors.white
                      : isSelected
                      ? widget.cs.primary.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.08),
                  width: active ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.black.withValues(alpha: 0.08)
                          : isSelected
                          ? widget.cs.primary.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(
                        (widget.radius * 0.6).clamp(0.0, widget.radius),
                      ),
                    ),
                    child:
                        activeVariant.iconUrl != null &&
                            activeVariant.iconUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: activeVariant.iconUrl!,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.extension_rounded,
                              size: 18,
                              color: active
                                  ? Colors.black
                                  : (isSelected
                                        ? widget.cs.primary
                                        : Colors.white70),
                            ),
                          )
                        : Icon(
                            Icons.extension_rounded,
                            size: 18,
                            color: active
                                ? Colors.black
                                : (isSelected
                                      ? widget.cs.primary
                                      : Colors.white70),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activeVariant.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active ? Colors.black : Colors.white,
                            fontWeight: isSelected || active
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.black.withValues(alpha: 0.1)
                                    : Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(
                                  (widget.radius * 0.4).clamp(
                                    0.0,
                                    widget.radius,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${widget.sources.length} VARIANTS • ${(activeVariant.lang ?? activeVariant.type.name).toUpperCase()}',
                                style: TextStyle(
                                  color: active
                                      ? Colors.black87
                                      : Colors.white60,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: active ? Colors.black : widget.cs.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 13,
                        color: active ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AppFocusHover(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    scaleFactor: 1.1,
                    builder: (context, isArrowFocused, isArrowHovered) {
                      final arrowActive = isArrowFocused || isArrowHovered;
                      return Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: arrowActive
                              ? (active ? Colors.black26 : Colors.white24)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: active ? Colors.black : Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 20, top: 6, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.sources.map((variant) {
                      final isVariantSelected =
                          widget.currentSource?.id == variant.id;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: AppFocusHover(
                          onTap: () => widget.onSelectSource(variant),
                          scaleFactor: 1.02,
                          builder: (context, isSubFocused, isSubHovered) {
                            final subActive = isSubFocused || isSubHovered;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: subActive
                                    ? Colors.white
                                    : isVariantSelected
                                    ? widget.cs.primary.withValues(alpha: 0.14)
                                    : Colors.white.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(
                                  widget.radius * 0.8,
                                ),
                                border: Border.all(
                                  color: subActive
                                      ? Colors.white
                                      : isVariantSelected
                                      ? widget.cs.primary.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.06),
                                  width: subActive ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.subdirectory_arrow_right_rounded,
                                    size: 16,
                                    color: subActive
                                        ? Colors.black54
                                        : Colors.white.withValues(alpha: 0.4),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      (variant.lang ?? variant.type.name)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: subActive
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight:
                                            isVariantSelected || subActive
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  if (isVariantSelected)
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: subActive
                                            ? Colors.black
                                            : widget.cs.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 11,
                                        color: subActive
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
