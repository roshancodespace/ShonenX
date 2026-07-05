import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_list_item.dart';
import 'package:shonenx/features/tracking/domain/models/tracked_status.dart';
import 'package:shonenx/features/tracking/engine/tracking_service.dart';
import 'package:shonenx/features/tracking/providers/media_tracking_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class EditTrackerSheet extends ConsumerStatefulWidget {
  final UnifiedMedia media;
  final TrackedListItem initialItem;
  final TrackingService tracker;
  final String? trackingId;

  const EditTrackerSheet({
    super.key,
    required this.media,
    required this.initialItem,
    required this.tracker,
    this.trackingId,
  });

  @override
  ConsumerState<EditTrackerSheet> createState() => _EditTrackerSheetState();
}

class _EditTrackerSheetState extends ConsumerState<EditTrackerSheet> {
  late TrackedStatus _status;
  late double _progress;
  late double _score;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialItem.status == TrackedStatus.unknown
        ? TrackedStatus.watching
        : widget.initialItem.status;
    _progress = widget.initialItem.progress;
    _score = widget.initialItem.score ?? 0.0;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      if (!(await widget.tracker.isAuthenticated)) {
        throw Exception('Not authenticated');
      }

      await widget.tracker.updateListItem(
        media: widget.media,
        trackingId: widget.trackingId ?? widget.media.id,
        status: _status,
        progress: _progress,
        score: _score,
      );

      ref.invalidate(
        mediaTrackingProvider(
          TrackingQuery(
            widget.tracker.type,
            widget.media.id,
            widget.media.type,
          ),
        ),
      );

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxEpisodes = widget.media.episodes;

    return AppBottomSheet(
      title: 'Edit Tracking',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<TrackedStatus>(
            initialValue: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: TrackedStatus.values
                .where((s) => s != TrackedStatus.unknown)
                .map(
                  (s) => DropdownMenuItem<TrackedStatus>(
                    value: s,
                    child: Text(s.getLabelForMedia(widget.media.type)),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _status = val;
                  if (val == TrackedStatus.completed && maxEpisodes != null) {
                    _progress = maxEpisodes.toDouble();
                  }
                });
              }
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Progress',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                onPressed: _progress > 0
                    ? () => setState(() => _progress--)
                    : null,
                onLongPress: () {
                  if (_progress > 0) {
                    setState(() => _progress = 0);
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                ),
                icon: const Icon(Icons.remove),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => AppBottomSheet(
                        title: 'Edit Progress',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  IntrinsicWidth(
                                    child: TextField(
                                      canRequestFocus: true,
                                      autofocus: true,
                                      controller: TextEditingController(
                                        text: _progress.toInt().toString(),
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      onChanged: (v) {
                                        if (v.isNotEmpty) {
                                          setState(
                                            () => _progress = double.parse(v),
                                          );
                                        }
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '  /  ${maxEpisodes ?? '??'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: () => context.pop(),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                ),
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    '${_progress.toInt()} ${maxEpisodes != null ? '/ $maxEpisodes' : ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: (maxEpisodes == null || _progress < maxEpisodes)
                    ? () => setState(() => _progress++)
                    : null,
                onLongPress: () {
                  if (maxEpisodes != null) {
                    setState(() => _progress = maxEpisodes.toDouble());
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                ),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Score',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                _score > 0 ? _score.toStringAsFixed(1) : 'Unscored',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: _score,
            min: 0,
            max: 10,
            divisions: 100,
            onChanged: (val) => setState(() => _score = val),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
