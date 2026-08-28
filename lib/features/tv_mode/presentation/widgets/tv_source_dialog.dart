import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/features/tv_mode/presentation/widgets/tv_focusable.dart';
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

        return LayoutBuilder(
          builder: (context, constraints) {
            final useTwoColumns =
                constraints.maxWidth >= 460 && sources.length > 2;

            if (useTwoColumns) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: sources.length,
                itemBuilder: (context, index) {
                  final source = sources[index];
                  final isSelected = currentSource?.id == source.id;
                  return _SourceCard(
                    source: source,
                    isSelected: isSelected,
                    radius: radius,
                    cs: cs,
                    onTap: () => _selectSource(context, ref, source),
                  );
                },
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: sources.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final source = sources[index];
                final isSelected = currentSource?.id == source.id;
                return _SourceCard(
                  source: source,
                  isSelected: isSelected,
                  radius: radius,
                  cs: cs,
                  onTap: () => _selectSource(context, ref, source),
                );
              },
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
    return TvFocusable(
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
