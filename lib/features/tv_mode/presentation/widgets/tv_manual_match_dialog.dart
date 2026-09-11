import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/core/utils/focus_hover_detector.dart';
import 'package:shonenx/features/discovery/domain/media_args.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/source_engine/utils/media_type_extensions.dart';

class TvManualMatchDialog {
  static Future<void> show(
    BuildContext context, {
    required String mediaTitle,
    required MediaType type,
    required MediaArgs matchArgs,
    SourceInfo? currentSource,
  }) {
    final title = currentSource != null
        ? 'Fix Match • ${currentSource.name}'
        : 'Fix Match';

    return AppDialog.show(
      context: context,
      title: title,
      icon: const Icon(Icons.auto_fix_high_rounded),
      maxWidth: 700,
      wrapScrollable: false,
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: _TvManualMatchContent(
        mediaTitle: mediaTitle,
        type: type,
        matchArgs: matchArgs,
      ),
    );
  }
}

class _TvManualMatchContent extends ConsumerStatefulWidget {
  final String mediaTitle;
  final MediaType type;
  final MediaArgs matchArgs;

  const _TvManualMatchContent({
    required this.mediaTitle,
    required this.type,
    required this.matchArgs,
  });

  @override
  ConsumerState<_TvManualMatchContent> createState() =>
      _TvManualMatchContentState();
}

class _TvManualMatchContentState extends ConsumerState<_TvManualMatchContent> {
  late final TextEditingController _controller;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;

  List<UnifiedMedia>? _results;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.mediaTitle);
    _search(widget.mediaTitle);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    setState(() {
      _isLoading = true;
      _results = null;
    });

    try {
      final pref = await ref.read(
        mediaPreferenceProvider(widget.matchArgs).future,
      );
      final source = widget.type.usesAnimeSources
          ? ref.read(animeSourceProvider(pref.sourceInfo))
          : ref.read(mangaSourceProvider(pref.sourceInfo));
      final results = await source.search(cleanQuery, widget.type);
      if (mounted) setState(() => _results = results);
    } catch (e, st) {
      AppLogger.scope(
        'TvManualMatchDialog',
      ).e('Search failed for "$cleanQuery"', e, st);
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSelect(UnifiedMedia result) {
    ref
        .read(mediaPreferenceProvider(widget.matchArgs).notifier)
        .setManualMatch(result.id, result.title.availableTitle);

    Navigator.of(context).pop();
  }

  void _resetToAuto(SourceInfo sourceInfo) {
    ref
        .read(mediaPreferenceProvider(widget.matchArgs).notifier)
        .updateSource(sourceInfo);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final radius = GlobalUI.uiRoundness;
    final prefState = ref
        .watch(mediaPreferenceProvider(widget.matchArgs))
        .value;
    final hasManualMatch = prefState?.matchedMediaId != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasManualMatch && prefState != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Matched: ${prefState.matchedMediaTitle ?? prefState.matchedMediaId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AppFocusHover(
                  onTap: () => _resetToAuto(prefState.sourceInfo),
                  scaleFactor: 1.05,
                  builder: (context, isFocused, isHovered) {
                    final active = isFocused || isHovered;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white12,
                        borderRadius: BorderRadius.circular(
                          (radius * 0.6).clamp(0.0, double.infinity),
                        ),
                      ),
                      child: Text(
                        'Reset Auto',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.black : Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.25),
            ),
          ),
          child: TextField(
            controller: _controller,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            onSubmitted: _search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search title on provider...',
              hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: cs.primary,
                size: 20,
              ),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: _buildResultsList(cs, radius, prefState?.matchedMediaId),
        ),
      ],
    );
  }

  Widget _buildResultsList(
    ColorScheme cs,
    double radius,
    String? currentMatchedId,
  ) {
    if (_isLoading && _results == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_results != null && _results!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 36, color: cs.outline),
              const SizedBox(height: 10),
              const Text(
                'No matches found on this source',
                style: TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    }

    final items = _results ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isMatched = currentMatchedId == item.id;

        return AppFocusHover(
          onTap: () => _onSelect(item),
          scaleFactor: 1.02,
          builder: (context, isFocused, isHovered) {
            final active = isFocused || isHovered;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? Colors.white
                    : isMatched
                    ? cs.primary.withValues(alpha: 0.14)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: active
                      ? Colors.white
                      : isMatched
                      ? cs.primary.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.08),
                  width: active ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      (radius * 0.5).clamp(0.0, double.infinity),
                    ),
                    child: item.cover != null && item.cover!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.cover!,
                            width: 38,
                            height: 54,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 38,
                              height: 54,
                              color: Colors.white10,
                              child: const Icon(Icons.movie_outlined, size: 18),
                            ),
                          )
                        : Container(
                            width: 38,
                            height: 54,
                            color: Colors.white10,
                            child: const Icon(Icons.movie_outlined, size: 18),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title.availableTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: active || isMatched
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: active ? Colors.black : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (item.format != null) ...[
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
                                    (radius * 0.4).clamp(0.0, double.infinity),
                                  ),
                                ),
                                child: Text(
                                  item.format!.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: active
                                        ? Colors.black87
                                        : Colors.white60,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (item.year != null)
                              Text(
                                item.year.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: active
                                      ? Colors.black54
                                      : Colors.white54,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.black
                          : isMatched
                          ? cs.primary
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        (radius * 0.5).clamp(0.0, double.infinity),
                      ),
                    ),
                    child: Text(
                      isMatched ? 'Matched' : 'Select',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: active
                            ? Colors.white
                            : isMatched
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
