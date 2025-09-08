import 'dart:developer';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:shonenx/core/models/anilist/media.dart';

/// Bottom sheet for editing anime list entry
class EditListBottomSheet extends StatefulWidget {
  final Media anime;

  const EditListBottomSheet({
    super.key,
    required this.anime,
  });

  @override
  State<EditListBottomSheet> createState() => _EditListBottomSheetState();
}

class _EditListBottomSheetState extends State<EditListBottomSheet> {
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = 'PLANNING';
    _progressController = TextEditingController(text: '0');
    _scoreController = TextEditingController(text: '0');
    _repeatsController = TextEditingController(text: '0');
    _notesController = TextEditingController();
    _isPrivate = false;
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scoreController.dispose();
    _repeatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    log('--- Saving Anime Status ---');
    log('Status: $_selectedStatus');
    log('Progress: ${_progressController.text}');
    log('Score: ${_scoreController.text}');
    log('Start Date: $_startDate');
    log('Completed Date: $_completedDate');
    log('Repeats: ${_repeatsController.text}');
    log('Private: $_isPrivate');
    log('Notes: ${_notesController.text}');

    // Simulate network call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
      _showSnackBar(
          'Success', 'Your list has been updated.', ContentType.success);
    }
  }

  void _showSnackBar(String title, String message, ContentType type) {
    if (!mounted) return;
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: type,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  Future<void> _pickDate(bool isStartDate) async {
    final initialDate =
        (isStartDate ? _startDate : _completedDate) ?? DateTime.now();
    final firstDate =
        isStartDate ? DateTime(1980) : (_startDate ?? DateTime(1980));

    final newDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
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
            Text('Edit Entry (WIP)',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
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
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Iconsax.save_2),
              label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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
      {String? suffixText = '', int? maxLines = 1, Widget? suffixIcon}) {
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
          suffixIcon: suffixIcon),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    final formattedDate =
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
        child: Text(formattedDate),
      ),
    );
  }
}
