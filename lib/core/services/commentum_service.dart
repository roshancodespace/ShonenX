import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shonenx/core/models/commentum/comment.dart';
import 'package:shonenx/core/models/commentum/error.dart';
import 'package:shonenx/core/models/commentum/user.dart';
import 'package:shonenx/core/utils/env_loader.dart';

class CommentumService {
  static const String _baseUrl = COMMENTUM_API_URL;

  static final Map<String, String> _jwtTokens = {};
  static String? _activeProvider;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _tokenKeyPrefix = 'commentum_jwt_';

  /// Call this when the app starts to load stored tokens
  static Future<void> init() async {
    final anilistToken = await _storage.read(key: '${_tokenKeyPrefix}anilist');
    final malToken = await _storage.read(key: '${_tokenKeyPrefix}mal');

    if (anilistToken != null) _jwtTokens['anilist'] = anilistToken;
    if (malToken != null) _jwtTokens['mal'] = malToken;
  }

  static void setActiveProvider(String? provider) {
    _activeProvider = provider;
  }

  static String? get _currentToken =>
      _activeProvider != null ? _jwtTokens[_activeProvider] : null;

  static Future<dynamic> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? params,
    bool isRetry = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: params?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_currentToken != null) 'Authorization': 'Bearer $_currentToken',
    };

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'PATCH':
          response = await http.patch(
            uri,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        case 'DELETE':
          response = await http.delete(
            uri,
            headers: headers,
            body: jsonEncode(body),
          );
          break;
        default:
          response = await http.get(uri, headers: headers);
      }

      final data = jsonDecode(response.body);

      // Handle 401 Unauthorized with silent re-login
      if (response.statusCode == 401 &&
          !isRetry &&
          _activeProvider != null &&
          endpoint != '/auth') {
        // This is where you read the access token baka
        final providerToken = await _storage.read(
          key: '$_activeProvider-token',
        );

        if (providerToken != null) {
          try {
            // Attempt silent login
            await login(_activeProvider!, providerToken);
            // Retry original request
            return await _request(
              endpoint,
              method: method,
              body: body,
              params: params,
              isRetry: true,
            );
          } catch (e) {
            // If re-login fails, fall through to throw the original error
          }
        }
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CommentumError(
          data['error'] ?? 'Server Error',
          response.statusCode,
        );
      }

      return data;
    } catch (e) {
      if (e is CommentumError) rethrow;
      throw CommentumError('Failed to communicate with proxy: $e', 500);
    }
  }

  // --- Authentication ---

  static Future<void> login(String provider, String accessToken) async {
    final data = await _request(
      '/auth',
      method: 'POST',
      body: {'provider': provider, 'access_token': accessToken},
    );

    final token = data['token'];
    _jwtTokens[provider] = token;
    await _storage.write(key: '$_tokenKeyPrefix$provider', value: token);

    // Automatically set as active if logging in
    setActiveProvider(provider);
  }

  static Future<void> logout(String provider) async {
    final oldActive = _activeProvider;
    _activeProvider = provider;

    if (_currentToken != null) {
      try {
        await _request('/auth', method: 'DELETE');
      } catch (_) {
        // Ignore errors during logout
      }
    }

    _jwtTokens.remove(provider);
    await _storage.delete(key: '$_tokenKeyPrefix$provider');

    if (oldActive == provider) {
      _activeProvider = null;
    } else {
      _activeProvider = oldActive;
    }
  }

  static Future<User> getMe() async {
    final data = await _request('/me');
    return User.fromJson(data['user']);
  }

  // --- Comments ---

  static Future<Comment> createComment(String mediaId, String content) async {
    final data = await _request(
      '/posts',
      method: 'POST',
      body: {'media_id': mediaId, 'content': content},
    );
    return Comment.fromJson(data['post']);
  }

  static Future<Map<String, dynamic>> listComments(
    String mediaId, {
    int limit = 20,
    String? cursor,
  }) async {
    final params = {'media_id': mediaId, 'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;

    final data = await _request('/posts', params: params);
    return {
      'comments': (data['comments'] as List)
          .map((c) => Comment.fromJson(c))
          .toList(),
      'next_cursor': data['next_cursor'],
    };
  }

  static Future<Map<String, dynamic>> voteComment(
    String commentId,
    int voteType, // 1: Upvote, -1 Downvote
  ) async {
    return await _request(
      '/votes',
      method: 'POST',
      body: {'post_id': commentId, 'vote_type': voteType},
    );
  }

  // --- Replies ---

  static Future<Reply> createReply(String parentId, String content) async {
    final data = await _request(
      '/posts',
      method: 'POST',
      body: {'parent_id': parentId, 'content': content},
    );
    return Comment.fromJson(data['post']);
  }

  static Future<Map<String, dynamic>> listReplies(
    String rootId, {
    int limit = 20,
    String? cursor,
    String? parentId,
  }) async {
    final params = {'root_id': rootId, 'limit': limit.toString()};
    if (parentId != null) params['parent_id'] = parentId;
    if (cursor != null) params['cursor'] = cursor;

    final data = await _request('/posts', params: params);
    return {
      'replies': (data['replies'] as List)
          .map((r) => Reply.fromJson(r))
          .toList(),
      'next_cursor': data['next_cursor'],
    };
  }

  // --- Moderation ---

  static Future<void> setCommentStatus(
    String commentId,
    CommentStatus status,
  ) async {
    await _request(
      '/moderation-comment-status',
      method: 'POST',
      body: {'comment_id': commentId, 'status': status.name},
    );
  }

  static Future<void> reportComment({
    required String commentId,
    required String reason,
    Map<String, dynamic>? reporterInfo,
  }) async {
    await _request(
      '/reports',
      method: 'POST',
      body: {'comment_id': commentId, 'reason': reason},
    );
  }

  static Future<void> deleteComment(String commentId) async {
    await _request('/posts?id=$commentId', method: 'DELETE');
  }

  static Future<Comment> updateComment(String commentId, String content) async {
    final data = await _request(
      '/posts?id=$commentId',
      method: 'PATCH',
      body: {'content': content},
    );
    return Comment.fromJson(data['post']);
  }
}
