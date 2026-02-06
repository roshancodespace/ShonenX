import 'dart:convert';
import 'package:flutter_qjs/flutter_qjs.dart';
import 'package:shonenx/core/anilist/services/anilist_service.dart';

class JsAnilistService {
  late JavascriptRuntime runtime;
  final AnilistService? anilistService;

  JsAnilistService(this.runtime, this.anilistService);

  void init() {
    if (anilistService == null) {
      runtime.evaluate('''
        class Anilist {
            async searchAnime(title, page, perPage, filter) {
                throw new Error("Anilist service not available");
            }
            async getGenres() {
                throw new Error("Anilist service not available");
            }
            async getTags() {
                throw new Error("Anilist service not available");
            }
            async getAnimeDetails(animeId) {
                throw new Error("Anilist service not available");
            }
            async getTrendingAnime(page, perPage) {
                throw new Error("Anilist service not available");
            }
            async getPopularAnime(page, perPage) {
                throw new Error("Anilist service not available");
            }
            async getTopRatedAnime(page, perPage) {
                throw new Error("Anilist service not available");
            }
            async getRecentlyUpdatedAnime(page, perPage) {
               throw new Error("Anilist service not available");
            }
            async getUpcomingAnime(page, perPage) {
               throw new Error("Anilist service not available");
            }
            async getMostFavoriteAnime(page, perPage) {
               throw new Error("Anilist service not available");
            }
        }
        ''');
      return;
    }

    runtime.onMessage('anilist_searchAnime', (dynamic args) async {
      final res = await anilistService!.searchAnime(
        args[0],
        page: args[1],
        perPage: args[2],
      );
      return jsonEncode(res.map((e) => e.toJson()).toList());
    });

    runtime.onMessage('anilist_getGenres', (dynamic args) async {
      return jsonEncode(await anilistService!.getGenres());
    });

    runtime.onMessage('anilist_getTags', (dynamic args) async {
      return jsonEncode(await anilistService!.getTags());
    });

    runtime.onMessage('anilist_getAnimeDetails', (dynamic args) async {
      final id = int.tryParse(args[0].toString()) ?? -1;
      final res = await anilistService!.getAnimeDetails(id);
      return jsonEncode(res?.toJson());
    });

    runtime.onMessage('anilist_getTrendingAnime', (dynamic args) async {
      final res = await anilistService!.getTrendingAnime(
        page: args[0],
        perPage: args[1],
      );
      return jsonEncode(res.map((e) => e.toJson()).toList());
    });

    runtime.onMessage('anilist_getPopularAnime', (dynamic args) async {
      final res = await anilistService!.getPopularAnime(
        page: args[0],
        perPage: args[1],
      );
      return jsonEncode(res.map((e) => e.toJson()).toList());
    });

    runtime.onMessage('anilist_getTopRatedAnime', (dynamic args) async {
      final res = await anilistService!.getTopRatedAnime(
        page: args[0],
        perPage: args[1],
      );
      return jsonEncode(res.map((e) => e.toJson()).toList());
    });

    runtime.onMessage('anilist_getRecentlyUpdatedAnime', (dynamic args) async {
      final res = await anilistService!.getRecentlyUpdatedAnime(
        page: args[0],
        perPage: args[1],
      );
      return jsonEncode(res.map((e) => e.toJson()).toList());
    });

    runtime.onMessage('anilist_getUpcomingAnime', (dynamic args) async {
      final res = await anilistService!.getUpcomingAnime(
        page: args[0],
        perPage: args[1],
      );
      return jsonEncode(res.map((e) => e.toJson()).toList());
    });

    runtime.onMessage('anilist_getMostFavoriteAnime', (dynamic args) async {
      final res = await anilistService!.getMostFavoriteAnime(
        page: args[0],
        perPage: args[1],
      );
      return jsonEncode(res.map((e) => e.toJson()).toList());
    });

    runtime.evaluate('''
class Anilist {
    async searchAnime(title, page, perPage, filter) {
         const result = await sendMessage("anilist_searchAnime", JSON.stringify([title, page, perPage, filter]));
        return JSON.parse(result);
    }
    async getGenres() {
         const result = await sendMessage("anilist_getGenres", JSON.stringify([]));
        return JSON.parse(result);
    }
    async getTags() {
         const result = await sendMessage("anilist_getTags", JSON.stringify([]));
        return JSON.parse(result);
    }
    async getAnimeDetails(animeId) {
         const result = await sendMessage("anilist_getAnimeDetails", JSON.stringify([animeId]));
        return JSON.parse(result);
    }
    async getTrendingAnime(page, perPage) {
         const result = await sendMessage("anilist_getTrendingAnime", JSON.stringify([page, perPage]));
        return JSON.parse(result);
    }
    async getPopularAnime(page, perPage) {
         const result = await sendMessage("anilist_getPopularAnime", JSON.stringify([page, perPage]));
        return JSON.parse(result);
    }
    async getTopRatedAnime(page, perPage) {
         const result = await sendMessage("anilist_getTopRatedAnime", JSON.stringify([page, perPage]));
        return JSON.parse(result);
    }
    async getRecentlyUpdatedAnime(page, perPage) {
         const result = await sendMessage("anilist_getRecentlyUpdatedAnime", JSON.stringify([page, perPage]));
        return JSON.parse(result);
    }
    async getUpcomingAnime(page, perPage) {
         const result = await sendMessage("anilist_getUpcomingAnime", JSON.stringify([page, perPage]));
        return JSON.parse(result);
    }
    async getMostFavoriteAnime(page, perPage) {
         const result = await sendMessage("anilist_getMostFavoriteAnime", JSON.stringify([page, perPage]));
        return JSON.parse(result);
    }
}
''');
  }
}
