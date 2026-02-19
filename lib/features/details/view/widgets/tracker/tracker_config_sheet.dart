import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/core/models/tracker/tracker_models.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/features/details/view_model/external_tracker_notifier.dart';

/// Bottom sheet for configuring tracking (status, progress, score, dates).
class TrackerConfigSheet extends ConsumerStatefulWidget {
  final UniversalMedia media;
  final TrackerType tracker;
  final int remoteId;

  const TrackerConfigSheet({
    super.key,
    required this.media,
    required this.tracker,
    required this.remoteId,
  });

  static Future<void> show(
    BuildContext context, {
    required UniversalMedia media,
    required TrackerType tracker,
    required int remoteId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TrackerConfigSheet(
        media: media,
        tracker: tracker,
        remoteId: remoteId,
      ),
    );
  }

  @override
  ConsumerState<TrackerConfigSheet> createState() => _TrackerConfigSheetState();
}

class _TrackerConfigSheetState extends ConsumerState<TrackerConfigSheet> {
  late String _status;
  late TextEditingController _progressController;
  late TextEditingController _scoreController;
  DateTime? _startDate;
  DateTime? _endDate;

  final ValueNotifier<bool> _isSaving = ValueNotifier(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier(true);
  bool _isExistingEntry = false;

  @override
  void initState() {
    super.initState();
    _status = TrackerStatus.planned;
    _progressController = TextEditingController(text: '0');
    _scoreController = TextEditingController(text: '0');
    _loadExistingEntry();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scoreController.dispose();
    _isSaving.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _loadExistingEntry() async {
    _isLoading.value = true;

    try {
      // First ensure binding exists
      final notifier = ref.read(
        externalTrackerProvider(widget.media.id).notifier,
      );
      await notifier.bindTracker(widget.media, widget.tracker, widget.remoteId);

      // Check if there's existing remote entry data
      final trackerState = ref.read(externalTrackerProvider(widget.media.id));
      final entry = trackerState.entries[widget.tracker];

      if (entry != null) {
        _isExistingEntry = true;
        setState(() {
          _status = entry.status;
          _progressController.text = entry.progress.toString();
          _scoreController.text = entry.score.toString();
          _startDate = entry.startDate;
          _endDate = entry.endDate;
        });
      }
    } catch (_) {
      // Entry may not exist yet, that's fine
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _save() async {
    _isSaving.value = true;

    try {
      final notifier = ref.read(
        externalTrackerProvider(widget.media.id).notifier,
      );
      final progress = int.tryParse(_progressController.text) ?? 0;
      final score = double.tryParse(_scoreController.text) ?? 0;

      final success = await notifier.saveTrackerEntry(
        widget.media,
        widget.tracker,
        widget.remoteId,
        status: _status,
        progress: progress,
        score: score,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated on ${widget.tracker.displayName}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update ${widget.tracker.displayName}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      _isSaving.value = false;
    }
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Tracker?'),
        content: Text(
          'This will remove tracking for this anime on ${widget.tracker.displayName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _isSaving.value = true;
    try {
      final notifier = ref.read(
        externalTrackerProvider(widget.media.id).notifier,
      );
      await notifier.removeTracker(
        widget.media,
        widget.tracker,
        widget.remoteId,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      _isSaving.value = false;
    }
  }

  void _handleStatusChange(String? newStatus) {
    if (newStatus == null) return;
    setState(() {
      _status = newStatus;
      if (newStatus == TrackerStatus.completed) {
        if (widget.media.episodes != null) {
          _progressController.text = widget.media.episodes.toString();
        }
        _endDate ??= DateTime.now();
        _startDate ??= DateTime.now();
      } else if (newStatus == TrackerStatus.watching) {
        _startDate ??= DateTime.now();
        _endDate = null;
      }
    });
  }

  void _incrementProgress() {
    int current = int.tryParse(_progressController.text) ?? 0;
    int? total = widget.media.episodes;
    if (total == null || current < total) {
      setState(() {
        current++;
        _progressController.text = current.toString();
        if (total != null && current == total) {
          _status = TrackerStatus.completed;
          _endDate ??= DateTime.now();
        } else if (_status == TrackerStatus.planned) {
          _status = TrackerStatus.watching;
          _startDate ??= DateTime.now();
        }
      });
    }
  }

  void _decrementProgress() {
    int current = int.tryParse(_progressController.text) ?? 0;
    if (current > 0) {
      setState(() {
        current--;
        _progressController.text = current.toString();
        if (_status == TrackerStatus.completed) {
          _status = TrackerStatus.watching;
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart
        ? _startDate ?? DateTime.now()
        : _endDate ?? DateTime.now();
    final first = isStart ? DateTime(1980) : (_startDate ?? DateTime(1980));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = date;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            _buildHeader(theme),
            const SizedBox(height: 24),

            // Status & Score
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStatusDropdown(theme)),
                const SizedBox(width: 16),
                Expanded(child: _buildScoreField(theme)),
              ],
            ),
            const SizedBox(height: 20),

            // Progress
            _buildProgressSection(theme),
            const SizedBox(height: 20),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    theme,
                    'Started At',
                    _startDate,
                    () => _pickDate(true),
                    () => setState(() => _startDate = DateTime.now()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    theme,
                    'Completed At',
                    _endDate,
                    () => _pickDate(false),
                    () => setState(() => _endDate = DateTime.now()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Buttons
            _buildButtons(theme),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _isLoading,
      builder: (context, loading, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _trackerBadge(theme),
                  const SizedBox(width: 8),
                  Text(
                    loading ? 'Loading...' : 'Tracking Config',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (loading)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    height: 2,
                    width: 80,
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Iconsax.close_circle),
          ),
        ],
      ),
    );
  }

  Widget _trackerBadge(ThemeData theme) {
    final color = widget.tracker == TrackerType.anilist
        ? const Color(0xFF02A9FF)
        : const Color(0xFF2E51A2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.tracker.shortName,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _status,
      onChanged: _handleStatusChange,
      items: TrackerStatus.all
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                TrackerStatus.displayName(s),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          )
          .toList(),
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      isExpanded: true,
    );
  }

  Widget _buildScoreField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _scoreController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Score',
            suffixText: '/ 10',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          onChanged: (_) => setState(() {}),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 2,
            ),
            child: Slider(
              value:
                  double.tryParse(_scoreController.text)?.clamp(0.0, 10.0) ?? 0,
              min: 0,
              max: 10,
              divisions: 100,
              onChanged: (val) => setState(() {
                _scoreController.text = ((val * 10).round() / 10).toString();
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    final total = widget.media.episodes;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _progressController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Progress',
              suffixText: total != null ? '/ $total' : null,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildIncrementButton(Iconsax.minus, _decrementProgress, theme),
        const SizedBox(width: 8),
        _buildIncrementButton(Iconsax.add, _incrementProgress, theme),
      ],
    );
  }

  Widget _buildIncrementButton(
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }

  Widget _buildDateField(
    ThemeData theme,
    String label,
    DateTime? date,
    VoidCallback onTap,
    VoidCallback onToday,
  ) {
    final formatted = date != null
        ? DateFormat.yMMMd().format(date)
        : 'Select Date';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatted),
                const Icon(Iconsax.calendar_1, size: 18),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onToday,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            child: const Text('Today'),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _isSaving,
      builder: (context, saving, _) => Row(
        children: [
          if (_isExistingEntry)
            Expanded(
              flex: 1,
              child: FilledButton.icon(
                onPressed: saving ? null : _remove,
                icon: const Icon(Iconsax.trash),
                label: const Text('Remove'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          if (_isExistingEntry) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Iconsax.save_2),
              label: Text(saving ? 'Saving...' : 'Save'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
