import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:shonenx/core/network/cf_client.dart';
import 'package:shonenx/features/player/presentation/widgets/custom_subtitle_overlay.dart';
import 'package:shonenx/features/player/providers/custom_subtitle_provider.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';
import 'package:shonenx/shared/models/ui_style_enums.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';

final _debugSubtitleContentProvider = StateProvider<String>(
  (ref) => _testBasicSrt,
);
final _debugPlaybackPositionProvider = StateProvider<Duration>(
  (ref) => Duration.zero,
);
final _debugIsPlayingProvider = StateProvider<bool>((ref) => false);
final _debugActiveCueProvider = StateProvider<SubtitleCue?>((ref) => null);
final _debugIsLoadingProvider = StateProvider<bool>((ref) => false);
final _debugSplitRatioProvider = StateProvider<double>((ref) => 0.5);

final _debugMaxDurationProvider = Provider<Duration>((ref) {
  final cuesAsync = ref.watch(customSubtitleProvider);
  if (cuesAsync.hasValue &&
      cuesAsync.value != null &&
      cuesAsync.value!.isNotEmpty) {
    final maxMs = cuesAsync.value!
        .map((c) => c.end.inMilliseconds)
        .reduce((a, b) => a > b ? a : b);
    return Duration(milliseconds: maxMs + 2000);
  }
  return const Duration(seconds: 30);
});

const _testBasicSrt = '''
1
00:00:01,000 --> 00:00:03,500
This is a basic subtitle.

2
00:00:04,000 --> 00:00:06,000
It has multiple lines
to test wrapping.

3
00:00:06,500 --> 00:00:08,000
End of basic test.

4
00:00:15,000 --> 00:00:18,000
This cue appears at 15 seconds.

5
00:00:25,000 --> 00:00:28,000
Final cue at 25 seconds!
''';

const _testOverlappingCues = '''
1
00:00:01,000 --> 00:00:05,000
Cue 1 (1s to 5s)

2
00:00:02,000 --> 00:00:04,000
Cue 2 (2s to 4s) overlapping!
(Should expose binary search limitation)

3
00:00:12,000 --> 00:00:18,000
Cue 3 (12s to 18s)

4
00:00:16,000 --> 00:00:22,000
Cue 4 (16s to 22s) overlapping with Cue 3!
''';

const _testAssTags = r'''
1
00:00:01,000 --> 00:00:04,000
{\an8}{\pos(400,100)}Top aligned ASS tag text

2
00:00:04,500 --> 00:00:07,000
{\c&H0000FF&}Blue text with ASS color tag

3
00:00:07,500 --> 00:00:10,000
<i>HTML italics</i> and <b>HTML bold</b>

4
00:00:18,500 --> 00:00:22,000
{\u1}Underlined ASS text{\u0} at 18s

5
00:00:26,000 --> 00:00:29,000
{\fad(500,500)}Fading text at 26s
''';

const _testFastCues = '''
1
00:00:01,000 --> 00:00:01,200
Flash 1

2
00:00:01,200 --> 00:00:01,400
Flash 2

3
00:00:01,400 --> 00:00:01,600
Flash 3

4
00:00:28,000 --> 00:00:28,100
Flash 4 at end
''';

class SubtitleDebugScreen extends ConsumerStatefulWidget {
  const SubtitleDebugScreen({super.key});

  @override
  ConsumerState<SubtitleDebugScreen> createState() =>
      _SubtitleDebugScreenState();
}

class _SubtitleDebugScreenState extends ConsumerState<SubtitleDebugScreen> {
  Timer? _playbackTimer;
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final isPlaying = ref.read(_debugIsPlayingProvider);
    if (isPlaying) {
      _playbackTimer?.cancel();
      ref.read(_debugIsPlayingProvider.notifier).state = false;
    } else {
      ref.read(_debugIsPlayingProvider.notifier).state = true;
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        final pos = ref.read(_debugPlaybackPositionProvider);
        final maxDur = ref.read(_debugMaxDurationProvider);
        if (pos >= maxDur) {
          ref.read(_debugPlaybackPositionProvider.notifier).state =
              Duration.zero;
        } else {
          ref.read(_debugPlaybackPositionProvider.notifier).state =
              pos + const Duration(milliseconds: 100);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Subtitle Renderer Debug',
      body: ProviderScope(
        overrides: [
          customSubtitleProvider.overrideWith((ref) async {
            final content = ref.watch(_debugSubtitleContentProvider);
            // Offload parsing to an isolate to prevent UI freezing on huge files
            final cues = await compute(SubtitleParser.parseString, content);
            return cues;
          }),
          videoEngineStateProvider.overrideWith(() {
            return _MockEngineStateNotifier();
          }),
        ],
        child: _SubtitleDebugView(
          urlController: _urlController,
          onTogglePlayback: _togglePlayback,
        ),
      ),
    );
  }
}

class _MockEngineStateNotifier extends EngineStateNotifier {
  @override
  EngineState build() {
    // Listen to the manual position provider and update EngineState
    ref.listen(_debugPlaybackPositionProvider, (prev, next) {
      updateState(position: next);
    });
    return EngineState(
      position: ref.read(_debugPlaybackPositionProvider),
      duration: ref.watch(_debugMaxDurationProvider),
    );
  }
}

class _SubtitleDebugView extends ConsumerWidget {
  final TextEditingController urlController;
  final VoidCallback onTogglePlayback;
  const _SubtitleDebugView({
    required this.urlController,
    required this.onTogglePlayback,
  });

  Future<void> _loadUrl(BuildContext context, WidgetRef ref) async {
    String url = urlController.text.trim();
    if (url.isEmpty) return;

    final uri = Uri.parse(url);
    final cacheBuster = 'cb=${DateTime.now().millisecondsSinceEpoch}';
    if (uri.query.isEmpty) {
      url = '$url?$cacheBuster';
    } else {
      url = '$url&$cacheBuster';
    }

    ref.read(_debugIsLoadingProvider.notifier).state = true;
    try {
      final response = await CFClient.instance.get(url);
      if (response.statusCode == 200) {
        final content = utf8.decode(response.bodyBytes, allowMalformed: true);
        ref.read(_debugSubtitleContentProvider.notifier).state = content;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loaded from URL successfully!')),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load URL: $e')));
      }
    } finally {
      ref.read(_debugIsLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _loadFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'vtt', 'ass', 'ssa'],
      );
      if (result != null && result.files.single.path != null) {
        ref.read(_debugIsLoadingProvider.notifier).state = true;
        final file = File(result.files.single.path!);
        final fileContent = await file.readAsString();
        ref.read(_debugSubtitleContentProvider.notifier).state = fileContent;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load file: $e')));
      }
    } finally {
      ref.read(_debugIsLoadingProvider.notifier).state = false;
    }
  }

  void _loadTest(WidgetRef ref, String payload) {
    ref.read(_debugSubtitleContentProvider.notifier).state = payload;
  }

  Widget _buildPlayer(BuildContext context, Duration pos) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          Center(
            child: Text(
              'Simulated Player Background\n\nActive Cues rendered via CustomSubtitleOverlay',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          const CustomSubtitleOverlay(),
          Positioned(
            top: 16,
            left: 16,
            child: Text(
              _formatDuration(pos),
              style: const TextStyle(
                color: Colors.redAccent,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCuePanel(WidgetRef ref, BuildContext context) {
    final active = ref.watch(_debugActiveCueProvider);
    if (active == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        ),
        child: const Text(
          'No active cue at this timestamp.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Start: ${_formatDuration(active.start)}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              Text(
                'End: ${_formatDuration(active.end)}',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              Text(
                'Dur: ${active.end.inMilliseconds - active.start.inMilliseconds}ms',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Raw Parsed Text:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            active.text,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    Duration pos,
    bool isPlaying,
    SubtitleCue? activeCue,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 0,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Source Input (Compact)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: urlController,
                        decoration: InputDecoration(
                          hintText: 'Enter URL or load local file',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              GlobalUI.uiRoundness,
                            ),
                          ),
                          suffixIcon: ref.watch(_debugIsLoadingProvider)
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download_rounded),
                                  tooltip: 'Load from URL',
                                  onPressed: () => _loadUrl(context, ref),
                                ),
                        ),
                        onSubmitted: (_) => _loadUrl(context, ref),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.folder_open_rounded),
                      label: const Text('Local'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            GlobalUI.uiRoundness,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () => _loadFile(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Test Payloads
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text(
                        'Tests:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Basic'),
                        onPressed: () => _loadTest(ref, _testBasicSrt),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Overlap'),
                        onPressed: () => _loadTest(ref, _testOverlappingCues),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('ASS/HTML'),
                        onPressed: () => _loadTest(ref, _testAssTags),
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Fast Cues'),
                        onPressed: () => _loadTest(ref, _testFastCues),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Playback Controls (Minimal)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      GlobalUI.uiRoundness * 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        onPressed: onTogglePlayback,
                      ),
                      Expanded(
                        child: Consumer(
                          builder: (context, ref, child) {
                            final maxDur = ref.watch(_debugMaxDurationProvider);
                            final maxMs = maxDur.inMilliseconds.toDouble();
                            return Slider(
                              value: pos.inMilliseconds.toDouble().clamp(
                                0,
                                maxMs,
                              ),
                              min: 0,
                              max: maxMs,
                              label: _formatDuration(pos),
                              onChanged: (val) {
                                ref
                                    .read(
                                      _debugPlaybackPositionProvider.notifier,
                                    )
                                    .state = Duration(
                                  milliseconds: val.toInt(),
                                );
                              },
                            );
                          },
                        ),
                      ),

                      Text(
                        _formatDuration(pos),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Active Cue Debug',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildActiveCuePanel(ref, context),

                const SizedBox(height: 16),
                const Text(
                  'Raw Subtitle Buffer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
              ),
              child: ref
                  .watch(customSubtitleProvider)
                  .when(
                    data: (cues) {
                      if (cues.isEmpty) {
                        final rawText = ref.watch(
                          _debugSubtitleContentProvider,
                        );
                        final lines = rawText.split('\n');
                        return ListView.builder(
                          itemCount: lines.length,
                          itemBuilder: (context, index) {
                            final line = lines[index];
                            final displayText = line.length > 500
                                ? '${line.substring(0, 250)} ... [truncated ${line.length - 500} chars] ... ${line.substring(line.length - 250)}'
                                : line;
                            return Text(
                              displayText,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            );
                          },
                        );
                      }
                      return ListView.builder(
                        itemCount: cues.length,
                        itemBuilder: (context, index) {
                          final cue = cues[index];
                          final isActive = activeCue == cue;
                          return InkWell(
                            onTap: () {
                              ref
                                  .read(_debugPlaybackPositionProvider.notifier)
                                  .state = cue
                                  .start;
                            },
                            child: Container(
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 8,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_formatDuration(cue.start)} --> ${_formatDuration(cue.end)}',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      color: Colors.blueAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    cue.text,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                    error: (e, st) {
                      final rawText = ref.watch(_debugSubtitleContentProvider);
                      final lines = rawText.split('\n');
                      return ListView.builder(
                        itemCount: lines.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Text(
                              'Error parsing: $e\n',
                              style: const TextStyle(color: Colors.red),
                            );
                          }
                          if (index == 1) return const Divider();
                          final line = lines[index - 2];
                          final displayText = line.length > 500
                              ? '${line.substring(0, 250)} ... [truncated ${line.length - 500} chars] ... ${line.substring(line.length - 250)}'
                              : line;
                          return Text(
                            displayText,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 11,
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuesAsync = ref.watch(customSubtitleProvider);
    final pos = ref.watch(_debugPlaybackPositionProvider);
    final isPlaying = ref.watch(_debugIsPlayingProvider);
    final splitRatio = ref.watch(_debugSplitRatioProvider);

    // Manual active cue calculation for debug panel
    SubtitleCue? activeCue;
    if (cuesAsync.hasValue) {
      final cues = cuesAsync.value!;
      for (final cue in cues) {
        if (pos >= cue.start && pos <= cue.end) {
          activeCue = cue;
          break; // First match, simulating binary search behavior
        }
      }
    }

    // Schedule microtask to update active cue for debug panel without building during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ref.read(_debugActiveCueProvider.notifier).state = activeCue;
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: (splitRatio * 100).toInt(),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildPlayer(context, pos),
                  ),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeColumn,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    final current = ref.read(_debugSplitRatioProvider);
                    final next =
                        (current + details.delta.dx / constraints.maxWidth)
                            .clamp(0.2, 0.8);
                    ref.read(_debugSplitRatioProvider.notifier).state = next;
                  },
                  child: Container(
                    width: 16,
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 2,
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: ((1 - splitRatio) * 100).toInt(),
                child: _buildControls(context, ref, pos, isPlaying, activeCue),
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildPlayer(context, pos),
            Expanded(
              child: _buildControls(context, ref, pos, isPlaying, activeCue),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String threeDigits(int n) => n.toString().padLeft(3, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String threeDigitMs = threeDigits(duration.inMilliseconds.remainder(1000));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds.$threeDigitMs";
  }
}
