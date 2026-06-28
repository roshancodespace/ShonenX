import 'package:commentum_client/commentum_client.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class CommentComposer extends StatelessWidget {
  final TextEditingController controller;
  final Comment? replyingTo;
  final VoidCallback? onCancelReply;
  final VoidCallback? onSubmit;
  final bool isSubmitting;
  final double? uiRoundness;

  const CommentComposer({
    super.key,
    required this.controller,
    this.replyingTo,
    this.onCancelReply,
    this.onSubmit,
    this.isSubmitting = false,
    this.uiRoundness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final baseRoundness = uiRoundness ?? GlobalUI.uiRoundness;
    final outerRadius = baseRoundness * 2;
    final innerRadius = outerRadius > 6 ? outerRadius - 6 : outerRadius;

    return Container(
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(outerRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyingTo != null)
            Container(
              margin: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 10,
                bottom: 2,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(baseRoundness * 1.2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.reply_rounded,
                    size: 16,
                    color: cs.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to @${replyingTo!.username}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: onCancelReply,
                    borderRadius: BorderRadius.circular(baseRoundness),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(
              left: 18,
              right: 6,
              top: 6,
              bottom: 6,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLength: 500,
                    maxLines: 4,
                    minLines: 1,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: replyingTo != null
                          ? 'Reply to @${replyingTo!.username}...'
                          : 'Add a comment...',
                      hintStyle: TextStyle(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      filled: true,
                      fillColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(innerRadius),
                      ),
                    ),
                    onPressed: isSubmitting ? null : onSubmit,
                    icon: isSubmitting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
