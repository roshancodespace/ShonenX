import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/settings/presentation/source_settings_sheet.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/selection_card_group.dart';
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
  final bool showDoneButton;

  const SourceSelectorList({
    super.key,
    required this.availableSources,
    this.currentSource,
    required this.mediaType,
    required this.onSourceSelected,
    this.onSettingsClosed,
    this.showDoneButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SelectionCardGroup(
            title: 'Available Sources',
            subtitle:
                'Select an extension for media playback and chapter reading.',
            children: groupedNames.asMap().entries.map((entry) {
              final groupIndex = entry.key;
              final sourceName = entry.value;
              final sources = groupedSources[sourceName]!;
              final isLastGroup = groupIndex == groupedNames.length - 1;

              return _SourceGroupCardTile(
                key: ValueKey(sourceName),
                sourceName: sourceName,
                sources: sources,
                currentSource: currentSource,
                mediaType: mediaType,
                isLastGroup: isLastGroup,
                onSourceSelected: onSourceSelected,
                onSettingsClosed: onSettingsClosed,
              );
            }).toList(),
          ),
          if (showDoneButton) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: context.pop,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 1,
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SourceGroupCardTile extends ConsumerStatefulWidget {
  final String sourceName;
  final List<SourceInfo> sources;
  final SourceInfo? currentSource;
  final MediaType mediaType;
  final bool isLastGroup;
  final void Function(BuildContext context, SourceInfo source) onSourceSelected;
  final void Function()? onSettingsClosed;

  const _SourceGroupCardTile({
    super.key,
    required this.sourceName,
    required this.sources,
    required this.currentSource,
    required this.mediaType,
    required this.isLastGroup,
    required this.onSourceSelected,
    this.onSettingsClosed,
  });

  @override
  ConsumerState<_SourceGroupCardTile> createState() =>
      _SourceGroupCardTileState();
}

class _SourceGroupCardTileState extends ConsumerState<_SourceGroupCardTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (widget.sources.length == 1) {
      return _buildTile(
        context: context,
        sourceInfo: widget.sources.first,
        isSubItem: false,
        parentIconUrl: widget.sources.first.iconUrl,
        showDivider: !widget.isLastGroup,
      );
    }

    final hasSelectedVariant = widget.sources.any(
      (s) => s.id == widget.currentSource?.id,
    );
    final defaultVariant = widget.sources.firstWhere((s) {
      final l = s.lang?.toLowerCase();
      return l == 'en' || l == 'english';
    }, orElse: () => widget.sources.first);

    final activeVariant = hasSelectedVariant
        ? widget.currentSource!
        : defaultVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTile(
          context: context,
          sourceInfo: activeVariant,
          isSubItem: false,
          parentIconUrl: widget.sources.first.iconUrl,
          showDivider: _isExpanded || !widget.isLastGroup,
          expandAction: IconButton(
            icon: AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutCubic,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: cs.onSurfaceVariant,
                size: 20,
              ),
            ),
            visualDensity: VisualDensity.compact,
            tooltip: _isExpanded ? 'Collapse variants' : 'Expand variants',
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.fastOutSlowIn,
          alignment: Alignment.topCenter,
          child: _isExpanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.sources.asMap().entries.map((vEntry) {
                    final vIdx = vEntry.key;
                    final s = vEntry.value;
                    final isLastVariant = vIdx == widget.sources.length - 1;

                    return _buildTile(
                      context: context,
                      sourceInfo: s,
                      isSubItem: true,
                      parentIconUrl: widget.sources.first.iconUrl,
                      showDivider: !widget.isLastGroup || !isLastVariant,
                    );
                  }).toList(),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required SourceInfo sourceInfo,
    required bool isSubItem,
    required String? parentIconUrl,
    Widget? expandAction,
    bool showDivider = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final selected = widget.currentSource?.id == sourceInfo.id;
    final sourceImpl = widget.mediaType.usesAnimeSources
        ? ref.read(animeSourceProvider(sourceInfo))
        : ref.read(mangaSourceProvider(sourceInfo));

    final iconUrlToUse = sourceInfo.iconUrl?.isNotEmpty == true
        ? sourceInfo.iconUrl
        : parentIconUrl;

    return SelectionCardTile(
      isSubItem: isSubItem,
      isSelected: selected,
      showDivider: showDivider,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: (iconUrlToUse != null && iconUrlToUse.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: iconUrlToUse,
                width: isSubItem ? 20 : 24,
                height: isSubItem ? 20 : 24,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Icon(
                  Icons.extension_rounded,
                  size: isSubItem ? 20 : 24,
                  color: cs.onSurfaceVariant,
                ),
              )
            : Icon(
                Icons.extension_rounded,
                size: isSubItem ? 20 : 24,
                color: cs.onSurfaceVariant,
              ),
      ),
      title: isSubItem
          ? (sourceInfo.lang ?? sourceInfo.type.name).toUpperCase()
          : sourceInfo.name,
      subtitle: isSubItem
          ? null
          : '${widget.sources.length} ${widget.sources.length == 1 ? 'variant' : 'variants'} • ${(sourceInfo.lang ?? sourceInfo.type.name).toUpperCase()}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder<List<SourceSetting>>(
            future: sourceImpl.getSettingsSchema(),
            builder: (context, snapshot) {
              final hasSettings = snapshot.hasData && snapshot.data!.isNotEmpty;
              if (!hasSettings) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.settings_outlined, size: 18),
                color: cs.onSurfaceVariant,
                visualDensity: VisualDensity.compact,
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
                    if (widget.onSettingsClosed != null) {
                      widget.onSettingsClosed!();
                    }
                  });
                },
              );
            },
          ),
          if (expandAction != null) expandAction,
        ],
      ),
      onTap: () => widget.onSourceSelected(context, sourceInfo),
    );
  }
}
