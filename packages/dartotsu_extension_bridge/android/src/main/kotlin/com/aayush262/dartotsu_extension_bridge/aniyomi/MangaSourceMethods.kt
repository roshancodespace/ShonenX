package com.aayush262.dartotsu_extension_bridge.aniyomi

import android.util.Log
import com.aayush262.dartotsu_extension_bridge.Logger
import eu.kanade.tachiyomi.PreferenceScreen
import eu.kanade.tachiyomi.animesource.model.AnimeUpdateStrategy
import eu.kanade.tachiyomi.animesource.model.AnimesPage
import eu.kanade.tachiyomi.animesource.model.FetchType
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.animesource.model.SEpisode
import eu.kanade.tachiyomi.animesource.model.Video
import eu.kanade.tachiyomi.source.CatalogueSource
import eu.kanade.tachiyomi.source.ConfigurableSource
import eu.kanade.tachiyomi.source.model.MangasPage
import eu.kanade.tachiyomi.source.model.Page
import eu.kanade.tachiyomi.source.model.SChapter
import eu.kanade.tachiyomi.source.model.SManga
import eu.kanade.tachiyomi.source.model.UpdateStrategy
import eu.kanade.tachiyomi.source.online.HttpSource
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.get
import java.util.regex.Matcher
import java.util.regex.Pattern

class MangaSourceMethods(sourceID: String, langIndex: Int = 0) : AniyomiSourceMethods {

    private val source: CatalogueSource

    init {
        val manager = Injekt.get<AniyomiExtensionManager>()
        val extension = manager.installedMangaExtensions
            .find { it.sources.first().id.toString() == sourceID }
            ?: throw IllegalArgumentException("Manga source with ID '$sourceID' not found.")

        val src = extension.sources.getOrNull(langIndex) ?: extension.sources.firstOrNull()
        source = src as? HttpSource ?: src as? CatalogueSource
                ?: throw IllegalArgumentException("Source with ID '$sourceID' is not an HttpSource or CatalogueSource")
    }

    override var baseUrl = (source as? HttpSource)?.baseUrl

    override suspend fun getPopular(page: Int): AnimesPage {
        return mangaPageToAnimePage(source.getPopularManga(page))
    }

    override suspend fun getLatestUpdates(page: Int): AnimesPage {
        return mangaPageToAnimePage(source.getLatestUpdates(page))
    }

    override suspend fun getSearchResults(query: String, page: Int): AnimesPage {
        return mangaPageToAnimePage(
            source.getSearchManga(
                page = page,
                query = query,
                filters = source.getFilterList()
            )
        )
    }

    override suspend fun getDetails(media: SAnime): SAnime {
        return source.getMangaDetails(media.toSManga()).toSAnime()
    }

    override suspend fun getChapterList(media: SAnime): List<SEpisode> {
        return source.getChapterList(media.toSManga()).map { it.toSEpisode() }
    }

    override suspend fun getPageList( chapter: SChapter): List<Page> {
       return (source).getPageList(chapter)
    }

    override fun setupPreferenceScreen(screen: PreferenceScreen) {
        if (source is ConfigurableSource) {
            source.setupPreferenceScreen(screen)
        } else {
            throw NoPreferenceScreenException("This source does not support preferences.")
        }
    }

    override suspend fun getEpisodeList(media: SAnime): List<SEpisode> {
        throw UnsupportedOperationException()
    }

    override suspend fun getVideoList(episode: SEpisode): List<Video> {
        throw UnsupportedOperationException()
    }

    private fun mangaPageToAnimePage(mangaPage: MangasPage): AnimesPage {
        return AnimesPage(
            mangaPage.mangas.map { it.toSAnime() },
            mangaPage.hasNextPage
        )
    }
    fun SChapter.toSEpisode(): SEpisode {
        val chapter = this
        return object : SEpisode {
            override var url: String = chapter.url
            override var name: String = chapter.name
            override var date_upload: Long = chapter.date_upload
            override var episode_number: Float = findChapterNumber(chapter.name) ?: chapter.chapter_number
            override var fillermark: Boolean = false
            override var scanlator: String? = chapter.scanlator
            override var summary: String?= null
            override var preview_url: String? = null
        }
    }

    fun SAnime.toSManga(): SManga {
        val anime = this
        return object : SManga {
            override var url: String = anime.url
            override var title: String = anime.title
            override var artist: String? = anime.artist
            override var author: String? = anime.author
            override var description: String? = anime.description
            override var genre: String? = anime.genre
            override var status: Int = anime.status
            override var thumbnail_url: String? = anime.thumbnail_url
            override var update_strategy: UpdateStrategy = UpdateStrategy.ALWAYS_UPDATE
            override var initialized: Boolean = anime.initialized
        }
    }

    fun SManga.toSAnime(): SAnime {
        val manga = this

        return object : SAnime {
            override var url: String = runCatching { manga.url }.getOrElse {
                Logger.log("Uninitialized URL for SManga: ${safeUrl(manga)}")
                "[UNINITIALIZED_URL]"
            }

            override var title: String = runCatching { manga.title }.getOrElse {
                Logger.log( "Uninitialized title for SManga: ${safeTitle(manga)}")
                "[UNINITIALIZED_TITLE]"
            }

            override var artist: String? = runCatching { manga.artist }.getOrNull()
            override var author: String? = runCatching { manga.author }.getOrNull()
            override var description: String? = runCatching { manga.description }.getOrNull()
            override var genre: String? = runCatching { manga.genre }.getOrNull()
            override var status: Int = runCatching { manga.status }.getOrDefault(SAnime.UNKNOWN)
            override var thumbnail_url: String? = runCatching { manga.thumbnail_url }.getOrNull()
            override var background_url: String?
                get() = TODO("Not yet implemented")
                set(value) {}
            override var update_strategy: AnimeUpdateStrategy =
                runCatching { AnimeUpdateStrategy.ALWAYS_UPDATE }.getOrDefault(AnimeUpdateStrategy.ALWAYS_UPDATE)
            override var fetch_type: FetchType
                get() = TODO("Not yet implemented")
                set(value) {}
            override var season_number: Double = runCatching { 1.0 }.getOrDefault(0.0)
            override var initialized: Boolean = runCatching { manga.initialized }.getOrDefault(false)
        }
    }
    private fun safeTitle(manga: SManga): String =
        runCatching { manga.title }.getOrElse { "[UNINITIALIZED_TITLE]" }

    private fun safeUrl(manga: SManga): String =
        runCatching { manga.url }.getOrElse { "[UNINITIALIZED_URL]" }
    private val REGEX_ITEM = "[\\s:.\\-]*(\\d+\\.?\\d*)[\\s:.\\-]*"
    private val REGEX_PART_NUMBER = "(?<!part\\s)\\b(\\d+)\\b"
    private val REGEX_CHAPTER = "(chapter|chap|ch|c)${REGEX_ITEM}"
    fun findChapterNumber(text: String): Float? {
        val pattern: Pattern = Pattern.compile(REGEX_CHAPTER, Pattern.CASE_INSENSITIVE)
        val matcher: Matcher = pattern.matcher(text)

        return if (matcher.find()) {
            matcher.group(2)?.toFloat()
        } else {
            val failedChapterNumberPattern: Pattern =
                Pattern.compile(REGEX_PART_NUMBER, Pattern.CASE_INSENSITIVE)
            val failedChapterNumberMatcher: Matcher =
                failedChapterNumberPattern.matcher(text)
            if (failedChapterNumberMatcher.find()) {
                failedChapterNumberMatcher.group(1)?.toFloat()
            } else {
                text.toFloatOrNull()
            }
        }
    }

}