import 'package:commentum_client/commentum_client.dart';
import 'package:flutter/material.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final void Function(Comment) onReply;
  final void Function(Comment, int) onVote;
  final void Function(Comment) onDelete;
  final bool isReply;

  const CommentItem({
    super.key,
    required this.comment,
    required this.onReply,
    required this.onVote,
    required this.onDelete,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final userVote = comment.userVote ?? 0;

    return Padding(
      padding: isReply
          ? const EdgeInsets.only(top: 10, bottom: 2)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 16,
            backgroundImage: comment.avatarUrl != null
                ? NetworkImage(comment.avatarUrl!)
                : null,
            backgroundColor: cs.surfaceContainerHighest,
            child: comment.avatarUrl == null
                ? Text(
                    comment.username.isNotEmpty
                        ? comment.username[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontSize: isReply ? 11 : 13,
                    ),
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
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              comment.username,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: isReply ? 12.5 : 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comment.mediaProvider != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '· ${comment.mediaProvider!.toUpperCase()}',
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.centerRight,
                        child: Text(
                          _formatDate(comment.createdAt),
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                    fontSize: isReply ? 13 : 14,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => onVote(comment, 1),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 14,
                                    color: userVote == 1
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comment.score}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: (userVote != 0)
                                          ? (userVote == 1
                                                ? cs.primary
                                                : cs.error)
                                          : cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 12,
                            color: cs.outlineVariant.withValues(alpha: 0.25),
                          ),
                          InkWell(
                            onTap: () => onVote(comment, -1),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                size: 14,
                                color: userVote == -1
                                    ? cs.error
                                    : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: cs.onSurfaceVariant,
                      ),
                      onPressed: () => onReply(comment),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          size: 16,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (val) {
                          if (val == 'delete') onDelete(comment);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'report',
                            child: Text('Report'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (comment.replies.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              color: cs.outlineVariant.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final reply in comment.replies)
                                CommentItem(
                                  comment: reply,
                                  onReply: onReply,
                                  onVote: onVote,
                                  onDelete: onDelete,
                                  isReply: true,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    final days = diff.inDays;
    if (days >= 365) {
      final years = (days / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
    if (days >= 30) {
      final months = (days / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    if (days >= 7) {
      final weeks = (days / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    if (days > 0) return '$days ${days == 1 ? 'day' : 'days'} ago';
    if (diff.inHours > 0) return '${diff.inHours} ${diff.inHours == 1 ? 'hr' : 'hrs'} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
    return 'just now';
  }
}
