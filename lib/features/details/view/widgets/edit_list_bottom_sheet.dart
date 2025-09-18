import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/core/anilist/services/anilist_service.dart';
import 'package:shonenx/core/models/anilist/fuzzy_date.dart';
import 'package:shonenx/core/models/anilist/media.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/watchlist/view_model/watchlist_notifier.dart';
import 'package:collection/collection.dart';
import 'package:shonenx/shared/providers/anime_repo_provider.dart';

/// Bottom sheet for editing anime list entry
class EditListBottomSheet extends ConsumerStatefulWidget {
  final Media anime;

  const EditListBottomSheet({
    super.key,
    required this.anime,
  });

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
    'DROPPED'
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
    _selectedStatus = entry.status;
    _progressController.text = entry.progress.toString();
    _scoreController.text = entry.score.toString();
    _repeatsController.text = entry.repeat.toString();
    _notesController.text = entry.notes;
    _startDate = entry.startedAt?.toDateTime;
    _completedDate = entry.completedAt?.toDateTime;
    _isPrivate = entry.isPrivate;
  }

  Future<void> _loadEntry() async {
    _isFetching.value = true;
    try {
      final auth = ref.read(authProvider);
      if (auth.authPlatform == null) {
        _showSnackBar(
            'Login Required', 'Please login first!', ContentType.failure);
        return;
      }

      final watchlistNotifier = ref.read(watchlistProvider.notifier);
      final animeRepo = ref.read(animeRepositoryProvider);
      final watchlist = ref.read(watchlistProvider);

      dynamic entry = watchlist.lists.values
          .expand((e) => e)
          .firstWhereOrNull((media) => media.id == widget.anime.id);

      if (entry == null && auth.authPlatform == AuthPlatform.anilist) {
        entry = await animeRepo.getAnimeEntry(widget.anime.id!);
        if (entry != null) watchlistNotifier.addEntry(entry);
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
    if (auth.authPlatform == null) {
      _showSnackBar(
          'Login Required', 'Please login first!', ContentType.failure);
      return;
    }

    _isSaving.value = true;
    try {
      final score = double.tryParse(_scoreController.text) ?? 0.0;
      final progress = int.tryParse(_progressController.text) ?? 0;
      final repeats = int.tryParse(_repeatsController.text) ?? 0;

      if (auth.authPlatform == AuthPlatform.anilist) {
        await ref.read(anilistServiceProvider).updateUserAnimeList(
              mediaId: widget.anime.id!,
              status: _selectedStatus,
              score: score,
              private: _isPrivate,
              startedAt: FuzzyDateInput(
                year: _startDate?.year,
                month: _startDate?.month,
                day: _startDate?.day,
              ),
              completedAt: FuzzyDateInput(
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
        _showSnackBar(
            'Info', 'MAL support not implemented yet', ContentType.warning);
      }

      if (mounted) Navigator.pop(context);
    } catch (e, st) {
      AppLogger.e('Error while saving anime list: $e\n$st');
      _showSnackBar(
          'Error', 'Failed to update anime list', ContentType.failure);
    } finally {
      _isSaving.value = false;
    }
  }

  void _showSnackBar(String title, String message, ContentType type) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: title,
          message: message,
          contentType: type,
        ),
      ));
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
          if (_completedDate != null && _completedDate!.isBefore(_startDate!)) {
            _completedDate = null;
          }
        } else {
          _completedDate = newDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalEpisodes = widget.anime.episodes;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ValueListenableBuilder(
                  valueListenable: _isFetching,
                  builder: (context, value, child) => value
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text('Syncing Entry...',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text('Edit Entry',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                )
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStatusDropdown()),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildTextField('Score', _scoreController,
                        suffixText: '/ 10')),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Progress', _progressController,
                suffixText: totalEpisodes != null ? '/ $totalEpisodes' : 'eps',
                suffixIcon: IconButton(
                  icon: const Icon(Iconsax.add_circle),
                  onPressed: () {
                    int current = int.tryParse(_progressController.text) ?? 0;
                    if (totalEpisodes == null || current < totalEpisodes) {
                      _progressController.text = '${current + 1}';
                    }
                  },
                )),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _buildDateField(
                        'Started At', _startDate, () => _pickDate(true))),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildDateField('Completed At', _completedDate,
                        () => _pickDate(false))),
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
            FilledButton.icon(
              onPressed: _isSaving.value ? null : () => _saveChanges(),
              icon: _isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Iconsax.save_2),
              label: Text(_isSaving.value ? 'Saving...' : 'Save Changes'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      onChanged: (value) {
        if (value != null) setState(() => _selectedStatus = value);
      },
      items: _statusOptions
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item
                    .toLowerCase()
                    .replaceFirst(item[0].toLowerCase(), item[0])),
              ))
          .toList(),
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? suffixText, int maxLines = 1, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType:
          maxLines == 1 ? TextInputType.number : TextInputType.multiline,
      inputFormatters:
          maxLines == 1 ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        suffixText: suffixText,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    final formatted =
        date != null ? DateFormat.yMMMd().format(date) : 'Select Date';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(formatted),
      ),
    );
  }
}
