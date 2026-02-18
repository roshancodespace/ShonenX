import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:commentum_client/commentum_client.dart';
import 'package:shonenx/core/commentum/commentum_provider.dart';
import 'package:shonenx/core/models/universal/universal_media.dart';
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
  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isPostingComment = false;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  String _sortBy = 'createdAt';
  String? _nextCursor;
  int _commentCount = 0;
  Comment? _replyingTo;

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

  Future<void> _loadComments({bool refresh = true}) async {
    if (refresh) setState(() => _isLoading = true);
    try {
      final res = await commentumClient.listComments(
        widget.anime.id.toString(),
        limit: 20,
        cursor: _nextCursor,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _comments = [];
          }
          final newComments = res.data;
          _commentCount = res.count;

          if (refresh) {
            _comments = newComments;
          } else {
            _comments.addAll(newComments);
          }

          _nextCursor = res.nextCursor;
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
    final user = auth.userFor(auth.activePlatform);

    if (user == null) {
      _showLoginRequired(context);
      return;
    }

    final isReply = _replyingTo != null;

    final tempId = (-DateTime.now().millisecondsSinceEpoch).toString();
    final tempComment = Comment(
      id: tempId,
      content: text,
      score: 0,
      status: CommentStatus.active,
      username: user.name,
      avatarUrl: user.avatarUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      hasMoreReplies: false,
      replies: [],
      repliesCount: 0,
      userVote: 0,
    );

    _commentController.clear();
    _commentFocusNode.unfocus();

    setState(() {
      _isPostingComment = true;
      if (!isReply) {
        _comments.insert(0, tempComment);
      }
    });

    try {
      if (isReply) {
        await commentumClient.createReply(
          _replyingTo!.id,
          text,
        );
        if (mounted) setState(() => _replyingTo = null);
      } else {
        await commentumClient.createComment(
          widget.anime.id.toString(),
          "anilist",
          text,
        );
      }

      await _loadComments(refresh: true);
    } catch (e) {
      if (mounted) {
        if (e is CommentumError) {
          if (e.status == 401) {
            await ref
                .read(authProvider.notifier)
                .reLoginCommentum(auth.activePlatform);
            return;
          }
        }
        setState(() {
          if (!isReply) _comments.removeWhere((c) => c.id == tempId);
        });
        _commentController.text = text;
        _showSnackBar('Failed to post: $e', isError: true);
      }
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.userFor(auth.activePlatform);
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
              _buildHeader(theme, colorScheme),
              Divider(height: 1, color: colorScheme.outlineVariant),
              Expanded(
                child: _buildCommentList(
                  theme,
                  colorScheme,
                  scrollController,
                  user,
                  isLoggedIn,
                ),
              ),
              if (isLoggedIn)
                _CommentInputBox(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  isPosting: _isPostingComment,
                  user: user,
                  onSubmit: _submitComment,
                  replyingTo: _replyingTo,
                  onCancelReply: () {
                    setState(() {
                      _replyingTo = null;
                      _commentFocusNode.unfocus();
                    });
                  },
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      child: Column(
        children: [
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
                        '$_commentCount comments',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
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
                    child: Text(
                      'Newest',
                      style: TextStyle(
                        color: _sortBy == 'createdAt'
                            ? colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'voteScore',
                    child: Text(
                      'Top',
                      style: TextStyle(
                        color: _sortBy == 'voteScore'
                            ? colorScheme.primary
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
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
    if (_isLoading && _comments.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.primary),
      );
    }

    if (_comments.isEmpty) {
      return Center(
        child: Text(
          'No comments yet',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComments,
      child: ListView.separated(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _comments.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
        itemBuilder: (context, index) {
          return _CommentItem(
            _comments[index],
            onRefresh: _loadComments,
            isLoggedIn: isLoggedIn,
            onReply: (comment) {
              setState(() {
                _replyingTo = comment;
                _commentFocusNode.requestFocus();
              });
            },
            onRemove: () {
              setState(() {
                _comments.removeAt(index);
              });
            },
          );
        },
      ),
    );
  }
}

class _CommentItem extends ConsumerStatefulWidget {
  final Comment comment;
  final int depth;
  final VoidCallback onRefresh;
  final bool isLoggedIn;
  final ValueChanged<Comment> onReply;

  const _CommentItem(
    this.comment, {
    this.depth = 0,
    required this.onRefresh,
    this.isLoggedIn = false,
    required this.onReply,
    this.onRemove,
  });

  final VoidCallback? onRemove;

  @override
  ConsumerState<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<_CommentItem> {
  bool _isExpanded = true;
  late int _score;
  late int _userVote;
  late String _content;
  late List<Comment> _replies;
  Timer? _debounce;
  bool _isEditing = false;
  final TextEditingController _editController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _score = widget.comment.score;
    _userVote = widget.comment.userVote ?? 0;
    _content = widget.comment.content;
    _replies = widget.comment.replies;
  }

  @override
  void didUpdateWidget(_CommentItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comment != widget.comment) {
      _score = widget.comment.score;
      _userVote = widget.comment.userVote ?? 0;
      _content = widget.comment.content;
      _replies = widget.comment.replies;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _editController.dispose();
    super.dispose();
  }

  void _handleVote(int type) {
    if (!widget.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Log in to vote')));
      return;
    }

    final previousVote = _userVote;
    final previousScore = _score;

    int newVote = type;
    int scoreDelta = 0;

    if (previousVote == type) {
      newVote = 0;
      scoreDelta = -type;
    } else {
      if (previousVote != 0) {
        scoreDelta = type * 2;
      } else {
        scoreDelta = type;
      }
    }

    setState(() {
      _userVote = newVote;
      _score = previousScore + scoreDelta;
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        await commentumClient.voteComment(widget.comment.id, newVote);
      } catch (e) {
        if (mounted) {
          setState(() {
            _userVote = previousVote;
            _score = previousScore;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Vote failed: $e')));
        }
      }
    });
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
      _editController.text = _content;
    });
  }

  Future<void> _saveEdit() async {
    final newContent = _editController.text.trim();
    if (newContent.isEmpty || newContent == _content) {
      setState(() => _isEditing = false);
      return;
    }

    final previousContent = _content;
    setState(() {
      _content = newContent;
      _isEditing = false;
    });

    try {
      await commentumClient.updateComment(widget.comment.id, newContent);
    } catch (e) {
      if (mounted) {
        setState(() => _content = previousContent);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update comment: $e')));
      }
    }
  }

  Future<void> _deleteComment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await commentumClient.deleteComment(widget.comment.id);
      if (widget.onRemove != null) {
        widget.onRemove!();
      } else {
        if (mounted) widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete comment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasReplies = _replies.isNotEmpty;
    final isRoot = widget.depth == 0;
    final auth = ref.watch(authProvider);
    final isOwner =
        auth.userFor(auth.activePlatform)?.name == widget.comment.username;

    // Content Widget
    final contentWidget = Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primaryContainer,
                backgroundImage: (widget.comment.avatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(widget.comment.avatarUrl!)
                    : null,
                child: (widget.comment.avatarUrl?.isNotEmpty ?? false)
                    ? null
                    : Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.comment.username,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${_getTimeAgo(widget.comment.createdAt.toString())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (isOwner)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Options',
                  padding: EdgeInsets.zero,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') _startEdit();
                    if (value == 'delete') _deleteComment();
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _editController,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                  ),
                  onPressed: _saveEdit,
                  tooltip: 'Save',
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  onPressed: () => setState(() => _isEditing = false),
                  tooltip: 'Cancel',
                ),
              ],
            )
          else
            Text(
              _content,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          Row(
            children: [
              InkWell(
                onTap: () => _handleVote(1),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    _userVote == 1
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 18,
                    color: _userVote == 1
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$_score',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _userVote != 0
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              InkWell(
                onTap: () => _handleVote(-1),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    _userVote == -1
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 18,
                    color: _userVote == -1
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (widget.isLoggedIn)
                InkWell(
                  onTap: () => widget.onReply(widget.comment),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text('Reply', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ),
                ),
              const Spacer(),
              if (widget.isLoggedIn)
                InkWell(
                  onTap: _showReportDialog,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (!hasReplies) {
      return contentWidget;
    }

    // Threaded View
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: contentWidget,
        ),
        if (_isExpanded)
          ..._replies.asMap().entries.map((entry) {
            final index = entry.key;
            final childComment = entry.value;
            final isLast = index == _replies.length - 1;

            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: isRoot ? 46 : 32,
                  child: CustomPaint(
                    painter: _ThreadLinePainter(
                      isLast: isLast,
                      avatarRadius: 14,
                      leftOffset: isRoot ? 29 : 15,
                      context: context,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: isRoot ? 46 : 32),
                  child: _CommentItem(
                    childComment,
                    depth: widget.depth + 1,
                    onRefresh: widget.onRefresh,
                    isLoggedIn: widget.isLoggedIn,
                    onReply: widget.onReply,
                    onRemove: () {
                      setState(() {
                        _replies.removeAt(index);
                      });
                    },
                  ),
                ),
              ],
            );
          }),
        if (!_isExpanded)
          Padding(
            padding: EdgeInsets.only(left: isRoot ? 50 : 24, bottom: 8),
            child: Text(
              'Click to see ${_replies.length} replies...',
              style: TextStyle(color: colorScheme.primary, fontSize: 12),
            ),
          ),
      ],
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
        return AlertDialog(
          title: const Text('Report Comment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: reasons
                .map(
                  (r) => ListTile(
                    title: Text(r),
                    dense: true,
                    onTap: () => Navigator.pop(context, r),
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      try {
        await widget.comment.report(commentumClient, result);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Report submitted')));
        }
      } catch (e) {
        // Handle error silently or show snackbar
      }
    }
  }
}

class _ThreadLinePainter extends CustomPainter {
  final bool isLast;
  final double avatarRadius;
  final double leftOffset;
  final BuildContext context;

  _ThreadLinePainter({
    required this.isLast,
    required this.avatarRadius,
    required this.leftOffset,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);
    final paint = Paint()
      ..color = theme.colorScheme.surfaceContainerHighest
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    // Vertical Line
    path.moveTo(leftOffset, 0);

    // Child avatar center y = 8 (padding) + 14 (radius) = 22
    final avatarCenterY = 8.0 + avatarRadius;

    if (isLast) {
      // Connect to child (Curved L)
      path.lineTo(leftOffset, avatarCenterY - 10);
      path.quadraticBezierTo(
        leftOffset,
        avatarCenterY,
        leftOffset + 10,
        avatarCenterY,
      );
      path.lineTo(size.width, avatarCenterY);
    } else {
      // Continue down + Branch
      path.lineTo(leftOffset, size.height);

      // Branch
      final branchPath = Path();
      branchPath.moveTo(leftOffset, avatarCenterY);
      branchPath.lineTo(size.width, avatarCenterY);
      canvas.drawPath(branchPath, paint);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CommentInputBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isPosting;
  final AuthUser? user;
  final VoidCallback onSubmit;
  final Comment? replyingTo;
  final VoidCallback? onCancelReply;

  const _CommentInputBox({
    required this.controller,
    required this.focusNode,
    required this.isPosting,
    required this.user,
    required this.onSubmit,
    this.replyingTo,
    this.onCancelReply,
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
    if (hasText != _hasText) setState(() => _hasText = hasText);
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.replyingTo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.reply_rounded,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Replying to ${widget.replyingTo!.username}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: widget.onCancelReply,
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: widget.user?.avatarUrl != null
                      ? NetworkImage(widget.user!.avatarUrl!)
                      : null,
                  child: widget.user?.avatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 18,
                          color: colorScheme.onPrimaryContainer,
                        )
                      : null,
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
                      ),
                    ),
                    child: TextField(
                      controller: widget.controller,
                      focusNode: widget.focusNode,
                      enabled: !widget.isPosting,
                      maxLines: null,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: widget.replyingTo != null
                            ? 'Reply to ${widget.replyingTo!.username}...'
                            : 'Add a comment...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _hasText ? widget.onSubmit : null,
                  icon: widget.isPosting
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: _hasText
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
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
