import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/discovery/presentation/widgets/sheets/manual_match_sheet.dart';
import 'package:shonenx/features/discovery/providers/matched_media_provider.dart';
import 'package:shonenx/features/discovery/providers/media_preference_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
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
    final isNoSources = error.toString().contains('no-sources');

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (sheetContext) => _buildErrorSheet(
        sheetContext,
        isNoSources: isNoSources,
        mediaType: mediaType,
        mediaTitle: mediaTitle,
        availableSourcesProvider: availableSourcesProvider,
        onResumeRetry: onResumeRetry,
      ),
    );
  }

  Widget _buildErrorSheet(
    BuildContext sheetContext, {
    required bool isNoSources,
    required MediaType mediaType,
    required String mediaTitle,
    required FutureProvider<List<SourceInfo>> availableSourcesProvider,
    required Future<void> Function() onResumeRetry,
  }) {
    final theme = Theme.of(sheetContext);

    return AppBottomSheet(
      title: isNoSources ? 'No Extensions' : 'Source Missing',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isNoSources
                ? 'You do not have any extensions installed for this media type. Please install an extension from settings to continue.'
                : 'The extension you previously used for this is missing or could not find the content. Please select a new source to continue.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => _handleErrorAction(
              sheetContext,
              isNoSources: isNoSources,
              mediaType: mediaType,
              mediaTitle: mediaTitle,
              availableSourcesProvider: availableSourcesProvider,
              onResumeRetry: onResumeRetry,
            ),
            child: Text(isNoSources ? 'Go to Extensions' : 'Select New Source'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleErrorAction(
    BuildContext sheetContext, {
    required bool isNoSources,
    required MediaType mediaType,
    required String mediaTitle,
    required FutureProvider<List<SourceInfo>> availableSourcesProvider,
    required Future<void> Function() onResumeRetry,
  }) async {
    Navigator.pop(sheetContext);

    if (isNoSources) {
      context.push('/settings/extensions');
      return;
    }

    final selectedSource = await _selectNewSource(availableSourcesProvider);
    if (selectedSource == null || !mounted) return;

    ref
        .read(
          mediaPreferenceProvider(
            MatchArgs(mediaTitle: mediaTitle, type: mediaType),
          ).notifier,
        )
        .updateSource(selectedSource);

    final result = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => ManualMatchSheet(mediaTitle: mediaTitle, type: mediaType),
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

  Future<SourceInfo?> _selectNewSource(
    FutureProvider<List<SourceInfo>> provider,
  ) async {
    final sources = await ref.read(provider.future);
    if (!mounted) return null;

    return showModalBottomSheet<SourceInfo>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sourceCtx) {
        return AppBottomSheet(
          title: 'Select Source (1/2)',
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: sources.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final source = sources[index];
              return ListTile(
                leading: const Icon(Icons.extension),
                title: Text(
                  source.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text((source.lang ?? source.type.name).toUpperCase()),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(sourceCtx, source),
              );
            },
          ),
        );
      },
    );
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
          value: 'clear',
          child: Row(
            children: [
              Icon(Icons.layers_clear_outlined, size: 18),
              SizedBox(width: 8),
              Text('Clear Source Preference'),
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
          value: 'fix_match',
          child: Row(
            children: [
              Icon(Icons.build_circle_outlined, size: 18),
              SizedBox(width: 8),
              Text('Fix Match'),
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

      case 'clear':
        await ref
            .read(
              mediaPreferenceProvider(
                MatchArgs(mediaTitle: mediaTitle, type: mediaType),
              ).notifier,
            )
            .clearPreference();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Source preference cleared')),
          );
        }
        break;

      case 'remove_history':
        await onRemoveHistory();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Removed from history')));
        }
        break;

      case 'fix_match':
        await showModalBottomSheet(
          context: context,
          builder: (_) =>
              ManualMatchSheet(mediaTitle: mediaTitle, type: mediaType),
        );
        break;
    }
  }
}
