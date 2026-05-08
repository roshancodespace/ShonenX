import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episode_list_panel.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/player_screen.dart';
import 'package:shonenx/features/player/presentation/widgets/progress_bar.dart';
import 'package:shonenx/features/player/providers/active_engine_provider.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class BottomControls extends StatefulWidget {
  final bool showControls;
  final Function onToggleLockControls;
  final VideoEngine engine;
  final PlayerState playerState;
  final PlayerController controller;
  final ThemeData theme;
  final AniSkipArgs? aniskipArgs;
  final PlayerParams? params;

  const BottomControls({
    super.key,
    required this.showControls,
    required this.onToggleLockControls,
    required this.engine,
    required this.playerState,
    required this.controller,
    required this.theme,
    this.aniskipArgs,
    this.params,
  });

  @override
  State<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends State<BottomControls> {
  double? _dragingValue;

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedPositioned(
      duration: Durations.medium2,
      curve: Curves.fastEaseInToSlowEaseOut,
      bottom: widget.showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 20, top: 40),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.3),
              Colors.black,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProgressBar(
              aniskipArgs: widget.aniskipArgs,
              engine: widget.engine,
              draggingValue: _dragingValue,
              onDragStart: (value) => setState(() => _dragingValue = value),
              onChanged: (value) => setState(() => _dragingValue = value),
              onDragEnd: (value) {
                widget.engine
                    .seekTo(Duration(seconds: value.toInt()))
                    .then((_) => setState(() => _dragingValue = null));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildActionIcon(
                    Icons.lock_outline_rounded,
                    () => widget.onToggleLockControls(),
                  ),
                  const SizedBox(width: 16),
                  _buildBottomSheetTrigger(
                    context: context,
                    value: widget.playerState.activeSubtitle,
                    items: widget.playerState.subtitles,
                    itemLabel: (s) => s.language,
                    onChanged: (v) => widget.controller.changeSubtitle(v),
                    isDisabled: widget.playerState.subtitles.isEmpty,
                    withBadge: false,
                    displayWidget: Badge(
                      label: Text(
                        widget.playerState.subtitles.length.toString(),
                      ),
                      isLabelVisible: widget.playerState.subtitles.isNotEmpty,
                      backgroundColor: widget.theme.colorScheme.primary,
                      textColor: widget.theme.colorScheme.onPrimary,
                      child:
                          widget.playerState.subtitles.isEmpty ||
                              widget.playerState.activeSubtitle == null
                          ? Icon(
                              Icons.subtitles_off_outlined,
                              color: widget.playerState.subtitles.isEmpty
                                  ? Colors.white54
                                  : Colors.white,
                            )
                          : const Icon(Icons.subtitles_outlined),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (widget.params != null)
                    _buildActionIcon(
                      Icons.format_list_bulleted_rounded,
                      () => _showEpisodePanel(context),
                    ),
                  const SizedBox(width: 24),
                  Consumer(
                    builder: (context, ref, child) {
                      final position = ref.watch(
                        engineStateProvider.select((s) => s.position),
                      );
                      final duration = ref.watch(
                        engineStateProvider.select((s) => s.duration),
                      );

                      return Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: widget.theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  if (widget.playerState.activeServer?.type !=
                      ServerType.unknown)
                    _buildActionButton(
                      displayText:
                          widget.playerState.activeServer?.type ==
                              ServerType.dub
                          ? 'DUB'
                          : 'SUB',
                      onTap: () => widget.controller.changeServerType(),
                      isHighlighted: true,
                      theme: widget.theme,
                    ),
                  const SizedBox(width: 20),
                  _buildBottomSheetTrigger<VideoServer>(
                    context: context,
                    value: widget.playerState.activeServer,
                    items: widget.playerState.servers,
                    itemLabel: (s) => '[ ${s.id} ] ${s.name}',
                    onChanged: (v) => widget.controller.changeServer(v),
                    displayText:
                        widget.playerState.activeServer?.id ?? 'Default',
                    badgeBuilder: (s) {
                      if (s.type == ServerType.unknown) {
                        return null;
                      }
                      final isDub = s.type == ServerType.dub;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDub
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isDub ? 'DUB' : 'SUB',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDub
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildBottomSheetTrigger<VideoStream>(
                    context: context,
                    value: widget.playerState.activeStream,
                    items: widget.playerState.streams,
                    itemLabel: (s) => s.quality,
                    onChanged: (v) => widget.controller.changeStream(v),
                    displayText:
                        widget.playerState.activeStream?.quality ?? 'Auto',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEpisodePanel(BuildContext context) {
    final params = widget.params!;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Episodes',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.38,
          height: double.infinity,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                Expanded(
                  child: EpisodeListPanel(
                    media: params.media,
                    currentEpisodeNumber: params.episode.number,
                    onEpisodeTap: (episode, sourceInfo) {
                      Navigator.of(context).pop();
                      context.pushReplacement(
                        '/player',
                        extra: PlayerParams(
                          media: params.media,
                          episode: episode,
                          sourceInfo: sourceInfo,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildActionButton({
    required String displayText,
    required VoidCallback onTap,
    required bool isHighlighted,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        alignment: Alignment.center,
        padding: isHighlighted
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : EdgeInsets.zero,
        decoration: isHighlighted
            ? BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Text(
          displayText,
          style: TextStyle(
            color: isHighlighted
                ? theme.colorScheme.onPrimaryContainer
                : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSheetTrigger<T>({
    required BuildContext context,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T) onChanged,
    bool? isDisabled,
    bool? withBadge = true,
    String? displayText,
    Widget? displayWidget,
    bool isHighlighted = false,
    Widget? Function(T)? badgeBuilder,
  }) {
    return Badge(
      label: Text(items.length.toString()),
      isLabelVisible: (withBadge ?? true) && items.length > 1,
      backgroundColor: widget.theme.colorScheme.primary,
      textColor: widget.theme.colorScheme.onPrimary,
      child: InkWell(
        onTap: isDisabled == true
            ? null
            : () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return AppBottomSheet(
                      title: displayText ?? '',
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items.map((item) {
                            final isSelected = item == value;

                            return ListTile(
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      itemLabel(item),
                                      style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (badgeBuilder != null) ...[
                                    const SizedBox(width: 10),
                                    badgeBuilder(item) ??
                                        const SizedBox.shrink(),
                                  ],
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check)
                                  : null,
                              onTap: () {
                                onChanged(item);
                                Navigator.pop(context);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          alignment: Alignment.center,
          padding: isHighlighted
              ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
              : EdgeInsets.zero,
          decoration: isHighlighted
              ? BoxDecoration(
                  color: const Color(0xFF343040),
                  borderRadius: BorderRadius.circular(6),
                )
              : null,
          child:
              displayWidget ??
              (displayText != null
                  ? Padding(
                      padding: isHighlighted
                          ? EdgeInsets.zero
                          : const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 10,
                            ),
                      child: Text(
                        displayText,
                        style: TextStyle(
                          color: isHighlighted
                              ? const Color(0xFFBCAAE0)
                              : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }
}
