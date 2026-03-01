package com.aayush262.dartotsu_extension_bridge.aniyomi

import android.annotation.SuppressLint
import android.content.Context
import androidx.preference.*
import eu.kanade.tachiyomi.PreferenceScreen
import eu.kanade.tachiyomi.animesource.model.AnimesPage
import eu.kanade.tachiyomi.animesource.model.SAnime
import eu.kanade.tachiyomi.animesource.model.SEpisode
import eu.kanade.tachiyomi.animesource.online.AnimeHttpSource
import eu.kanade.tachiyomi.source.model.Page
import eu.kanade.tachiyomi.source.model.SChapter
import eu.kanade.tachiyomi.source.online.HttpSource
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import okhttp3.Headers
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.get
import androidx.core.net.toUri
import com.aayush262.dartotsu_extension_bridge.LogLevel
import com.aayush262.dartotsu_extension_bridge.Logger

class AniyomiBridge(private val context: Context) {
    private lateinit var channel: MethodChannel

    fun attach(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            binding.binaryMessenger,
            "flutterKotlinBridge"
        ).apply {
            setMethodCallHandler(Handler())
        }

    }

    fun detach() = channel.setMethodCallHandler(null)


    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private inner class Handler : MethodChannel.MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            runCatching {
                handlers[call.method]?.invoke(call, result)
                    ?: result.notImplemented()
            }.onFailure {
                Logger.log("Bad method call $it", LogLevel.INFO)
                result.error("INVALID_ARGS", it.message, null)
            }
        }


        private val handlers = mapOf(
            "getInstalledAnimeExtensions" to ::getInstalledAnimeExtensions,
            "getInstalledMangaExtensions" to ::getInstalledMangaExtensions,
            "fetchAnimeExtensions" to ::fetchAnimeExtensions,
            "fetchMangaExtensions" to ::fetchMangaExtensions,
            "getLatestUpdates" to ::getLatestUpdates,
            "getPopular" to ::getPopular,
            "getDetail" to ::getDetail,
            "getVideoList" to ::getVideoList,
            "getPageList" to ::getPageList,
            "search" to ::search,
            "getPreference" to ::getPreference,
            "saveSourcePreference" to ::saveSourcePreference
        )


        private fun media(sourceId: String, isAnime: Boolean) =
            if (isAnime) AnimeSourceMethods(sourceId) else MangaSourceMethods(sourceId)

        private inline fun <reified T> MethodCall.arg(key: String): T =
            (arguments as? Map<*, *>)?.get(key) as? T
                ?: throw IllegalArgumentException("Missing or invalid arg: $key")

        private fun launch(call: MethodCall,result: MethodChannel.Result, block: suspend () -> Any?) {
            scope.launch {
                runCatching { block() }
                    .onSuccess { withContext(Dispatchers.Main) { result.success(it) } }
                    .onFailure {
                        Logger.log("Error for [${call.method}]: $it", LogLevel.ERROR)
                        withContext(Dispatchers.Main) {
                            result.error("ERROR", it.message, null)
                        }
                    }
            }
        }


        private fun getInstalledAnimeExtensions(call: MethodCall, result: MethodChannel.Result) =
            launch(call,result) {

                Injekt.get<AniyomiExtensionManager>().fetchInstalledAnimeExtensions().map { ext ->
                    val baseUrl = (ext.sources.firstOrNull() as? AnimeHttpSource)?.baseUrl.orEmpty()
                    mapOf(
                        "id" to ext.sources.first().id,
                        "name" to ext.name,
                        "baseUrl" to baseUrl,
                        "lang" to ext.lang,
                        "isNsfw" to ext.isNsfw,
                        "iconUrl" to ext.iconUrl,
                        "version" to ext.versionName,
                        "libVersion" to ext.libVersion,
                        "supportedLanguages" to ext.sources.map { it.lang },
                        "itemType" to 1,
                        "hasUpdate" to ext.hasUpdate,
                        "isObsolete" to ext.isObsolete,
                        "isUnofficial" to ext.isUnofficial,
                    )
                }
            }

        private fun getInstalledMangaExtensions(call: MethodCall, result: MethodChannel.Result) =
            launch(call,result) {
                Injekt.get<AniyomiExtensionManager>().fetchInstalledMangaExtensions().map { ext ->
                    val baseUrl = (ext.sources.firstOrNull() as? HttpSource)?.baseUrl.orEmpty()
                    mapOf(
                        "id" to ext.sources.first().id,
                        "name" to ext.name,
                        "baseUrl" to baseUrl,
                        "lang" to ext.lang,
                        "isNsfw" to ext.isNsfw,
                        "iconUrl" to ext.iconUrl,
                        "version" to ext.versionName,
                        "libVersion" to ext.libVersion,
                        "supportedLanguages" to ext.sources.map { it.lang },
                        "itemType" to 0,
                        "hasUpdate" to ext.hasUpdate,
                        "isObsolete" to ext.isObsolete,
                        "isUnofficial" to ext.isUnofficial,
                    )
                }
            }


        private fun fetchAnimeExtensions(call: MethodCall, result: MethodChannel.Result) =
            launch(call,result) {
                val args = call.arguments as? List<*>
                val repos = args?.filterIsInstance<String>() ?: emptyList()
                Injekt.get<AniyomiExtensionManager>()
                    .findAvailableAnimeExtensions(repos)
                    .map { ext ->

                        mapOf(
                            "name" to ext.name,
                            "id" to ext.sources.first().id,
                            "version" to ext.versionName,
                            "libVersion" to ext.libVersion,
                            "supportedLanguages" to ext.sources.map { it.lang },
                            "lang" to ext.lang,
                            "isNsfw" to ext.isNsfw,
                            "apkName" to ext.apkName,
                            "iconUrl" to ext.iconUrl,
                            "itemType" to 1,
                        )
                    }
            }

        private fun fetchMangaExtensions(call: MethodCall, result: MethodChannel.Result) =
            launch(call,result) {
                val args = call.arguments as? List<*>
                val repos = args?.filterIsInstance<String>() ?: emptyList()
                Injekt.get<AniyomiExtensionManager>()
                    .findAvailableMangaExtensions(repos)
                    .map { ext ->
                        mapOf(
                            "name" to ext.name,
                            "id" to ext.sources.first().id,
                            "version" to ext.versionName,
                            "libVersion" to ext.libVersion,
                            "supportedLanguages" to ext.sources.map { it.lang },
                            "lang" to ext.lang,
                            "apkName" to ext.apkName,
                            "isNsfw" to ext.isNsfw,
                            "iconUrl" to ext.iconUrl,
                            "itemType" to 0,
                        )
                    }
            }


        private fun getPopular(call: MethodCall, result: MethodChannel.Result) =
            paged(call, result) { media, page -> media.getPopular(page) }

        private fun getLatestUpdates(call: MethodCall, result: MethodChannel.Result) =
            paged(call, result) { media, page -> media.getLatestUpdates(page) }

        private fun search(call: MethodCall, result: MethodChannel.Result) =
            paged(call, result) { media, page ->
                media.getSearchResults(call.arg("query"), page)
            }

        private fun paged(
            call: MethodCall,
            result: MethodChannel.Result,
            block: suspend (AniyomiSourceMethods, Int) -> AnimesPage
        ) = launch(call,result) {
            val sourceId = call.arg<String>("sourceId")
            val isAnime = call.arg<Boolean>("isAnime")
            val page = call.arg<Int>("page")

            val res = block(media(sourceId, isAnime), page)
            mapOf(
                "list" to res.animes.map { it.toMap() },
                "hasNextPage" to res.hasNextPage
            )
        }

        private fun getDetail(call: MethodCall, result: MethodChannel.Result) = launch(call,result) {
            val sourceId = call.arg<String>("sourceId")
            val isAnime = call.arg<Boolean>("isAnime")
            val map = call.arg<Map<String, Any?>>("media")

            val anime = SAnime.create().apply {
                title = map["title"] as String
                url = map["url"] as String
                thumbnail_url = map["thumbnail_url"] as? String
                description = map["description"] as? String
                artist = map["artist"] as? String
                author = map["author"] as? String
                genre = map["genre"] as? String
            }

            val media = media(sourceId, isAnime)
            val details = media.getDetails(anime)
            val eps = if (isAnime) media.getEpisodeList(anime) else media.getChapterList(anime)

            mapOf(
                "title" to anime.title,
                "url" to anime.url,
                "cover" to anime.thumbnail_url,
                "artist" to details.artist,
                "author" to details.author,
                "description" to details.description,
                "genre" to details.getGenres(),
                "status" to details.status,
                "episodes" to eps.map {
                    mapOf(
                        "name" to it.name,
                        "url" to it.url,
                        "date_upload" to it.date_upload,
                        "episode_number" to it.episode_number,
                        "scanlator" to it.scanlator
                    )
                }
            )
        }

        private fun getVideoList(call: MethodCall, result: MethodChannel.Result) = launch(call,result) {
            val sourceId = call.arg<String>("sourceId")
            val isAnime = call.arg<Boolean>("isAnime")
            val map = call.arg<Map<String, Any?>>("episode")

            val ep = SEpisode.create().apply {
                name = map["name"] as String
                url = map["url"] as String
                episode_number = (map["episode_number"] as? Double)?.toFloat() ?: 0f
                scanlator = map["scanlator"] as? String
            }

            media(sourceId, isAnime).getVideoList(ep).map {
                mapOf(
                    "title" to it.videoTitle,
                    "url" to it.videoUrl,
                    "quality" to it.resolution,
                    "headers" to it.headers?.toMap(),
                    "subtitles" to it.subtitleTracks.map { t -> mapOf("file" to t.url, "label" to t.lang) },
                    "audios" to it.audioTracks.map { t -> mapOf("file" to t.url, "label" to t.lang) }
                )
            }
        }

        private fun Headers.toMap() = names().associateWith { this[it].orEmpty() }

        private fun Page.toPayload(baseUrl: String): Map<String, Any> {
            val uri = imageUrl!!.toUri()
            val headers = uri.queryParameterNames.associateWith {
                uri.getQueryParameter(it).orEmpty()
            } + mapOf("Referer" to "$baseUrl/", "Origin" to baseUrl)

            return mapOf("url" to imageUrl!!, "headers" to headers)
        }

        private fun getPageList(call: MethodCall, result: MethodChannel.Result) = launch(call,result) {
            val sourceId = call.arg<String>("sourceId")
            val isAnime = call.arg<Boolean>("isAnime")
            val map = call.arg<Map<String, Any?>>("episode")

            val chapter = SChapter.create().apply {
                name = map["name"] as String
                url = map["url"] as String
            }

            val media = media(sourceId, isAnime)
            media.getPageList(chapter).map { it.toPayload(media.baseUrl ?: "") }
        }


        private val sourcePreferences = mutableMapOf<String, MutableMap<String, PrefHandlers>>()

        fun saveSourcePreference(call: MethodCall, result: MethodChannel.Result) {
            val sourceId = call.arg<String>("sourceId")
            val key = call.arg<String>("key")
            val action = (call.arguments as Map<*, *>)["action"] as? String ?: "change"
            val newValue = (call.arguments as Map<*, *>)["value"]

            val handler = sourcePreferences[sourceId]?.get(key) ?: return
            val pref = handler.pref

            if (action == "click") handler.click?.onPreferenceClick(pref)
            else handler.change?.onPreferenceChange(pref, newValue)

            when (pref) {
                is SwitchPreferenceCompat -> pref.isChecked = newValue as Boolean
                is ListPreference -> pref.value = newValue as String
                is EditTextPreference -> pref.text = newValue as String
                is MultiSelectListPreference -> {
                    val newSet = when (newValue) {
                        is List<*> -> newValue.filterIsInstance<String>().toSet()
                        is Set<*> -> newValue.filterIsInstance<String>()
                        else -> emptySet()
                    }
                    pref.values = newSet.toMutableSet()
                }

                is CheckBoxPreference -> pref.isChecked = newValue as Boolean
            }

            result.success(true)
        }

        @SuppressLint("RestrictedApi")
        private fun getPreference(call: MethodCall, result: MethodChannel.Result) {
            val sourceId = call.arg<String>("sourceId")
            val isAnime = call.arg<Boolean>("isAnime")

            sourcePreferences.remove(sourceId)

            val screen = PreferenceManager(context).createPreferenceScreen(context)
            media(sourceId, isAnime).setupPreferenceScreen(screen)

            result.success(screen.toDynamicMap(sourceId))
        }

        private fun PreferenceScreen.toDynamicMap(sourceId: String): List<Map<String, Any?>> {
            val list = mutableListOf<Map<String, Any?>>()
            val store = sourcePreferences.getOrPut(sourceId) { mutableMapOf() }

            fun walk(group: PreferenceGroup) {
                for (i in 0 until group.preferenceCount) {
                    val p = group.getPreference(i)
                    store[p.key] = PrefHandlers(p, p.onPreferenceClickListener, p.onPreferenceChangeListener)

                    val map = mutableMapOf(
                        "key" to p.key,
                        "title" to p.title?.toString(),
                        "summary" to p.summary?.toString(),
                        "enabled" to p.isEnabled,
                        "type" to when (p) {
                            is ListPreference -> "list"
                            is MultiSelectListPreference -> "multi_select"
                            is SwitchPreferenceCompat -> "switch"
                            is EditTextPreference -> "text"
                            is CheckBoxPreference -> "checkbox"
                            else -> "other"
                        },
                        "value" to when (p) {
                            is ListPreference -> p.value
                            is MultiSelectListPreference -> p.values.toList()
                            is SwitchPreferenceCompat -> p.isChecked
                            is EditTextPreference -> p.text
                            is CheckBoxPreference -> p.isChecked
                            else -> null
                        }
                    )

                    list += map
                    if (p is PreferenceCategory) walk(p)
                }
            }

            walk(this)
            return list
        }
    }

    private data class PrefHandlers(
        val pref: Preference,
        val click: Preference.OnPreferenceClickListener?,
        val change: Preference.OnPreferenceChangeListener?
    )
}


private fun SAnime.toMap() = mapOf(
    "title" to title,
    "url" to url,
    "cover" to thumbnail_url,
    "artist" to artist,
    "author" to author,
    "description" to description,
    "genre" to getGenres(),
    "status" to status,
)
