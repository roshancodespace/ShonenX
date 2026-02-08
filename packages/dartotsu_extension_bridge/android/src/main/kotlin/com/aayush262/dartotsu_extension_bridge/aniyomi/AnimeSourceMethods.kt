package com.aayush262.dartotsu_extension_bridge.aniyomi

import eu.kanade.tachiyomi.PreferenceScreen
import eu.kanade.tachiyomi.animesource.AnimeCatalogueSource
import eu.kanade.tachiyomi.animesource.ConfigurableAnimeSource
import eu.kanade.tachiyomi.animesource.model.AnimesPage
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.animesource.model.SEpisode
import eu.kanade.tachiyomi.animesource.model.Video
import eu.kanade.tachiyomi.animesource.online.AnimeHttpSource
import eu.kanade.tachiyomi.source.model.Page
import eu.kanade.tachiyomi.source.model.SChapter
import eu.kanade.tachiyomi.source.model.SManga
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.get

class AnimeSourceMethods(sourceID: String, langIndex: Int = 0) : AniyomiSourceMethods {

    private val source: AnimeCatalogueSource
    init {
        val manager = Injekt.get<AniyomiExtensionManager>()
        val extension = manager.installedAnimeExtensions
            .find { it.pkgName == sourceID }
            ?: throw IllegalArgumentException("Anime source with ID '$sourceID' not found.")

        val src = extension.sources.getOrNull(langIndex) ?: extension.sources.firstOrNull()

        source = src as? AnimeHttpSource ?: src as? AnimeCatalogueSource
                ?: throw IllegalArgumentException("Source with ID '$sourceID' is not an AnimeHttpSource or AnimeCatalogueSource")
    }

    override var baseUrl = (source as? AnimeHttpSource)?.baseUrl

    override suspend fun getPopular(page: Int): AnimesPage = source.getPopularAnime(page)

    override suspend fun getLatestUpdates(page: Int): AnimesPage = source.getLatestUpdates(page)


    override suspend fun getSearchResults(query: String, page: Int): AnimesPage =
        source.getSearchAnime(
            page = page,
            query = query,
            filters = source.getFilterList()
        )

    override suspend fun getDetails(media: SAnime): SAnime = source.getAnimeDetails(media)

    override suspend fun getEpisodeList(media: SAnime): List<SEpisode> = source.getEpisodeList(media)

    override suspend fun getVideoList(episode: SEpisode): List<Video> {
        if ((source as AnimeHttpSource).javaClass.declaredMethods.any { it.name == "getHosterList" }) {
            val hosters = source.getHosterList(episode)
            val allVideos = hosters.flatMap { hoster ->
                val videos = source.getVideoList(hoster)
                videos.map { it.copy(videoTitle = "${hoster.hosterName} - ${it.videoTitle}") }
            }
            return allVideos
        } else {
            return source.getVideoList(episode)
        }
    }

    override suspend fun getChapterList(media: SAnime): List<SEpisode> =
        throw UnsupportedOperationException("Chapters are not supported in anime sources.")

    override suspend fun getPageList(chapter: SChapter): List<Page> =
        throw UnsupportedOperationException("Pages are not supported in anime sources.")

    override fun setupPreferenceScreen(screen: PreferenceScreen) {
        if (source is ConfigurableAnimeSource) {
            source.setupPreferenceScreen(screen)
        } else {
            throw NoPreferenceScreenException("This source does not support preferences.")
        }
    }
}
class NoPreferenceScreenException(message: String) : Exception(message)

