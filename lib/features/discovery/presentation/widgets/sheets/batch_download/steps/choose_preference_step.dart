import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shonenx/core/services/one_dm_service.dart';

import '../batch_download_sheet.dart';

class ChoosePreferenceStep extends StatelessWidget {
  final BatchDownloadSheetState state;

  const ChoosePreferenceStep({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isFallback = state.currentStep == BatchStep.preferenceFallbackPrompt;
    final epNumStr =
        state.referenceEpisode?.number.toString().contains('.0') == true
        ? state.referenceEpisode?.number.toInt().toString()
        : state.referenceEpisode?.number.toString();

    return Column(
      key: const ValueKey('choosePreference'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isFallback
                ? cs.errorContainer.withValues(alpha: 0.35)
                : cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                isFallback
                    ? Icons.warning_amber_rounded
                    : Icons.auto_awesome_rounded,
                color: isFallback ? cs.error : cs.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFallback
                          ? 'Preference Missing for Episode $epNumStr'
                          : 'Template Reference: Episode $epNumStr',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isFallback ? cs.error : cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isFallback
                          ? 'Please choose a new server & quality for the remaining ${state.sortedSelected.length - state.currentIndex} episodes.'
                          : 'Select your preferred server and quality for all ${state.selectedEpisodes.length} selected episodes.',
                      style: textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                  Text(
                    'SELECT SERVER',
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (state.serversError != null)
                    Text(
                      'Error loading servers: ${state.serversError}',
                      style: TextStyle(color: cs.error),
                    )
                  else if (state.availableServers == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (state.availableServers!.isEmpty)
                    const Text('No servers available.')
                  else if (state.availableServers!.length == 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: cs.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Only 1 server available: ${state.availableServers!.first.name} • ${state.availableServers!.first.type.displayName} (Auto-selected)',
                              style: TextStyle(
                                color: cs.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: state.availableServers!.map((server) {
                        final isSelected = state.selectedServer == server;
                        return ChoiceChip(
                          label: Text(
                            '${server.name} • ${server.type.displayName}',
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (selected) {
                            if (selected && state.referenceEpisode != null) {
                              state.fetchStreamsForReference(
                                state.referenceEpisode!,
                                server,
                              );
                            }
                          },
                          selectedColor: cs.primaryContainer,
                          backgroundColor: cs.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected ? cs.primary : Colors.transparent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 20),
                Text(
                  'SELECT VIDEO QUALITY',
                  style: textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 10),
                if (state.loadingStreams)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state.streamsError != null)
                  Text(
                    'Error loading qualities: ${state.streamsError}',
                    style: TextStyle(color: cs.error),
                  )
                else if (state.availableStreams == null ||
                    state.availableStreams!.isEmpty)
                  Text(
                    'No stream links found for this server.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.availableStreams!.map((stream) {
                      final isSelected = state.selectedStream == stream;
                      return ChoiceChip(
                        label: Text(
                          stream.quality,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            state.updateState(
                              () => state.selectedStream = stream,
                            );
                          }
                        },
                        selectedColor: cs.primaryContainer,
                        backgroundColor: cs.surfaceContainerHighest.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? cs.primary : Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Builder(
          builder: (context) {
            final isOneDMInstalledAsync = state.ref.watch(
              isOneDMInstalledProvider,
            );
            final isOneDMInstalled = isOneDMInstalledAsync.value ?? false;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed:
                      (state.selectedServer == null ||
                          state.selectedStream == null)
                      ? null
                      : () => state.startQueueLoop(fromIndexZero: !isFallback),
                  icon: Icon(
                    isFallback
                        ? Icons.play_arrow_rounded
                        : Icons.download_rounded,
                  ),
                  label: Text(
                    isFallback
                        ? 'Resume Downloading'
                        : 'Start Batch Download (${state.selectedEpisodes.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isFallback) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => state.updateState(
                            () => state.currentStep = BatchStep.selectEpisodes,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      if (isOneDMInstalled && Platform.isAndroid)
                        const SizedBox(width: 12),
                    ],
                    if (isOneDMInstalled && Platform.isAndroid)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              (state.selectedServer == null ||
                                  state.selectedStream == null)
                              ? null
                              : () => state.startQueueLoop(
                                  fromIndexZero: !isFallback,
                                  overrideOneDM: true,
                                ),
                          icon: Icon(
                            Icons.cloud_download_outlined,
                            size: 18,
                            color: cs.primary,
                          ),
                          label: const Text('1DM Batch'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
      ],
    );
  }
}
