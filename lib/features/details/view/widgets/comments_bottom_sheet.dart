import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/models/commentum/comment.dart';
import 'package:shonenx/core/models/commentum/media.dart';
import 'package:shonenx/core/models/commentum/response.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/core/services/commentum_service.dart';
import 'package:shonenx/features/auth/model/user.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';

class CommentsBottomSheet extends ConsumerStatefulWidget {
  final UniversalMedia anime;

  const CommentsBottomSheet({super.key, required this.anime});

  static Future<void> show(BuildContext context, UniversalMedia anime) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(anime: anime),
    );
  }

  @override
  ConsumerState<CommentsBottomSheet> createState() =>
      _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends ConsumerState<CommentsBottomSheet> {
  CommentumResponse? _response;
  bool _isLoading = false;
  bool _isPostingComment = false;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String _sortBy = 'createdAt';
  final int _page = 1;

  CommentumMedia get _mediaInfo => CommentumMedia(
    mediaId: widget.anime.id,
    mediaType: 'anime',
    mediaTitle: widget.anime.title.userPreferred,
    mediaYear: widget.anime.seasonYear ?? 0,
    mediaPoster:
        widget.anime.coverImage.large ?? widget.anime.coverImage.medium ?? '',
  );

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getUserInfo(AuthUser? user) {
    return {
      'user_id': user?.id ?? 'GUEST_USER',
      'username': user?.name ?? 'Guest',
      'avatar':
          user?.avatarUrl ??
          'https://s4.anilist.co/file/anilistcdn/user/avatar/medium/default.png',
    };
  }

  Future<void> _loadComments() async {
    setState(() => _isLoading = true);
    try {
      final res = await CommentumService.getComments(
        mediaId: widget.anime.id,
        mediaType: 'anilist',
        page: _page,
        limit: 20,
        sortBy: _sortBy,
        sortOrder: 'desc',
      );
      if (mounted) {
        setState(() {
          _response = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load comments', isError: true);
      }
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final auth = ref.read(authProvider);
    final user = auth.activePlatform == AuthPlatform.anilist
        ? auth.anilistUser
        : auth.malUser;

    setState(() => _isPostingComment = true);
    try {
      await CommentumService.createComment(
        clientType: 'anilist',
        userInfo: _getUserInfo(user),
        mediaInfo: _mediaInfo,
        content: text,
      );
      _commentController.clear();
      _commentFocusNode.unfocus();
      await _loadComments();
      if (mounted) _showSnackBar('Comment posted');
    } catch (e) {
      if (mounted) _showSnackBar('Failed to post comment', isError: true);
    } finally {
      if (mounted) setState(() => _isPostingComment = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.activePlatform == AuthPlatform.anilist
        ? auth.anilistUser
        : auth.malUser;
    final isLoggedIn = user != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag Handle & Header
              _buildHeader(theme, colorScheme),
              // Divider
              Divider(height: 1, color: colorScheme.outlineVariant),
              // Comment List
              Expanded(
                child: _buildCommentList(
                  theme,
                  colorScheme,
                  scrollController,
                  user,
                  isLoggedIn,
                ),
              ),
              // Input / Login Banner
              if (isLoggedIn)
                _CommentInputBox(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  isPosting: _isPostingComment,
                  user: user,
                  onSubmit: _submitComment,
                )
              else
                _LoginRequiredBanner(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
    final commentCount = _response?.comments.length ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      child: Column(
        children: [
          // Drag indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 22,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!_isLoading)
                      Text(
                        '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              // Sort button
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.sort_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Sort',
                onSelected: (value) {
                  setState(() => _sortBy = value);
                  _loadComments();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'createdAt',
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 18,
                          color: _sortBy == 'createdAt'
                              ? colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Newest',
                          style: TextStyle(
                            color: _sortBy == 'createdAt'
                                ? colorScheme.primary
                                : null,
                            fontWeight: _sortBy == 'createdAt'
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'voteScore',
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 18,
                          color: _sortBy == 'voteScore'
                              ? colorScheme.primary
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Top',
                          style: TextStyle(
                            color: _sortBy == 'voteScore'
                                ? colorScheme.primary
                                : null,
                            fontWeight: _sortBy == 'voteScore'
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Close button
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Close',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentList(
    ThemeData theme,
    ColorScheme colorScheme,
    ScrollController scrollController,
    AuthUser? user,
    bool isLoggedIn,
  ) {
    if (_isLoading && _response == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading comments...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (_response == null || _response!.comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No comments yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Be the first to share your thoughts',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _response!.comments.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          return _CommentItem(
            _response!.comments[index],
            userInfo: _getUserInfo(user),
            onRefresh: _loadComments,
            isLoggedIn: isLoggedIn,
          );
        },
      ),
    );
  }
}

// ─── Comment Item ────────────────────────────────────────────────

class _CommentItem extends StatefulWidget {
  final Comment comment;
  final int depth;
  final Map<String, dynamic> userInfo;
  final VoidCallback onRefresh;
  final bool isLoggedIn;

  const _CommentItem(
    this.comment, {
    this.depth = 0,
    required this.userInfo,
    required this.onRefresh,
    this.isLoggedIn = false,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasReplies = widget.comment.replies.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(
        left: widget.depth * 24.0,
        top: widget.depth > 0 ? 8 : 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: hasReplies
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.primaryContainer,
                        backgroundImage: widget.comment.userAvatar.isNotEmpty
                            ? NetworkImage(widget.comment.userAvatar)
                            : null,
                        onBackgroundImageError: (_, _) {},
                        child: widget.comment.userAvatar.isNotEmpty
                            ? null
                            : Icon(
                                Icons.person_rounded,
                                size: 18,
                                color: colorScheme.onPrimaryContainer,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.comment.username,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.comment.userRole != 'user') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _roleColor(
                                        widget.comment.userRole,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _roleColor(
                                          widget.comment.userRole,
                                        ),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      widget.comment.userRole.toUpperCase(),
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: _roleColor(
                                              widget.comment.userRole,
                                            ),
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              _getTimeAgo(widget.comment.createdAt.toString()),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Content
                  Text(
                    widget.comment.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Actions
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.thumb_up_outlined,
                        label: widget.comment.voteScore.toString(),
                        onPressed: widget.isLoggedIn
                            ? () => _vote('upvote')
                            : () => _showLoginRequired(context),
                      ),
                      const SizedBox(width: 4),
                      _ActionButton(
                        icon: Icons.thumb_down_outlined,
                        onPressed: widget.isLoggedIn
                            ? () => _vote('downvote')
                            : () => _showLoginRequired(context),
                      ),
                      if (hasReplies) ...[
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: _isExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          label: '${widget.comment.replies.length}',
                          onPressed: () =>
                              setState(() => _isExpanded = !_isExpanded),
                        ),
                      ],
                      const Spacer(),
                      if (widget.isLoggedIn)
                        IconButton(
                          icon: Icon(
                            Icons.flag_outlined,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => _showReportDialog(),
                          tooltip: 'Report',
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Replies
          if (hasReplies && _isExpanded)
            Container(
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colorScheme.outlineVariant, width: 2),
                ),
              ),
              child: Column(
                children: widget.comment.replies
                    .map(
                      (r) => _CommentItem(
                        r,
                        depth: widget.depth + 1,
                        userInfo: widget.userInfo,
                        onRefresh: widget.onRefresh,
                        isLoggedIn: widget.isLoggedIn,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Just now';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
      if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) {
      return 'Just now';
    }
  }

  void _showLoginRequired(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Log in to interact with comments'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _vote(String type) async {
    try {
      await CommentumService.voteComment(
        commentId: widget.comment.id,
        userInfo: widget.userInfo,
        voteType: type,
      );
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vote failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showReportDialog() async {
    final reasons = [
      'Spam',
      'Harassment',
      'Inappropriate content',
      'Spoiler',
      'Other',
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          title: const Text('Report Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map(
                  (r) => ListTile(
                    title: Text(r),
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () => Navigator.pop(context, r),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      try {
        await CommentumService.reportComment(
          commentId: widget.comment.id,
          reporterInfo: widget.userInfo,
          reason: result,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Text('Report submitted'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report failed: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red.shade700;
      case 'moderator':
      case 'mod':
        return Colors.green.shade700;
      case 'vip':
        return Colors.purple.shade700;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

// ─── Comment Input Box ───────────────────────────────────────────

class _CommentInputBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPosting;
  final AuthUser? user;
  final VoidCallback onSubmit;

  const _CommentInputBox({
    required this.controller,
    required this.focusNode,
    required this.isPosting,
    required this.user,
    required this.onSubmit,
  });

  @override
  State<_CommentInputBox> createState() => _CommentInputBoxState();
}

class _CommentInputBoxState extends State<_CommentInputBox> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage: widget.user?.avatarUrl != null
                  ? NetworkImage(widget.user!.avatarUrl!)
                  : null,
              onBackgroundImageError: (_, _) {},
              child:
                  widget.user?.avatarUrl != null &&
                      widget.user!.avatarUrl!.isNotEmpty
                  ? null
                  : Icon(
                      Icons.person_rounded,
                      size: 18,
                      color: colorScheme.onPrimaryContainer,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 100,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: widget.focusNode.hasFocus
                        ? colorScheme.primary
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: widget.focusNode.hasFocus ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: !widget.isPosting,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            widget.isPosting
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colorScheme.primary,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _hasText ? widget.onSubmit : null,
                    icon: Icon(
                      Icons.send_rounded,
                      size: 22,
                      color: _hasText
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: _hasText
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(8),
                    ),
                    tooltip: 'Post comment',
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Login Required Banner ───────────────────────────────────────

class _LoginRequiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Log in to comment, vote, and interact',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Button ───────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              if (label != null) ...[
                const SizedBox(width: 5),
                Text(
                  label!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
