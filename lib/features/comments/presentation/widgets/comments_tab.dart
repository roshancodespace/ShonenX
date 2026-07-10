import 'package:commentum_client/commentum_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/commentum/commentum_auth_service.dart';
import 'package:shonenx/core/utils/formatting.dart';
import 'package:shonenx/features/auth/providers/auth_provider.dart';
import 'package:shonenx/features/comments/presentation/providers/comments_provider.dart';
import 'package:shonenx/features/tracking/domain/models/tracker_type.dart';
import 'package:shonenx/features/tracking/engine/remote_tracker.dart';
import 'package:shonenx/features/tracking/providers/tracker_registry.dart';
import 'package:shonenx/features/comments/presentation/widgets/comment_composer.dart';
import 'package:shonenx/features/comments/presentation/widgets/comment_item.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/staggered_fade_in.dart';

class CommentsTabWidget extends ConsumerStatefulWidget {
  final UnifiedMedia media;
  final int? initialEpisodeNumber;
  final bool forceEpisodeFilter;

  const CommentsTabWidget({
    super.key,
    required this.media,
    this.initialEpisodeNumber,
    this.forceEpisodeFilter = false,
  });

  @override
  ConsumerState<CommentsTabWidget> createState() => _CommentsTabWidgetState();
}

class _CommentsTabWidgetState extends ConsumerState<CommentsTabWidget> {
  final TextEditingController _contentController = TextEditingController();
  Comment? _replyingTo;
  bool _isSubmitting = false;
  int? _selectedEpisodeNumber;

  @override
  void initState() {
    super.initState();
    _selectedEpisodeNumber = widget.initialEpisodeNumber;
  }

  String get _mediaProvider {
    final active = ref.read(commentumAuthServiceProvider).activeProvider;
    if (active == CommentumProvider.myanimelist && widget.media.idMal != null) {
      return 'mal';
    }
    if (active == CommentumProvider.anilist) {
      return 'anilist';
    }
    if (widget.media.idMal != null && widget.media.id == widget.media.idMal) {
      return 'mal';
    }
    return 'anilist';
  }

  String get _mediaId {
    if (_mediaProvider == 'mal' && widget.media.idMal != null) {
      return widget.media.idMal!;
    }
    return widget.media.id;
  }

  CommentsArgs get _args => CommentsArgs(
    mediaId: _mediaId,
    mediaProvider: _mediaProvider,
    episodeNumber: _selectedEpisodeNumber,
  );

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleConnect(CommentumProvider provider) async {
    final authService = ref.read(commentumAuthServiceProvider);
    final trackerTokens = ref.read(authTokensProvider).value ?? {};
    final trackerType = _mapProviderToTrackerType(provider);

    try {
      String? token = trackerType != null ? trackerTokens[trackerType] : null;

      if (token == null && trackerType != null) {
        final service = ref
            .read(availableTrackersProvider)
            .firstWhere((t) => t.type == trackerType);
        if (service is RemoteTracker) {
          await ref.read(authTokensProvider.notifier).login(service);
          final updatedTokens = ref.read(authTokensProvider).value ?? {};
          token = updatedTokens[trackerType];
        }
      }

      if (token != null) {
        await authService.signIn(provider, token);
        ref.invalidate(commentsProvider(_args));
        setState(() {});
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not obtain access token for ${provider.displayName}.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    }
  }

  TrackerType? _mapProviderToTrackerType(CommentumProvider p) {
    switch (p) {
      case CommentumProvider.anilist:
        return TrackerType.anilist;
      case CommentumProvider.myanimelist:
        return TrackerType.myanimelist;
      case CommentumProvider.simkl:
        return null;
    }
  }

  Future<void> _submitComment() async {
    final text = _contentController.text.trim();
    if (text.isEmpty || text.length > 500) return;

    setState(() => _isSubmitting = true);
    try {
      final notifier = ref.read(commentsProvider(_args).notifier);
      if (_replyingTo != null) {
        await notifier.postReply(_replyingTo!.id, text);
      } else {
        await notifier.postComment(text);
      }
      _contentController.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _confirmLogout(
    BuildContext context,
    CommentumAuthService authService,
    CommentumProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: Text(
          'Are you sure you want to log out of ${provider.displayName}?',
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () async {
              ctx.pop();
              context.pop();
              await authService.signOut(provider);
              setState(() {});
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showAccountSelectorSheet(CommentumAuthService authService) {
    final loggedIn = authService.loggedInProviders;
    final active = authService.activeProvider;
    final cs = Theme.of(context).colorScheme;
    final allProviders = [
      CommentumProvider.anilist,
      CommentumProvider.myanimelist,
    ];
    final available = allProviders.where((p) => !loggedIn.contains(p)).toList();

    AppBottomSheet.show(
      context: context,
      title: 'Comment Accounts',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (loggedIn.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'CONNECTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            for (final p in loggedIn)
              Builder(
                builder: (context) {
                  final trackerType = _mapProviderToTrackerType(p);
                  final profile = trackerType?.getProfile(ref);
                  final hasValidProfile =
                      profile != null &&
                      profile.username.isNotEmpty &&
                      profile.username != 'Guest';

                  final isActive = p == active;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isActive
                        ? null
                        : () {
                            authService.switchAccount(p);
                            context.pop();
                            setState(() {});
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: profile?.avatarUrl != null
                                ? NetworkImage(profile!.avatarUrl!)
                                : null,
                            backgroundColor: cs.surfaceContainerHighest,
                            child: profile?.avatarUrl == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: cs.onSurfaceVariant,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      hasValidProfile
                                          ? profile.username
                                          : p.displayName,
                                      style: TextStyle(
                                        fontWeight: isActive
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 14,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    if (isActive) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: cs.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            splashRadius: 18,
                            tooltip: 'Log Out',
                            onPressed: () =>
                                _confirmLogout(context, authService, p),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
          if (available.isNotEmpty) ...[
            if (loggedIn.isNotEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
              child: Text(
                'CONNECT MORE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 1.0,
                ),
              ),
            ),
            for (final provider in available)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  context.pop();
                  _handleConnect(provider);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.surfaceContainerLow,
                        child: Icon(
                          Icons.add_link_rounded,
                          size: 18,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connect ${provider.displayName}',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showEpisodePickerSheet(BuildContext context) {
    final maxEps = widget.media.episodes ?? 100;
    final controller = TextEditingController(
      text: _selectedEpisodeNumber?.toString() ?? '',
    );

    AppBottomSheet.show(
      context: context,
      title: 'Select Episode Discussion',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter episode number (1 - $maxEps)...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (val) {
                      final num = int.tryParse(val);
                      if (num != null && num > 0) {
                        context.pop();
                        setState(() => _selectedEpisodeNumber = num);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    final num = int.tryParse(controller.text);
                    if (num != null && num > 0) {
                      context.pop();
                      setState(() => _selectedEpisodeNumber = num);
                    }
                  },
                  child: const Text('Go'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 240,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: maxEps,
              itemBuilder: (ctx, idx) {
                final epNum = idx + 1;
                final isSelected = _selectedEpisodeNumber == epNum;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    context.pop();
                    setState(() => _selectedEpisodeNumber = epNum);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$epNum',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(commentumAuthServiceProvider);
    final commentsAsync = ref.watch(commentsProvider(_args));
    final uiRoundness = ref.watch(
      themePrefsProvider.select((s) => s.uiRoundness),
    );
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        StaggeredFadeIn(
          index: 0,
          child: !authService.isLoggedIn
              ? _buildLoginHeader(theme, uiRoundness)
              : _buildAccountHeader(theme, authService),
        ),
        Container(
          width: double.maxFinite,
          height: 1,
          color: cs.outlineVariant.withValues(alpha: 0.2),
        ),
        if (!widget.forceEpisodeFilter)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            color: cs.surfaceContainerLow,
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded, size: 16, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Filter:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          visualDensity: VisualDensity.compact,
                          label: const Text('All Series'),
                          selected: _selectedEpisodeNumber == null,
                          onSelected: (_) {
                            setState(() => _selectedEpisodeNumber = null);
                          },
                        ),
                        const SizedBox(width: 6),
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            _selectedEpisodeNumber != null
                                ? Icons.numbers_rounded
                                : Icons.add_rounded,
                            size: 14,
                          ),
                          label: Text(
                            _selectedEpisodeNumber != null
                                ? 'Ep $_selectedEpisodeNumber'
                                : 'Select Episode',
                          ),
                          onPressed: () => _showEpisodePickerSheet(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: cs.surfaceContainerLow,
            child: Row(
              children: [
                Icon(Icons.filter_alt_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Episode ${formatEpisodeNumber(_selectedEpisodeNumber ?? widget.initialEpisodeNumber)} Discussion',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: commentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 36,
                      color: cs.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load discussion',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      err.toString(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(commentsProvider(_args)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (state) {
              if (state.comments.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No comments yet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to share your thoughts.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount:
                    state.comments.length + (state.nextCursor != null ? 1 : 0),
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 68,
                  color: cs.outlineVariant.withValues(alpha: 0.15),
                ),
                itemBuilder: (context, index) {
                  if (index == state.comments.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: state.isMoreLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : TextButton(
                                onPressed: () => ref
                                    .read(commentsProvider(_args).notifier)
                                    .loadMore(),
                                child: const Text('Load More'),
                              ),
                      ),
                    );
                  }
                  final comment = state.comments[index];
                  return StaggeredFadeIn(
                    index: index + 1,
                    child: CommentItem(
                      comment: comment,
                      onReply: (c) => setState(() => _replyingTo = c),
                      onVote: (c, voteType) => ref
                          .read(commentsProvider(_args).notifier)
                          .vote(c.id, voteType),
                      onDelete: (c) => ref
                          .read(commentsProvider(_args).notifier)
                          .deleteComment(c.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (authService.isLoggedIn)
          CommentComposer(
            controller: _contentController,
            replyingTo: _replyingTo,
            onCancelReply: () => setState(() => _replyingTo = null),
            onSubmit: _submitComment,
            isSubmitting: _isSubmitting,
            uiRoundness: uiRoundness,
          ),
      ],
    );
  }

  Widget _buildLoginHeader(ThemeData theme, double uiRoundness) {
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 22,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sign in to join the discussion',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.invalidate(commentsProvider(_args)),
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            tooltip: 'Refresh Comments',
          ),
          const SizedBox(width: 4),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => _showAccountSelectorSheet(
              ref.read(commentumAuthServiceProvider),
            ),
            child: Text(
              'Sign In',
              style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountHeader(
    ThemeData theme,
    CommentumAuthService authService,
  ) {
    final cs = theme.colorScheme;
    final active = authService.activeProvider;
    final trackerType = active != null
        ? _mapProviderToTrackerType(active)
        : null;
    final profile = trackerType?.getProfile(ref);
    final hasValidProfile =
        profile != null &&
        profile.username.isNotEmpty &&
        profile.username != 'Guest';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: profile?.avatarUrl != null
                ? NetworkImage(profile!.avatarUrl!)
                : null,
            backgroundColor: cs.primaryContainer,
            child: profile?.avatarUrl == null
                ? Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: cs.onPrimaryContainer,
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasValidProfile
                      ? profile.username
                      : (active?.displayName ?? 'Account'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Commenting as ${active?.displayName ?? 'AniList'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => ref.invalidate(commentsProvider(_args)),
            icon: Icon(
              Icons.refresh_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            tooltip: 'Refresh Comments',
          ),
          const SizedBox(width: 4),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => _showAccountSelectorSheet(authService),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text(
              'Switch',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
