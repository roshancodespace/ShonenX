import 'package:commentum_client/commentum_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/commentum/commentum_auth_service.dart';
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

  const CommentsTabWidget({super.key, required this.media});

  @override
  ConsumerState<CommentsTabWidget> createState() => _CommentsTabWidgetState();
}

class _CommentsTabWidgetState extends ConsumerState<CommentsTabWidget> {
  final TextEditingController _contentController = TextEditingController();
  Comment? _replyingTo;
  bool _isSubmitting = false;

  String get _mediaId => widget.media.idMal ?? widget.media.id;
  String get _mediaProvider => widget.media.idMal != null ? 'mal' : 'anilist';

  CommentsArgs get _args =>
      CommentsArgs(mediaId: _mediaId, mediaProvider: _mediaProvider);

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
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          if (loggedIn.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                'CONNECTED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                  letterSpacing: 1.2,
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

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: p == active
                          ? cs.primaryContainer.withValues(alpha: 0.4)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: p == active
                          ? Border.all(
                              color: cs.primary.withValues(alpha: 0.5),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundImage: profile?.avatarUrl != null
                            ? NetworkImage(profile!.avatarUrl!)
                            : null,
                        backgroundColor: p == active
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        child: profile?.avatarUrl == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 20,
                                color: p == active
                                    ? cs.onPrimaryContainer
                                    : cs.onSurfaceVariant,
                              )
                            : null,
                      ),
                      title: Text(
                        hasValidProfile ? profile.username : p.displayName,
                        style: TextStyle(
                          fontWeight: p == active
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        p.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p == active)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cs.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onPrimary,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.logout_rounded,
                              size: 20,
                              color: cs.error,
                            ),
                            tooltip: 'Log Out',
                            onPressed: () =>
                                _confirmLogout(context, authService, p),
                          ),
                        ],
                      ),
                      onTap: p == active
                          ? null
                          : () {
                              authService.switchAccount(p);
                              context.pop();
                              setState(() {});
                            },
                    ),
                  );
                },
              ),
          ],
          if (available.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                'CONNECT MORE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            for (final provider in available)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.add_link_rounded,
                      size: 20,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  title: Text(
                    'Connect ${provider.displayName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Link account to comment',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () {
                    context.pop();
                    _handleConnect(provider);
                  },
                ),
              ),
          ],
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
            icon: Icon(Icons.refresh_rounded, size: 20, color: cs.onSurfaceVariant),
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
            icon: Icon(Icons.refresh_rounded, size: 20, color: cs.onSurfaceVariant),
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
