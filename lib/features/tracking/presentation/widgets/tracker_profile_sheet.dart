import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_profile.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_profile_provider.dart';
import 'package:shonenx/features/tracking/engine/trackers/anilist/anilist_tracker.dart';
import 'package:shonenx/features/tracking/providers/shonenx_metrics_provider.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/tracking/providers/tracking_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:shonenx/shared/widgets/tracker_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackerProfileSheet extends ConsumerStatefulWidget {
  final TrackerType trackerType;

  const TrackerProfileSheet({super.key, required this.trackerType});

  @override
  ConsumerState<TrackerProfileSheet> createState() =>
      _TrackerProfileSheetState();
}

class _TrackerProfileSheetState extends ConsumerState<TrackerProfileSheet> {
  bool _isEditing = false;
  bool _isSyncing = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final currentProfile = ref.read(trackerProfileProvider)[widget.trackerType];
    _nameController = TextEditingController(
      text:
          currentProfile?.username != null &&
              currentProfile!.username != 'Guest'
          ? currentProfile.username
          : '',
    );
    _bioController = TextEditingController(text: currentProfile?.bio ?? '');
    _avatarPath = currentProfile?.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _syncRemote() async {
    final tracker = ref
        .read(availableTrackersProvider)
        .firstWhere((t) => t.type == widget.trackerType);
    if (tracker is RemoteTracker) {
      setState(() => _isSyncing = true);
      try {
        final freshProfile = await tracker.fetchProfile();
        ref
            .read(trackerProfileProvider.notifier)
            .saveProfile(widget.trackerType, freshProfile);
        _initData();
      } catch (_) {}
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _pickImage() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.image);
    if (res != null && res.files.single.path != null) {
      setState(() => _avatarPath = res.files.single.path);
    }
  }

  void _pasteUrl() {
    final controller = TextEditingController(text: _avatarPath ?? '');
    AppDialog.show(
      context: context,
      title: 'Image URL',
      icon: Icon(
        Icons.link_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            setState(() => _avatarPath = controller.text.trim());
            context.pop();
          },
          child: const Text('Set'),
        ),
      ],
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: 'https://example.com/avatar.png',
        ),
      ),
    );
  }

  void _save() {
    final username = _nameController.text.trim().isEmpty
        ? widget.trackerType == TrackerType.local
              ? 'Guest'
              : widget.trackerType.displayName
        : _nameController.text.trim();
    final bio = _bioController.text.trim();

    final currentProfile = ref.read(trackerProfileProvider)[widget.trackerType];
    final profile =
        (currentProfile ??
                TrackerProfile(id: widget.trackerType.id, username: username))
            .copyWith(
              username: username,
              avatarUrl: _avatarPath,
              bio: bio.isEmpty ? null : bio,
            );

    ref
        .read(trackerProfileProvider.notifier)
        .saveProfile(widget.trackerType, profile);

    final tracker = ref
        .read(availableTrackersProvider)
        .firstWhere((t) => t.type == widget.trackerType);
    if (tracker is AnilistTracker && bio.isNotEmpty) {
      tracker.updateBio(bio);
    }

    setState(() => _isEditing = false);
  }

  void _logout() {
    final tracker = ref
        .read(availableTrackersProvider)
        .firstWhere((t) => t.type == widget.trackerType);
    if (tracker is RemoteTracker) {
      ref.read(authTokensProvider.notifier).logout(tracker);
    }
    context.pop();
  }

  void _openWeb(String? url) {
    if (url != null)
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    AppDialog.show(
      context: context,
      title: 'Rankings & Telemetry',
      icon: Icon(Icons.info_outline_rounded, color: cs.primary),
      maxWidth: 520,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Otaku Rank Progression',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Titles unlock automatically as your watched episode count grows:',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          _rankTier(theme, cs, 'Mythic Otaku God', '3,000+ Episodes', true),
          _rankTier(theme, cs, 'Grandmaster Watcher', '1,500+ Episodes', false),
          _rankTier(theme, cs, 'Elite Anime Veteran', '1,000+ Episodes', false),
          _rankTier(theme, cs, 'Seasoned Otaku', '500+ Episodes', false),
          _rankTier(theme, cs, 'Dedicated Enthusiast', '100+ Episodes', false),
          _rankTier(theme, cs, 'Apprentice Watcher', '20+ Episodes', false),
          _rankTier(theme, cs, 'Novice Explorer', '1+ Episodes', false),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'On-Device Local Telemetry',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Metrics (Sessions, Playtime, Series, Chapters) are compiled purely from your local database on this device. Zero telemetry leaves your device.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _rankTier(
    ThemeData theme,
    ColorScheme cs,
    String title,
    String req,
    bool isTop,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isTop
                    ? Icons.workspace_premium_rounded
                    : Icons.military_tech_rounded,
                size: 16,
                color: isTop ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isTop ? FontWeight.w800 : FontWeight.w600,
                  color: isTop ? cs.primary : cs.onSurface,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          Text(
            req,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'Unsynced';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _computeTitle(TrackerProfile? p) {
    final eps = p?.episodesWatched ?? 0;
    if (eps >= 3000) return 'Mythic Otaku God';
    if (eps >= 1500) return 'Grandmaster Watcher';
    if (eps >= 1000) return 'Elite Anime Veteran';
    if (eps >= 500) return 'Seasoned Otaku';
    if (eps >= 100) return 'Dedicated Enthusiast';
    if (eps >= 20) return 'Apprentice Watcher';
    if (eps > 0) return 'Novice Explorer';
    return 'Local Explorer';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final prefs = ref.watch(trackingPrefsProvider);
    final isPrimary = prefs.primaryTracker == widget.trackerType;
    final isRemote = widget.trackerType != TrackerType.local;
    final isLoggedIn =
        isRemote &&
        (ref.watch(authTokensProvider).value?.containsKey(widget.trackerType) ??
            false);
    final profile = ref.watch(trackerProfileProvider)[widget.trackerType];

    final hasStats =
        profile != null &&
        (profile.animeCount != null ||
            profile.episodesWatched != null ||
            profile.minutesWatched != null ||
            profile.meanScore != null ||
            profile.mangaCount != null ||
            profile.chaptersRead != null);

    return AppBottomSheet(
      title: widget.trackerType.displayName,
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline_rounded, color: cs.primary, size: 22),
          tooltip: 'Rankings & Telemetry Info',
          onPressed: () => _showInfoDialog(context),
        ),
      ],
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: _isEditing
              ? _buildEditView(theme, cs)
              : _buildDashboardView(
                  theme,
                  cs,
                  profile,
                  hasStats,
                  isPrimary,
                  isRemote,
                  isLoggedIn,
                ),
        ),
      ),
    );
  }

  Widget _buildDashboardView(
    ThemeData theme,
    ColorScheme cs,
    TrackerProfile? profile,
    bool hasStats,
    bool isPrimary,
    bool isRemote,
    bool isLoggedIn,
  ) {
    final cleanBio = (profile?.bio ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    final name =
        profile?.username ??
        (isRemote ? widget.trackerType.displayName : 'Guest');
    final gamerTitle = _computeTitle(profile);
    final lastSynced = _formatTimeAgo(profile?.lastSyncedAt);
    final localMetricsAsync = ref.watch(shonenxLocalMetricsProvider);

    return Column(
      key: const ValueKey('dash'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        Center(
          child: ClipOval(
            child: TrackerAvatarWidget(imageUrl: profile?.avatarUrl, size: 84),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.trackerType.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (profile?.profileUrl != null) ...[
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _openWeb(profile!.profileUrl),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                  color: cs.primary,
                ),
                tooltip: 'Open in Browser',
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              gamerTitle,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isRemote) ...[
              Text(
                ' • ',
                style: theme.textTheme.labelMedium?.copyWith(color: cs.outline),
              ),
              Text(
                'Last synced: $lastSynced',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (cleanBio.isNotEmpty || !isRemote) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              cleanBio.isNotEmpty
                  ? cleanBio
                  : 'Offline tracking stored locally on device',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (hasStats) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (profile!.animeCount != null)
                _cleanStat(theme, cs, profile.animeCount.toString(), 'Anime'),
              if (profile.episodesWatched != null)
                _cleanStat(
                  theme,
                  cs,
                  profile.episodesWatched.toString(),
                  'Episodes',
                ),
              if (profile.minutesWatched != null)
                _cleanStat(
                  theme,
                  cs,
                  (profile.minutesWatched! / 1440).toStringAsFixed(1),
                  'Days',
                ),
              if (profile.meanScore != null && profile.meanScore! > 0)
                _cleanStat(
                  theme,
                  cs,
                  '★ ${profile.meanScore!.toStringAsFixed(1)}',
                  'Score',
                ),
              if (profile.mangaCount != null)
                _cleanStat(theme, cs, profile.mangaCount.toString(), 'Manga'),
            ],
          ),
          if (profile.statusCounts != null &&
              profile.statusCounts!.isNotEmpty) ...[
            const SizedBox(height: 18),
            _buildStatusDistribution(theme, cs, profile.statusCounts!),
          ],
        ],
        if (profile?.favorites != null && profile!.favorites!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Favorites',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profile.favorites!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, idx) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CachedNetworkImage(
                    imageUrl: profile.favorites![idx],
                    width: 58,
                    height: 84,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 58,
                      height: 84,
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_rounded,
                        size: 20,
                        color: cs.outline,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        localMetricsAsync.when(
          data: (m) => _buildShonenxExclusiveCard(theme, cs, m),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => setState(() => _isEditing = true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Customize'),
              ),
            ),
            if (isRemote && isLoggedIn) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isSyncing ? null : _syncRemote,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _isSyncing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onPrimary,
                          ),
                        )
                      : const Text('Sync Profile'),
                ),
              ),
            ],
          ],
        ),
        if (!isPrimary) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref
                  .read(trackingPrefsProvider.notifier)
                  .setPrimaryTracker(widget.trackerType);
              context.pop();
            },
            style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            child: const Text('Set as Primary Tracker'),
          ),
        ],
        if (isRemote) ...[
          SizedBox(height: 16),
          if (isLoggedIn)
            TextButton(
              onPressed: _logout,
              style: TextButton.styleFrom(
                foregroundColor: cs.error,
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Log Out'),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: FilledButton(
                onPressed: () {
                  final tracker = ref
                      .read(availableTrackersProvider)
                      .firstWhere((t) => t.type == widget.trackerType);
                  if (tracker is RemoteTracker)
                    ref.read(authTokensProvider.notifier).login(tracker);
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text('Connect ${widget.trackerType.displayName}'),
              ),
            ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildStatusDistribution(
    ThemeData theme,
    ColorScheme cs,
    Map<String, int> counts,
  ) {
    final total = counts.values.fold<int>(0, (prev, val) => prev + val);
    if (total == 0) return const SizedBox.shrink();

    Color getColor(String status) {
      switch (status.toUpperCase()) {
        case 'CURRENT':
        case 'WATCHING':
        case 'READING':
          return cs.primary;
        case 'COMPLETED':
          return cs.tertiary;
        case 'PLANNING':
        case 'PLAN_TO_WATCH':
        case 'PLAN_TO_READ':
          return cs.secondaryContainer;
        case 'PAUSED':
        case 'ON_HOLD':
          return cs.primaryContainer;
        case 'DROPPED':
          return cs.error;
        default:
          return cs.outlineVariant;
      }
    }

    String getLabel(String status) {
      switch (status.toUpperCase()) {
        case 'CURRENT':
          return 'Watching';
        case 'PLANNING':
          return 'Planning';
        case 'PAUSED':
          return 'Paused';
        default:
          return status[0].toUpperCase() + status.substring(1).toLowerCase();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Row(
              children: counts.entries.map((e) {
                final flex = (e.value * 100 ~/ total);
                return Expanded(
                  flex: flex > 0 ? flex : 1,
                  child: Container(color: getColor(e.key)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 6,
          children: counts.entries.map((e) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: getColor(e.key),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${getLabel(e.key)} (${e.value})',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEditView(ThemeData theme, ColorScheme cs) {
    return Column(
      key: const ValueKey('edit'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Stack(
            children: [
              ClipOval(
                child: TrackerAvatarWidget(imageUrl: _avatarPath, size: 84),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: cs.primary,
                  shape: const CircleBorder(),
                  child: PopupMenuButton<int>(
                    tooltip: 'Change Avatar',
                    icon: Icon(Icons.edit, size: 14, color: cs.onPrimary),
                    onSelected: (val) {
                      if (val == 0) _pickImage();
                      if (val == 1) _pasteUrl();
                      if (val == 2) setState(() => _avatarPath = null);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 0,
                        child: Text('Pick Image File'),
                      ),
                      const PopupMenuItem(
                        value: 1,
                        child: Text('Paste Image URL'),
                      ),
                      if (_avatarPath != null)
                        const PopupMenuItem(
                          value: 2,
                          child: Text('Remove Image'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Override Display Name',
            hintText: widget.trackerType == TrackerType.local
                ? 'Guest'
                : widget.trackerType.displayName,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: widget.trackerType == TrackerType.anilist
                ? 'About / Bio (Syncs with AniList)'
                : 'About / Bio (Local Override)',
            hintText: 'Tell the otaku community about your taste...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.info_outline),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => setState(() {
                  _initData();
                  _isEditing = false;
                }),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cleanStat(
    ThemeData theme,
    ColorScheme cs,
    String value,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildShonenxExclusiveCard(
    ThemeData theme,
    ColorScheme cs,
    ShonenxLocalMetrics m,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(GlobalUI.uiRoundness),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'ShonenX Local Telemetry',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Device-only interaction analytics powered by ShonenX Engine',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _exclusiveMetric(
                theme,
                cs,
                Icons.play_circle_outline_rounded,
                m.streamedSessions.toString(),
                'Sessions',
              ),
              _exclusiveMetric(
                theme,
                cs,
                Icons.timer_outlined,
                '${m.hoursWatched.toStringAsFixed(1)}h',
                'Playtime',
              ),
              _exclusiveMetric(
                theme,
                cs,
                Icons.video_library_outlined,
                m.uniqueSeriesTracked.toString(),
                'Series',
              ),
              _exclusiveMetric(
                theme,
                cs,
                Icons.menu_book_rounded,
                m.chaptersRead.toString(),
                'Chapters',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exclusiveMetric(
    ThemeData theme,
    ColorScheme cs,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 5),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
