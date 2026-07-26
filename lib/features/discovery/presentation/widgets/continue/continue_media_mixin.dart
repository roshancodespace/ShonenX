import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/history/presentation/widgets/fix_source_sheet.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/source_engine/models/source_info.dart';

mixin ContinueMediaMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  bool isLoading = false;

  void setLoading(bool loading) {
    if (!mounted || isLoading == loading) return;
    setState(() => isLoading = loading);
  }

  Future<void> handleResumeMedia({
    required Future<void> Function() resolveAndPlay,
    required MediaType mediaType,
    required String mediaTitle,
    required FutureProvider<List<SourceInfo>> availableSourcesProvider,
  }) async {
    if (isLoading) return;

    setLoading(true);

    try {
      await resolveAndPlay();
    } catch (e) {
      if (!mounted) return;
      _showSourceError(
        error: e,
        mediaType: mediaType,
        mediaTitle: mediaTitle,
        availableSourcesProvider: availableSourcesProvider,
        onResumeRetry: resolveAndPlay,
      );
    } finally {
      setLoading(false);
    }
  }

  Future<void> _showSourceError({
    required Object error,
    required MediaType mediaType,
    required String mediaTitle,
    required FutureProvider<List<SourceInfo>> availableSourcesProvider,
    required Future<void> Function() onResumeRetry,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FixSourceSheet(mediaTitle: mediaTitle, type: mediaType),
    );

    if (result == true && mounted) {
      await handleResumeMedia(
        resolveAndPlay: onResumeRetry,
        mediaType: mediaType,
        mediaTitle: mediaTitle,
        availableSourcesProvider: availableSourcesProvider,
      );
    }
  }

  Future<void> showItemContextMenu({
    required Offset position,
    required MediaType mediaType,
    required String mediaTitle,
    required Future<void> Function() onRemoveHistory,
    VoidCallback? onViewDetails,
  }) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      useRootNavigator: true,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        if (onViewDetails != null)
          const PopupMenuItem(
            value: 'details',
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18),
                SizedBox(width: 8),
                Text('Open Details (No Play)'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'remove_history',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18),
              SizedBox(width: 8),
              Text('Remove from History'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'fix_source',
          child: Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 18),
              SizedBox(width: 8),
              Text('Fix Source'),
            ],
          ),
        ),
      ],
    );

    if (value == null || !mounted) return;

    switch (value) {
      case 'details':
        onViewDetails?.call();
        break;

      case 'remove_history':
        await onRemoveHistory();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Removed from history')));
        }
        break;

      case 'fix_source':
        final result = await showModalBottomSheet<bool>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) =>
              FixSourceSheet(mediaTitle: mediaTitle, type: mediaType),
        );

        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Source preference updated! Try playing again.'),
            ),
          );
        }
        break;
    }
  }
}
