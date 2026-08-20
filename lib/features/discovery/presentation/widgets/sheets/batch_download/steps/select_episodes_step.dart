import 'package:flutter/material.dart';

import 'package:shonenx/shared/widgets/app_dialog.dart';

import '../batch_download_sheet.dart';

class SelectEpisodesStep extends StatelessWidget {
  final BatchDownloadSheetState state;

  const SelectEpisodesStep({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      key: const ValueKey('selectEpisodes'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPresetPill('Select All', _selectAll, cs),
              const SizedBox(width: 8),
              _buildPresetPill('Unwatched', _selectUnwatched, cs),
              const SizedBox(width: 8),
              _buildPresetPill('Range', () => _showRangeDialog(context), cs),
              const SizedBox(width: 8),
              _buildPresetPill('Next 5', () => _selectNext(5), cs),
              const SizedBox(width: 8),
              _buildPresetPill('Next 10', () => _selectNext(10), cs),
              const SizedBox(width: 8),
              _buildPresetPill('Clear', _clearSelection, cs),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Selected Episodes',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${state.selectedEpisodes.length} / ${state.widget.episodes.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: state.widget.episodes.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: cs.outlineVariant.withValues(alpha: 0.15),
            ),
            itemBuilder: (context, index) {
              final ep = state.widget.episodes[index];
              final isSelected = state.selectedEpisodes.contains(ep);
              final isWatched = ep.number <= state.widget.watchedProgress;
              final epNumStr = ep.number.toString().contains('.0')
                  ? ep.number.toInt().toString()
                  : ep.number.toString();

              return InkWell(
                onTap: () {
                  state.updateState(() {
                    if (isSelected) {
                      state.selectedEpisodes.remove(ep);
                    } else {
                      state.selectedEpisodes.add(ep);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (checked) {
                          state.updateState(() {
                            if (checked == true) {
                              state.selectedEpisodes.add(ep);
                            } else {
                              state.selectedEpisodes.remove(ep);
                            }
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ep.title?.isNotEmpty == true
                                  ? '${ep.title}'
                                  : 'Episode $epNumStr',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Episode $epNumStr',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                                if (isWatched) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Watched',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: cs.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: state.selectedEpisodes.isEmpty
              ? null
              : state.goToChoosePreference,
          icon: const Icon(Icons.settings_suggest_rounded, size: 20),
          label: Text(
            'Configure Quality & Server (${state.selectedEpisodes.length})',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetPill(String label, VoidCallback onTap, ColorScheme cs) {
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: cs.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  void _selectAll() {
    state.updateState(
      () => state.selectedEpisodes = state.widget.episodes.toSet(),
    );
  }

  void _selectUnwatched() {
    state.updateState(() {
      state.selectedEpisodes = state.widget.episodes
          .where((e) => e.number > state.widget.watchedProgress)
          .toSet();
    });
  }

  void _selectNext(int count) {
    final unwatched = state.widget.episodes
        .where((e) => e.number > state.widget.watchedProgress)
        .toList();
    final list = unwatched.isNotEmpty ? unwatched : state.widget.episodes;
    state.updateState(() {
      state.selectedEpisodes = list.take(count).toSet();
    });
  }

  void _clearSelection() {
    state.updateState(() => state.selectedEpisodes.clear());
  }

  void _showRangeDialog(BuildContext context) {
    final sorted = state.widget.episodes.toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    if (sorted.isEmpty) return;

    final unwatched = sorted.where(
      (e) => e.number > state.widget.watchedProgress,
    );
    final initialStart = unwatched.isNotEmpty
        ? unwatched.first.number
        : sorted.first.number;
    final initialEnd = sorted.last.number;

    final startCtrl = TextEditingController(
      text: initialStart.toString().contains('.0')
          ? initialStart.toInt().toString()
          : initialStart.toString(),
    );
    final endCtrl = TextEditingController(
      text: initialEnd.toString().contains('.0')
          ? initialEnd.toInt().toString()
          : initialEnd.toString(),
    );

    AppDialog.show(
      context: context,
      title: 'Select Episode Range',
      child: StatefulBuilder(
        builder: (context, setState) {
          final cs = Theme.of(context).colorScheme;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter start and end episode numbers (available: ${sorted.first.number} to ${sorted.last.number}):',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'From Episode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '—',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'To Episode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final start =
                double.tryParse(startCtrl.text.trim()) ?? initialStart;
            final end = double.tryParse(endCtrl.text.trim()) ?? initialEnd;
            final minNum = start <= end ? start : end;
            final maxNum = start <= end ? end : start;

            final matched = sorted
                .where((e) => e.number >= minNum && e.number <= maxNum)
                .toSet();
            state.updateState(() {
              state.selectedEpisodes = matched;
            });
            Navigator.of(context).pop();
          },
          child: const Text('Apply Range'),
        ),
      ],
    );
  }
}
