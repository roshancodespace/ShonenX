import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/settings/presentation/source_settings_sheet.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/models/source_setting.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

class SourceSelectorList extends ConsumerWidget {
  final List<SourceInfo> availableSources;
  final SourceInfo? currentSource;
  final MediaType mediaType;
  final void Function(BuildContext context, SourceInfo source) onSourceSelected;
  final void Function()? onSettingsClosed;

  const SourceSelectorList({
    super.key,
    required this.availableSources,
    this.currentSource,
    required this.mediaType,
    required this.onSourceSelected,
    this.onSettingsClosed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (availableSources.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No sources available',
            style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final Map<String, List<SourceInfo>> groupedSources = {};
    for (final source in availableSources) {
      groupedSources.putIfAbsent(source.name, () => []).add(source);
    }

    for (final name in groupedSources.keys) {
      if (groupedSources[name]!.length > 1) {
        groupedSources[name]!.removeWhere(
          (s) => s.lang?.toLowerCase() == 'all',
        );
      }
    }

    final groupedNames = groupedSources.keys.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: groupedNames.length,
      itemBuilder: (context, index) {
        final sourceName = groupedNames[index];
        final sources = groupedSources[sourceName]!;

        return StatefulBuilder(
          builder: (context, setState) {
            bool isExpanded = false;

            Widget buildSourceItem({
              required SourceInfo sourceInfo,
              required bool isSubItem,
              required String? parentIconUrl,
              Widget? expandAction,
            }) {
              final selected = currentSource == sourceInfo;
              final sourceImpl = mediaType.usesAnimeSources
                  ? ref.read(animeSourceProvider(sourceInfo))
                  : ref.read(mangaSourceProvider(sourceInfo));

              final iconUrlToUse = sourceInfo.iconUrl?.isNotEmpty == true
                  ? sourceInfo.iconUrl
                  : parentIconUrl;

              return Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () => onSourceSelected(context, sourceInfo),
                  focusColor: cs.secondaryContainer.withValues(alpha: 0.5),
                  hoverColor: cs.onSurface.withValues(alpha: 0.08),
                  highlightColor: cs.onSurface.withValues(alpha: 0.12),
                  child: Container(
                    color: selected && isSubItem
                        ? cs.primaryContainer.withValues(alpha: 0.15)
                        : Colors.transparent,
                    padding: EdgeInsets.fromLTRB(isSubItem ? 30 : 18, 8, 18, 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child:
                              (iconUrlToUse != null && iconUrlToUse.isNotEmpty)
                              ? CachedNetworkImage(
                                  imageUrl: iconUrlToUse,
                                  width: isSubItem ? 32 : 44,
                                  height: isSubItem ? 32 : 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.extension,
                                    size: isSubItem ? 32 : 44,
                                  ),
                                )
                              : Icon(
                                  Icons.extension,
                                  size: isSubItem ? 32 : 44,
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSubItem
                                    ? (sourceInfo.lang ?? sourceInfo.type.name)
                                          .toUpperCase()
                                    : sourceInfo.name,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected ? cs.primary : cs.onSurface,
                                ),
                              ),
                              if (!isSubItem) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${sources.length} variants • ${(sourceInfo.lang ?? sourceInfo.type.name).toUpperCase()}',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.7,
                                    ),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        FutureBuilder<List<SourceSetting>>(
                          future: sourceImpl.getSettingsSchema(),
                          builder: (context, snapshot) {
                            final hasSettings =
                                snapshot.hasData && snapshot.data!.isNotEmpty;
                            if (!hasSettings) {
                              return const SizedBox.shrink();
                            }

                            return IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              color: cs.onSurfaceVariant,
                              tooltip: 'Source Settings',
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => SourceSettingsSheet(
                                    source: sourceInfo,
                                    schema: snapshot.data!,
                                  ),
                                ).then((_) {
                                  if (onSettingsClosed != null) {
                                    onSettingsClosed!();
                                  }
                                });
                              },
                            );
                          },
                        ),
                        if (selected && !isSubItem) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle_rounded,
                            color: cs.primary,
                            size: 24,
                          ),
                        ],
                        if (expandAction != null) ...[
                          const SizedBox(width: 4),
                          expandAction,
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }

            if (sources.length == 1) {
              return buildSourceItem(
                sourceInfo: sources.first,
                isSubItem: false,
                parentIconUrl: sources.first.iconUrl,
              );
            }

            final hasSelectedVariant = sources.any((s) => s == currentSource);
            final defaultVariant = sources.firstWhere((s) {
              final l = s.lang?.toLowerCase();
              return l == 'en' || l == 'english';
            }, orElse: () => sources.first);

            final activeVariant = hasSelectedVariant
                ? currentSource!
                : defaultVariant;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSourceItem(
                  sourceInfo: activeVariant,
                  isSubItem: false,
                  parentIconUrl: sources.first.iconUrl,
                  expandAction: IconButton(
                    icon: Icon(Icons.expand_more, color: cs.onSurfaceVariant),
                    tooltip: 'Expand variants',
                    onPressed: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    children: sources
                        .map(
                          (s) => buildSourceItem(
                            sourceInfo: s,
                            isSubItem: true,
                            parentIconUrl: sources.first.iconUrl,
                          ),
                        )
                        .toList(),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
