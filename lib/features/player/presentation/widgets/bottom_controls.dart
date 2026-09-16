import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/discovery/presentation/widgets/episodes_panel/episode_list_panel.dart';
import 'package:shonenx/features/player/domain/player_mode.dart';
import 'package:shonenx/features/player/engine/video_engine.dart';
import 'package:shonenx/features/player/presentation/widgets/player_controls.dart';
import 'package:shonenx/features/player/providers/aniskip_provider.dart';
import 'package:shonenx/features/player/providers/player_controller.dart';
import 'package:shonenx/features/player/providers/video_engine_provider.dart';
import 'package:shonenx/features/settings/presentation/widgets/subtitle_settings_sheet.dart';
import 'package:shonenx/shared/models/video_server.dart';
import 'package:shonenx/shared/models/video_stream.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_sheet_action.dart';
import 'package:file_picker/file_picker.dart';
import 'package:window_manager/window_manager.dart';

class BottomControls extends ConsumerStatefulWidget {
  final bool showControls;
  final Function onToggleLockControls;
  final VideoEngine engine;
  final PlayerState playerState;
  final PlayerController controller;
  final ThemeData theme;
  final PlayerMode mode;
  final bool? isFullScreen;
  final VoidCallback? onToggleFullScreen;
  final VoidCallback? onShowEpisodePanel;

  const BottomControls({
    super.key,
    required this.showControls,
    required this.onToggleLockControls,
    required this.engine,
    required this.playerState,
    required this.controller,
    required this.theme,
    required this.mode,
    this.isFullScreen,
    this.onToggleFullScreen,
    this.onShowEpisodePanel,
  });

  @override
  ConsumerState<BottomControls> createState() => _BottomControlsState();
}

class _BottomControlsState extends ConsumerState<BottomControls> {
  double? _dragingValue;
  bool _isFullScreen = false;
  bool _isPortrait = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.isFullScreen().then((val) {
        if (mounted) setState(() => _isFullScreen = val);
      });
    }
  }

  void _toggleFullScreen() async {
    if (widget.onToggleFullScreen != null) {
      widget.onToggleFullScreen!();
      return;
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      bool isFull = await windowManager.isFullScreen();
      if (isFull) {
        await windowManager.setFullScreen(false);
        if (Platform.isWindows) {
          await windowManager.setTitleBarStyle(TitleBarStyle.normal);
        }
        if (mounted) setState(() => _isFullScreen = false);
      } else {
        if (Platform.isWindows) {
          await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        }
        await windowManager.setFullScreen(true);
        if (mounted) setState(() => _isFullScreen = true);
      }
    }
  }

  void _toggleOrientation() {
    setState(() => _isPortrait = !_isPortrait);
    SystemChrome.setPreferredOrientations(
      _isPortrait
          ? [DeviceOrientation.portraitUp]
          : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeEpisode = widget.playerState.activeEpisode;
    final malId = widget.playerState.malId;
    final durationSec = ref.watch(
      videoEngineStateProvider.select((s) => s.duration.inSeconds),
    );
    final aniskipArgs =
        (malId != null &&
            activeEpisode != null &&
            activeEpisode.number % 1 == 0 &&
            durationSec >= 50)
        ? AniSkipArgs(
            malId: malId,
            episodeNumber: activeEpisode.number.toInt(),
            episodeLength: durationSec,
          )
        : null;
    final aniSkips = ref.watch(aniSkipProvider(aniskipArgs));

    final isCompact = MediaQuery.of(context).size.width < 450;
    final isVeryCompact = MediaQuery.of(context).size.width < 350;

    final audioTracks = ref.watch(
      videoEngineStateProvider.select((s) => s.audioTracks),
    );
    final activeAudioTrack = ref.watch(
      videoEngineStateProvider.select((s) => s.activeAudioTrack),
    );
    final actualAudioCount = audioTracks
        .where((t) => t.id != 'auto' && t.id != 'no')
        .length;

    return AnimatedPositioned(
      duration: Durations.medium2,
      curve: Curves.fastEaseInToSlowEaseOut,
      bottom: widget.showControls ? 0 : -100,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: Durations.short4,
        opacity: widget.showControls ? 1 : 0,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
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
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 12,
                top: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 10,
                      bottom: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildLeftControls(
                              audioTracks: audioTracks,
                              activeAudioTrack: activeAudioTrack,
                              actualAudioCount: actualAudioCount,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        PlayerSkipActionArea(
                          aniSkips: aniSkips,
                          engine: widget.engine,
                          controller: widget.controller,
                          playerState: widget.playerState,
                        ),
                      ],
                    ),
                  ),

                  ProgressBar(
                    aniSkips: aniSkips.value ?? [],
                    engine: widget.engine,
                    draggingValue: _dragingValue,
                    onDragStart: (value) {
                      setState(() => _dragingValue = value);
                    },
                    onChanged: (value) {
                      setState(() => _dragingValue = value);
                    },
                    onDragEnd: (value) {
                      widget.engine
                          .seekTo(Duration(seconds: value.toInt()))
                          .then((_) => setState(() => _dragingValue = null));
                    },
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        if (!isVeryCompact) const PlayerTimeDisplay(),

                        _buildRightControls(theme: theme, isCompact: isCompact),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftControls({
    required List<AudioTrack> audioTracks,
    required AudioTrack? activeAudioTrack,
    required int actualAudioCount,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Lock controls button
        PlayerIconButton(
          icon: Icons.lock_outline_rounded,
          onTap: () => widget.onToggleLockControls(),
        ),

        const SizedBox(width: 12),

        // Subtitle picker
        if (widget.playerState.subtitles.isNotEmpty)
          PlayerBottomSheetTrigger<SubtitleTrack>(
            value: widget.playerState.activeSubtitle,
            items: widget.playerState.subtitles,
            itemLabel: (s) => s.language,
            subtitleBuilder: (s) => s.label,
            onChanged: (v) {
              widget.controller.changeSubtitle(v);
            },
            onTap: () => _showSubtitleSelector(context),
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                constraints: const BoxConstraints(maxWidth: double.infinity),
                builder: (context) {
                  return const SubtitleSettingsSheet();
                },
              );
            },
            actions: [
              AppSheetAction(
                tooltip: 'Customize Subtitles',
                isPrimary: true,
                icon: Icons.tune_rounded,
                onTap: () {
                  Navigator.of(context).pop();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                    ),
                    builder: (context) => const SubtitleSettingsSheet(),
                  );
                },
              ),
            ],
            isDisabled: widget.playerState.subtitles.isEmpty,
            withBadge: false,
            displayText: 'Subtitles',
            displayWidget: Badge(
              label: Text((widget.playerState.subtitles.length - 1).toString()),
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

        // Audio track picker
        if (actualAudioCount > 0) ...[
          const SizedBox(width: 12),
          PlayerBottomSheetTrigger<AudioTrack>(
            value: activeAudioTrack,
            items: audioTracks,
            itemLabel: (s) => s.label,
            onChanged: (v) {
              widget.controller.changeAudioTrack(v);
            },
            withBadge: false,
            displayText: 'Audio',
            displayWidget: Badge(
              label: Text(actualAudioCount.toString()),
              isLabelVisible: actualAudioCount > 0,
              backgroundColor: widget.theme.colorScheme.primary,
              textColor: widget.theme.colorScheme.onPrimary,
              child: activeAudioTrack?.id == 'no'
                  ? const Icon(Icons.volume_off_outlined, color: Colors.white)
                  : const Icon(Icons.audiotrack_outlined, color: Colors.white),
            ),
          ),
        ],

        // Episodes panel button
        if (widget.mode is PlayerModeOnline) ...[
          const SizedBox(width: 12),
          PlayerIconButton(
            icon: Icons.format_list_bulleted_rounded,
            onTap: () {
              if (widget.onShowEpisodePanel != null) {
                widget.onShowEpisodePanel!();
              } else {
                _showEpisodePanel(context);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRightControls({
    required ThemeData theme,
    required bool isCompact,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayerSubDubToggle(
          playerState: widget.playerState,
          controller: widget.controller,
        ),

        if (widget.playerState.servers.length > 1 && !isCompact) ...[
          PlayerBottomSheetTrigger<VideoServer>(
            value: widget.playerState.activeServer,
            items: widget.playerState.servers,
            itemLabel: (s) => '[ ${trimText(s.id, maxLength: 30)} ] ${s.name}',
            onChanged: (v) {
              widget.controller.changeServer(v);
            },
            displayText: (() {
              final server = widget.playerState.activeServer;
              if (server == null) return 'Default';
              if (server.id.length <= 20) return server.id;
              final name = server.name;
              return name.length > 30 ? '${name.substring(0, 27)}...' : name;
            })(),
            badgeBuilder: (s) {
              if (s.type == ServerType.unknown) return null;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: s.type == ServerType.dub
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.type == ServerType.dub
                      ? 'DUB'
                      : s.type == ServerType.sub
                      ? 'SUB'
                      : '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: s.type == ServerType.dub
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSecondary,
                  ),
                ),
              );
            },
          ),
        ],

        if (widget.playerState.streams.length > 1 && !isCompact) ...[
          const SizedBox(width: 14),
          PlayerBottomSheetTrigger<VideoStream>(
            value: widget.playerState.activeStream,
            items: widget.playerState.streams,
            itemLabel: (s) => s.quality,
            onChanged: (v) {
              widget.controller.changeStream(v);
            },
            displayText: trimText(
              widget.playerState.activeStream?.quality ?? 'Auto',
              maxLength: 40,
            ),
          ),
        ],

        if (Platform.isAndroid || Platform.isIOS) ...[
          const SizedBox(width: 14),
          PlayerIconButton(
            icon: _isPortrait
                ? Icons.screen_lock_landscape_outlined
                : Icons.screen_lock_portrait_outlined,
            onTap: _toggleOrientation,
          ),
        ],

        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
          const SizedBox(width: 14),
          PlayerIconButton(
            icon: (widget.isFullScreen ?? _isFullScreen)
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            onTap: _toggleFullScreen,
          ),
        ],
      ],
    );
  }

  void _showSubtitleSelector(BuildContext context) {
    final theme = Theme.of(context);
    final activeSub = widget.playerState.activeSubtitle;

    final offOption = widget.playerState.subtitles.firstWhere(
      (s) => s.url.isEmpty,
      orElse: () => SubtitleTrack.none,
    );

    final groups = <String, List<SubtitleTrack>>{};
    for (final sub in widget.playerState.subtitles) {
      if (sub.url.isEmpty) continue;
      final label = sub.label ?? 'Other';
      groups.putIfAbsent(label, () => []).add(sub);
    }

    AppBottomSheet.show(
      context: context,
      title: 'Subtitles',
      actions: [
        AppSheetAction(
          tooltip: 'Load Local Subtitle',
          icon: Icons.folder_open_rounded,
          onTap: () async {
            Navigator.of(context).pop();
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['srt', 'vtt', 'ass', 'ssa'],
            );
            if (result != null && result.files.single.path != null) {
              final path = result.files.single.path!;
              final name = result.files.single.name;
              widget.controller.loadLocalSubtitle(path, name);
            }
          },
        ),
        const SizedBox(width: 8),
        AppSheetAction(
          tooltip: 'Customize Subtitles',
          isPrimary: true,
          icon: Icons.tune_rounded,
          onTap: () {
            Navigator.of(context).pop();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              constraints: const BoxConstraints(maxWidth: double.infinity),
              builder: (context) => const SubtitleSettingsSheet(),
            );
          },
        ),
      ],
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSubtitleTile(offOption, activeSub == offOption),
            const SizedBox(height: 8),
            for (final entry in groups.entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              for (final sub in entry.value)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _buildSubtitleTile(sub, activeSub == sub),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitleTile(SubtitleTrack item, bool isSelected) {
    final theme = Theme.of(context);
    return ListTile(
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: isSelected
          ? Icon(
              Icons.radio_button_checked_rounded,
              color: theme.colorScheme.primary,
            )
          : Icon(
              Icons.radio_button_unchecked_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
      title: Text(
        item.language,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        widget.controller.changeSubtitle(item);
        Navigator.of(context).pop();
      },
    );
  }

  void _showEpisodePanel(BuildContext context) {
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
                  child: Consumer(
                    builder: (context, ref, child) {
                      final currentEpisode = ref.watch(
                        playerControllerProvider.select((s) => s.activeEpisode),
                      );
                      if (currentEpisode == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return EpisodeListPanel(
                        media: (widget.mode as PlayerModeOnline).media,
                        currentEpisodeNumber: currentEpisode.number,
                        onEpisodeTap: (episode, sourceInfo) {
                          Navigator.of(context).pop();
                          ref
                              .read(playerControllerProvider.notifier)
                              .loadEpisode(episode);
                        },
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
}
