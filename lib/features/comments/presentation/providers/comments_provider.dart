import 'dart:async';
import 'package:anymex_extension_runtime_bridge/Services/Mangayomi/Util/string_extensions.dart';
import 'package:commentum_client/commentum_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/commentum/commentum_client.dart';
import 'package:shonenx/core/utils/formatting.dart';

class CommentsArgs {
  final String mediaId;
  final String mediaProvider;
  final int? episodeNumber;

  const CommentsArgs({
    required this.mediaId,
    required this.mediaProvider,
    this.episodeNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentsArgs &&
          other.mediaId == mediaId &&
          other.mediaProvider == mediaProvider &&
          other.episodeNumber == episodeNumber;

  @override
  int get hashCode => Object.hash(mediaId, mediaProvider, episodeNumber);
}

class CommentsState {
  final List<Comment> comments;
  final bool isMoreLoading;
  final String? nextCursor;
  final String? error;

  const CommentsState({
    required this.comments,
    this.isMoreLoading = false,
    this.nextCursor,
    this.error,
  });

  CommentsState copyWith({
    List<Comment>? comments,
    bool? isMoreLoading,
    String? nextCursor,
    String? error,
    bool clearError = false,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      nextCursor: nextCursor ?? this.nextCursor,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, CommentsState, CommentsArgs>(
      CommentsNotifier.new,
    );

class CommentsNotifier extends AsyncNotifier<CommentsState> {
  CommentsArgs arg;

  CommentumClient get _client => ref.read(commentumClientProvider);

  CommentsNotifier(this.arg);

  @override
  Future<CommentsState> build() async {
    // Ensure client auth sessions are initialized
    await _client.init();

    try {
      final response = await _client.listComments(
        mediaId: arg.mediaId,
        limit: 20,
        episodeNumber: formatEpisodeNumber(arg.episodeNumber)?.toInt(),
      );
      return CommentsState(
        comments: response.data,
        nextCursor: response.nextCursor,
      );
    } catch (e) {
      // If listing fails due to network or empty server, start with empty list
      return CommentsState(comments: [], error: e.toString());
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null ||
        current.isMoreLoading ||
        current.nextCursor == null) {
      return;
    }

    state = AsyncData(current.copyWith(isMoreLoading: true, clearError: true));

    try {
      final response = await _client.listComments(
        mediaId: arg.mediaId,
        limit: 20,
        cursor: current.nextCursor,
        episodeNumber: formatEpisodeNumber(arg.episodeNumber)?.toInt(),
      );

      final updatedComments = [...current.comments, ...response.data];
      state = AsyncData(
        current.copyWith(
          comments: updatedComments,
          isMoreLoading: false,
          nextCursor: response.nextCursor,
        ),
      );
    } catch (e) {
      state = AsyncData(
        current.copyWith(
          isMoreLoading: false,
          error: 'Failed to load more comments: $e',
        ),
      );
    }
  }

  Future<Comment> postComment(String content) async {
    final comment = await _client.createComment(
      mediaId: arg.mediaId,
      mediaProvider: arg.mediaProvider,
      content: content,
      episodeNumber: formatEpisodeNumber(arg.episodeNumber)?.toInt(),
    );

    final current = state.value;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          comments: [comment, ...current.comments],
          clearError: true,
        ),
      );
    }
    return comment;
  }

  Future<Comment> postReply(String parentId, String content) async {
    final reply = await _client.createReply(
      parentId: parentId,
      content: content,
    );

    final current = state.value;
    if (current != null) {
      final updated = _insertReplyRecursive(current.comments, parentId, reply);
      state = AsyncData(current.copyWith(comments: updated, clearError: true));
    }
    return reply;
  }

  List<Comment> _insertReplyRecursive(
    List<Comment> list,
    String parentId,
    Comment reply,
  ) {
    return list.map((c) {
      if (c.id == parentId) {
        return c.copyWith(
          replies: [...c.replies, reply],
          repliesCount: c.repliesCount + 1,
        );
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(
          replies: _insertReplyRecursive(c.replies, parentId, reply),
        );
      }
      return c;
    }).toList();
  }

  Future<void> vote(String commentId, int voteType) async {
    // Optimistic UI update
    final current = state.value;
    if (current != null) {
      final updated = _updateVoteRecursive(
        current.comments,
        commentId,
        voteType,
      );
      state = AsyncData(current.copyWith(comments: updated));
    }

    try {
      await _client.voteComment(commentId: commentId, voteType: voteType);
    } catch (e) {
      // Revert or refresh on error
      ref.invalidateSelf();
      rethrow;
    }
  }

  List<Comment> _updateVoteRecursive(
    List<Comment> list,
    String targetId,
    int newVote,
  ) {
    return list.map((c) {
      if (c.id == targetId) {
        final oldVote = c.userVote ?? 0;
        final finalVote = (oldVote == newVote) ? null : newVote;
        final scoreDiff = (finalVote ?? 0) - oldVote;
        return c.copyWith(score: c.score + scoreDiff, userVote: finalVote);
      }
      if (c.replies.isNotEmpty) {
        return c.copyWith(
          replies: _updateVoteRecursive(c.replies, targetId, newVote),
        );
      }
      return c;
    }).toList();
  }

  Future<void> deleteComment(String commentId) async {
    await _client.deleteComment(commentId: commentId);
    final current = state.value;
    if (current != null) {
      final updated = _deleteRecursive(current.comments, commentId);
      state = AsyncData(current.copyWith(comments: updated));
    }
  }

  List<Comment> _deleteRecursive(List<Comment> list, String targetId) {
    return list.where((c) => c.id != targetId).map((c) {
      if (c.replies.isNotEmpty) {
        return c.copyWith(replies: _deleteRecursive(c.replies, targetId));
      }
      return c;
    }).toList();
  }

  Future<void> reportComment(String commentId, String reason) async {
    await _client.reportComment(commentId: commentId, reason: reason);
  }
}
