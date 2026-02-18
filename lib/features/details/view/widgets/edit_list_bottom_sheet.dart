import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/shared/providers/anilist_service_provider.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/auth/providers/auth_notifier.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:collection/collection.dart';
import 'package:shonenx/features/details/view_model/local_tracker_notifier.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

/// Bottom sheet for editing anime list entry
class EditListBottomSheet extends ConsumerStatefulWidget {
  final UniversalMedia anime;

  const EditListBottomSheet({super.key, required this.anime});

  @override
  ConsumerState<EditListBottomSheet> createState() =>
      _EditListBottomSheetState();
}

class _EditListBottomSheetState extends ConsumerState<EditListBottomSheet> {
  static const List<String> _statusOptions = [
    'CURRENT',
    'PLANNING',
    'COMPLETED',
    'REPEATING',
    'PAUSED',
    'DROPPED',
  ];

  late String _selectedStatus;
  late TextEditingController _progressController;
  late TextEditingController _scoreController;
  late TextEditingController _repeatsController;
  late TextEditingController _notesController;
  DateTime? _startDate;
  DateTime? _completedDate;
  late bool _isPrivate;

  final ValueNotifier<bool> _isSaving = ValueNotifier(false);
  final ValueNotifier<bool> _isFetching = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _selectedStatus = 'PLANNING';
    _progressController = TextEditingController(text: '0');
    _scoreController = TextEditingController(text: '0');
    _repeatsController = TextEditingController(text: '0');
    _notesController = TextEditingController();
    _isPrivate = false;
    _loadEntry();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scoreController.dispose();
    _repeatsController.dispose();
    _notesController.dispose();
    _isSaving.dispose();
    _isFetching.dispose();
    super.dispose();
  }

  void _updateEntryFields(dynamic entry) {
    setState(() {
      _selectedStatus = entry.status;
      _progressController.text = entry.progress.toString();
      _scoreController.text = entry.score.toString();
      _repeatsController.text = entry.repeat.toString();
      _notesController.text = entry.notes;
      _startDate = entry.startedAt?.toDateTime;
      _completedDate = entry.completedAt?.toDateTime;
      _isPrivate = entry.isPrivate;
    });
  }

  Future<void> _loadEntry() async {
    _isFetching.value = true;
    try {
      final auth = ref.read(authProvider);
      final watchlistNotifier = ref.read(watchlistProvider.notifier);
      final animeRepo = ref.read(animeRepositoryProvider);
      final watchlist = ref.read(watchlistProvider);

      dynamic entry;

      if (auth.isAniListAuthenticated) {
        entry = watchlist.lists.values
            .expand((e) => e)
            .firstWhereOrNull((media) => media.id == widget.anime.id);

        if (entry == null && auth.activePlatform == AuthPlatform.anilist) {
          entry = await animeRepo.getAnimeEntry(int.parse(widget.anime.id));
          if (entry != null) watchlistNotifier.addEntry(entry);
        }
      } else {
        // Local load
        entry = await ref
            .read(localTrackerProvider.notifier)
            .getEntry(widget.anime.id);
      }

      if (entry != null) _updateEntryFields(entry);
    } catch (e) {
      AppLogger.e('Failed to load entry: $e');
    } finally {
      _isFetching.value = false;
    }
  }

  Future<void> _saveChanges() async {
    final auth = ref.read(authProvider);

    _isSaving.value = true;
    try {
      final score = double.tryParse(_scoreController.text) ?? 0.0;
      final progress = int.tryParse(_progressController.text) ?? 0;
      final repeats = int.tryParse(_repeatsController.text) ?? 0;

      if (auth.isAniListAuthenticated) {
        await ref
            .read(anilistServiceProvider)
            .updateUserAnimeList(
              mediaId: int.parse(widget.anime.id),
              status: _selectedStatus,
              score: score,
              private: _isPrivate,
              startedAt: FuzzyDate(
                year: _startDate?.year,
                month: _startDate?.month,
                day: _startDate?.day,
              ),
              completedAt: FuzzyDate(
                year: _completedDate?.year,
                month: _completedDate?.month,
                day: _completedDate?.day,
              ),
              repeat: repeats,
              notes: _notesController.text,
              progress: progress,
            );
        _showSnackBar('Success', 'Anime list updated', ContentType.success);
      } else {
        // Local Save
        await ref
            .read(localTrackerProvider.notifier)
            .saveEntry(
              widget.anime,
              status: _selectedStatus,
              score: score,
              progress: progress,
              repeat: repeats,
              notes: _notesController.text,
              isPrivate: _isPrivate,
              startedAt: _startDate,
              completedAt: _completedDate,
            );
        _showSnackBar('Success', 'Saved to local library', ContentType.success);
      }

      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      AppLogger.e('Error while saving anime list: $e\n$st');
      _showSnackBar(
        'Error',
        'Failed to update anime list',
        ContentType.failure,
      );
    } finally {
      _isSaving.value = false;
    }
  }

  void _showSnackBar(String title, String message, ContentType type) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: title,
            message: message,
            contentType: type,
          ),
        ),
      );
  }

  Future<void> _pickDate(bool isStartDate) async {
    final initial = isStartDate
        ? _startDate ?? DateTime.now()
        : _completedDate ?? DateTime.now();
    final first = isStartDate ? DateTime(1980) : (_startDate ?? DateTime(1980));

    final newDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now(),
    );

    if (newDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = newDate;
          // Ensure completed date is not before start date
          if (_completedDate != null && _completedDate!.isBefore(_startDate!)) {
            _completedDate = null;
          }
        } else {
          _completedDate = newDate;
        }
      });
    }
  }

  void _handleStatusChange(String? newStatus) {
    if (newStatus == null) return;
    setState(() {
      _selectedStatus = newStatus;
      if (newStatus == 'COMPLETED') {
        if (_progressController.text != widget.anime.episodes.toString() &&
            widget.anime.episodes != null) {
          _progressController.text = widget.anime.episodes.toString();
        }
        _completedDate ??= DateTime.now();
        _startDate ??= DateTime.now();
      } else if (newStatus == 'CURRENT') {
        _startDate ??= DateTime.now();
        _completedDate = null;
      }
    });
  }

  void _incrementProgress() {
    int current = int.tryParse(_progressController.text) ?? 0;
    int? total = widget.anime.episodes;
    if (total == null || current < total) {
      setState(() {
        current++;
        _progressController.text = current.toString();
        if (total != null && current == total) {
          _selectedStatus = 'COMPLETED';
          _completedDate ??= DateTime.now();
        } else if (_selectedStatus == 'PLANNING') {
          _selectedStatus = 'CURRENT';
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
        if (_selectedStatus == 'COMPLETED' &&
            (widget.anime.episodes == null ||
                current < widget.anime.episodes!)) {
          _selectedStatus = 'CURRENT';
          _completedDate = null;
        }
      });
    }
  }

  void _setMaxProgress() {
    if (widget.anime.episodes != null) {
      setState(() {
        _progressController.text = widget.anime.episodes.toString();
        _selectedStatus = 'COMPLETED';
        _startDate ??= DateTime.now();
        _completedDate ??= DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStatusDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildScoreSection()),
              ],
            ),
            const SizedBox(height: 24),
            _buildProgressSection(theme),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Started At',
                    _startDate,
                    () => _pickDate(true),
                    () => setState(() => _startDate = DateTime.now()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateField(
                    'Completed At',
                    _completedDate,
                    () => _pickDate(false),
                    () => setState(() => _completedDate = DateTime.now()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Additional Options'),
              shape: const Border(),
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8),
              children: [
                _buildTextField('Total Repeats', _repeatsController),
                const SizedBox(height: 16),
                _buildTextField('Notes', _notesController, maxLines: 3),
                SwitchListTile(
                  title: const Text('Private'),
                  value: _isPrivate,
                  onChanged: (val) => setState(() => _isPrivate = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSaveButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ValueListenableBuilder(
          valueListenable: _isFetching,
          builder: (context, value, child) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value ? 'Syncing Entry...' : 'Edit Entry',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (value)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
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
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.close_circle),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      onChanged: _handleStatusChange,
      items: _statusOptions
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item.toLowerCase().replaceFirst(item[0].toLowerCase(), item[0]),
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

  Widget _buildScoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          'Score',
          _scoreController,
          suffixText: '/ 10',
          onChanged: (val) => setState(() {}), // rebuild slider
        ),
        if (_scoreController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                trackHeight: 2,
              ),
              child: Slider(
                value:
                    double.tryParse(_scoreController.text)?.clamp(0.0, 10.0) ??
                    0,
                min: 0,
                max: 10,
                divisions: 100, // Allow .1 increments effectively
                label: _scoreController.text,
                onChanged: (val) {
                  setState(() {
                    // Round to 1 decimal place
                    _scoreController.text = ((val * 10).round() / 10)
                        .toString();
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme) {
    final total = widget.anime.episodes;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Progress',
                _progressController,
                suffixText: total != null ? '/ $total' : null,
              ),
            ),
            const SizedBox(width: 12),
            _buildIncrementButton(Iconsax.minus, _decrementProgress),
            const SizedBox(width: 8),
            _buildIncrementButton(Iconsax.add, _incrementProgress),
          ],
        ),
        if (total != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _setMaxProgress,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              child: const Text('Set to Max'),
            ),
          ),
      ],
    );
  }

  Widget _buildIncrementButton(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      ),
    );
  }

  Future<void> _deleteEntry() async {
    final auth = ref.read(authProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text(
          'Are you sure you want to delete this entry? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _isSaving.value = true;
    try {
      if (auth.isAniListAuthenticated) {
        final success = await ref
            .read(anilistServiceProvider)
            .deleteUserAnimeList(int.parse(widget.anime.id));
        if (success) {
          _showSnackBar('Success', 'Entry deleted', ContentType.success);
        } else {
          throw Exception('Failed to delete from AniList');
        }
      } else {
        await ref
            .read(localTrackerProvider.notifier)
            .deleteEntry(widget.anime.id);
        _showSnackBar('Success', 'Entry deleted locally', ContentType.success);
      }

      if (mounted) {
        ref.invalidate(watchlistProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      AppLogger.e('Failed to delete entry: $e');
      _showSnackBar('Error', 'Failed to delete entry', ContentType.failure);
    } finally {
      _isSaving.value = false;
    }
  }

  Widget _buildSaveButton(ThemeData theme) {
    return ValueListenableBuilder(
      valueListenable: _isSaving,
      builder: (context, saving, child) {
        return Row(
          children: [
            Expanded(
              flex: 1,
              child: FilledButton.icon(
                onPressed: saving ? null : _deleteEntry,
                icon: const Icon(Iconsax.trash),
                label: const Text('Delete'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
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
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: saving ? null : _saveChanges,
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.save_2),
                label: Text(saving ? 'Saving...' : 'Save Changes'),
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
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? suffixText,
    int maxLines = 1,
    Widget? suffixIcon,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      keyboardType: maxLines == 1
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.multiline,
      inputFormatters:
          maxLines == 1 &&
              label !=
                  'Score' // Allow decimals for score
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        suffixText: suffixText,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDateField(
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
}
