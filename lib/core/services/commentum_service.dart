import 'dart:convert';

import 'package:shonenx/core/models/commentum/comment.dart';
import 'package:shonenx/core/models/commentum/media.dart';
import 'package:shonenx/core/models/commentum/response.dart';
import 'package:shonenx/core/network/universal_client.dart';
import 'package:shonenx/core/utils/env_loader.dart';

class CommentumService {
  static const String baseUrl = COMMENTUM_API_URL;

  static Future<CommentumResponse> getComments({
    required String mediaId,
    required String mediaType,
    required int page,
    required int limit,
    required String sortBy,
    required String sortOrder,
  }) async {
    final response = await UniversalHttpClient.instance.get(
      Uri.parse(
        '$baseUrl/media?media_id=$mediaId&client_type=$mediaType&limit=$limit&page=$page&sort=$sortBy',
      ),
    );
    final json = jsonDecode(response.body);
    return CommentumResponse.fromJson(json);
  }

  static Future<Comment> createComment({
    required String clientType,
    required Map<String, dynamic> userInfo,
    required CommentumMedia mediaInfo,
    required String content,
    String? tag,
    int? parentId,
  }) async {
    final body = {
      "action": "create",
      "client_type": clientType,
      "user_info": userInfo,
      "media_info": {
        "media_id": mediaInfo.mediaId,
        "type": mediaInfo.mediaType,
        "title": mediaInfo.mediaTitle,
        "year": mediaInfo.mediaYear,
        "poster": mediaInfo.mediaPoster,
      },
      "content": content,
      "parent_id": parentId,
      if (tag != null) "tag": tag,
    };

    final response = await UniversalHttpClient.instance.post(
      Uri.parse('$baseUrl/comments'),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);
    if (json['success'] == true) {
      return Comment.fromJson(json['comment']);
    } else {
      throw Exception(json['error'] ?? 'Failed to create comment');
    }
  }

  static Future<Comment> editComment({
    required int commentId,
    required Map<String, dynamic> userInfo,
    required String content,
  }) async {
    final body = {
      "action": "edit",
      "comment_id": commentId,
      "user_info": userInfo,
      "content": content,
    };

    final response = await UniversalHttpClient.instance.post(
      Uri.parse('$baseUrl/comments'),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);
    if (json['success'] == true) {
      return Comment.fromJson(json['comment']);
    } else {
      throw Exception(json['error'] ?? 'Failed to edit comment');
    }
  }

  static Future<void> deleteComment({
    required int commentId,
    required Map<String, dynamic> userInfo,
  }) async {
    final body = {
      "action": "delete",
      "comment_id": commentId,
      "user_info": userInfo,
    };

    final response = await UniversalHttpClient.instance.post(
      Uri.parse('$baseUrl/comments'),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);
    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'Failed to delete comment');
    }
  }

  static Future<Map<String, dynamic>> voteComment({
    required int commentId,
    required Map<String, dynamic> userInfo,
    required String voteType,
  }) async {
    final body = {
      "comment_id": commentId,
      "user_info": userInfo,
      "vote_type": voteType,
    };

    final response = await UniversalHttpClient.instance.post(
      Uri.parse('$baseUrl/votes'),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);
    if (json['success'] == true) {
      return json;
    } else {
      throw Exception(json['error'] ?? 'Failed to vote');
    }
  }

  static Future<void> reportComment({
    required int commentId,
    required Map<String, dynamic> reporterInfo,
    required String reason,
    String? notes,
  }) async {
    final body = {
      "action": "create",
      "comment_id": commentId,
      "reporter_info": reporterInfo,
      "reason": reason,
      if (notes != null) "notes": notes,
    };

    final response = await UniversalHttpClient.instance.post(
      Uri.parse('$baseUrl/reports'),
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );

    final json = jsonDecode(response.body);
    if (json['success'] != true) {
      throw Exception(json['error'] ?? 'Failed to report comment');
    }
  }
}
