package com.aayush262.dartotsu_extension_bridge.aniyomi

import eu.kanade.tachiyomi.PreferenceScreen
import eu.kanade.tachiyomi.animesource.model.AnimesPage
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.animesource.model.SEpisode
import eu.kanade.tachiyomi.animesource.model.Video
import eu.kanade.tachiyomi.source.model.Page
import eu.kanade.tachiyomi.source.model.SChapter
import eu.kanade.tachiyomi.source.model.SManga

interface AniyomiSourceMethods {
    var baseUrl: String?
    /**
     * Fetches a page of popular anime.
     *
     * @param page The page number to fetch.
     * @return An [AnimesPage] containing the list of popular anime and a flag indicating if there are more pages.
     */
    suspend fun getPopular(page: Int): AnimesPage

    /**
     * Fetches a page of latest updates.
     *
     * @param page The page number to fetch.
     * @return An [AnimesPage] containing the list of latest updates and a flag indicating if there are more pages.
     */
    suspend fun getLatestUpdates(page: Int): AnimesPage

    /**
     * Fetches a page of search results based on the query.
     *
     * @param query The search query.
     * @param page The page number to fetch.
     * @return An [AnimesPage] containing the search results and a flag indicating if there are more pages.
     */
    suspend fun getSearchResults(query: String, page: Int): AnimesPage

    /**
     * Fetches the details of a specific anime.
     *
     * @param media The [SAnime] object containing the identifier of the anime.
     * @return An [SAnime] object with the details of the anime.
     */
    suspend fun getDetails(media: SAnime): SAnime

    /**
     * Fetches a list of episodes for a specific anime.
     *
     * @param media The [SAnime] object containing the identifier of the anime.
     * @return A list of [SEpisode] objects representing the episodes of the anime.
     */
    suspend fun getEpisodeList(media: SAnime): List<SEpisode>

    /**
     * Fetches a list of videos for a specific episode.
     *
     * @param episode The [SEpisode] object containing the identifier of the episode.
     * @return A list of [Video] objects representing the videos available for the episode.
     */
    suspend fun getVideoList(episode: SEpisode): List<Video>

    /**
     * Fetches a list of chapters for a specific manga.
     *
     * @param media The [SManga] object containing the identifier of the manga.
     * @return A list of [SChapter] objects representing the chapters of the manga.
     */
    suspend fun getChapterList(media: SAnime): List<SEpisode>

    /**
     * Fetches a list of pages for a specific chapter.
     *
     * @param chapter The [SChapter] object containing the identifier of the chapter.
     * @return A list of [Page] objects representing the pages of the chapter.
     */
    suspend fun getPageList(chapter: SChapter): List<Page>


    fun setupPreferenceScreen(screen: PreferenceScreen)
}