import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/player/providers/custom_subtitle_provider.dart';
import 'package:shonenx/features/player/domain/subtitle_prefs.dart';
import 'package:shonenx/features/player/providers/subtitle_prefs_provider.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/utils/subtitle_parser.dart';

class CustomSubtitleOverlay extends ConsumerWidget {
  final VideoEngine engine;
  const CustomSubtitleOverlay({super.key, required this.engine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(subtitlePrefsProvider);
    if (!prefs.useCustomSubtitle) return const SizedBox.shrink();

    final cuesAsync = ref.watch(customSubtitleProvider);

    return cuesAsync.when(
      data: (cues) {
        if (cues.isEmpty) return const SizedBox.shrink();
        return _ThrottledSubtitleView(engine: engine, cues: cues, prefs: prefs);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ThrottledSubtitleView extends StatefulWidget {
  final VideoEngine engine;
  final List<SubtitleCue> cues;
  final SubtitlePrefs prefs;

  const _ThrottledSubtitleView({
    required this.engine,
    required this.cues,
    required this.prefs,
  });

  @override
  State<_ThrottledSubtitleView> createState() => _ThrottledSubtitleViewState();
}

class _ThrottledSubtitleViewState extends State<_ThrottledSubtitleView> {
  List<SubtitleCue> _activeCues = const [];

  @override
  void initState() {
    super.initState();
    widget.engine.positionNotifier.addListener(_onPositionChanged);
    _updateActiveCues();
  }

  @override
  void didUpdateWidget(covariant _ThrottledSubtitleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.engine != widget.engine) {
      oldWidget.engine.positionNotifier.removeListener(_onPositionChanged);
      widget.engine.positionNotifier.addListener(_onPositionChanged);
      _updateActiveCues();
    } else if (oldWidget.cues != widget.cues) {
      _updateActiveCues();
    }
  }

  @override
  void dispose() {
    widget.engine.positionNotifier.removeListener(_onPositionChanged);
    super.dispose();
  }

  void _onPositionChanged() {
    _updateActiveCues();
  }

  void _updateActiveCues() {
    final position = widget.engine.positionNotifier.value;
    final newCues = _findActiveCues(widget.cues, position);
    if (!_areCuesEqual(_activeCues, newCues)) {
      setState(() {
        _activeCues = newCues;
      });
    }
  }

  static bool _areCuesEqual(List<SubtitleCue> a, List<SubtitleCue> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) {
        if (a[i].start != b[i].start ||
            a[i].end != b[i].end ||
            a[i].text != b[i].text ||
            a[i].alignment != b[i].alignment) {
          return false;
        }
      }
    }
    return true;
  }

  static List<SubtitleCue> _findActiveCues(
    List<SubtitleCue> cues,
    Duration position,
  ) {
    if (cues.isEmpty) return [];

    // Binary search for the first cue that starts AFTER the current position
    int low = 0;
    int high = cues.length - 1;
    int insertIndex = cues.length;

    while (low <= high) {
      int mid = low + ((high - low) >> 1);
      if (cues[mid].start > position) {
        insertIndex = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    // Iterate backwards to find all overlapping cues
    final List<SubtitleCue> activeCues = [];
    for (int i = insertIndex - 1; i >= 0; i--) {
      final cue = cues[i];
      if (cue.end >= position) {
        activeCues.add(cue);
      }
      // Stop searching if the cue started more than 60 seconds ago
      if (position.inSeconds - cue.start.inSeconds > 60) {
        break;
      }
    }

    return activeCues.reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_activeCues.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final responsiveFontSize = getResponsiveSubtitleSize(
      screenWidth,
      widget.prefs.fontSize,
    );

    final Map<Alignment, List<SubtitleCue>> groupedCues = {};
    for (final cue in _activeCues) {
      groupedCues.putIfAbsent(cue.alignment, () => []).add(cue);
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: SafeArea(
          child: Stack(
            children: groupedCues.entries.map((entry) {
              final alignment = entry.key;
              final cuesForAlignment = entry.value;

              return Align(
                alignment: alignment,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: alignment.y == 1.0 ? widget.prefs.bottomPadding : 0,
                    top: alignment.y == -1.0 ? widget.prefs.bottomPadding : 0,
                    left: 24,
                    right: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: cuesForAlignment
                        .expand(
                          (cue) => SubtitleParser.cleanSubtitleText(cue.text)
                              .split('\n')
                              .map((l) => l.replaceAll('\r', ''))
                              .where((l) => l.trim().isNotEmpty)
                              .map(
                                (line) => Container(
                                  margin: const EdgeInsets.only(bottom: 4.0),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.prefs.padding * 1.5,
                                    vertical: widget.prefs.padding * 0.5,
                                  ),
                                  decoration:
                                      widget.prefs.backgroundColor != 0x00000000
                                      ? BoxDecoration(
                                          color: widget.prefs.bg,
                                          borderRadius: BorderRadius.circular(
                                            4.0,
                                          ),
                                        )
                                      : null,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (getSubtitleStrokeStyle(
                                            widget.prefs,
                                            responsiveFontSize,
                                          ) !=
                                          null)
                                        Text(
                                          line,
                                          textAlign: TextAlign.center,
                                          style: getSubtitleStrokeStyle(
                                            widget.prefs,
                                            responsiveFontSize,
                                          ),
                                        ),
                                      Text(
                                        line,
                                        textAlign: TextAlign.center,
                                        style: getSubtitleTextStyle(
                                          widget.prefs,
                                          responsiveFontSize,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        )
                        .toList(),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
