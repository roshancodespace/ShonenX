package com.aayush262.dartotsu_extension_bridge.aniyomi

import android.content.Context
import com.aayush262.dartotsu_extension_bridge.LogLevel
import com.aayush262.dartotsu_extension_bridge.Logger
import com.aayush262.dartotsu_extension_bridge.aniyomi.models.ExtensionJsonObject
import com.aayush262.dartotsu_extension_bridge.aniyomi.models.toAnimeExtensions
import com.aayush262.dartotsu_extension_bridge.aniyomi.models.toMangaExtensions
import eu.kanade.tachiyomi.extension.anime.model.AnimeExtension
import eu.kanade.tachiyomi.extension.anime.model.AnimeLoadResult
import eu.kanade.tachiyomi.extension.manga.model.MangaExtension
import eu.kanade.tachiyomi.extension.manga.model.MangaLoadResult
import eu.kanade.tachiyomi.extension.util.ExtensionLoader
import eu.kanade.tachiyomi.network.GET
import eu.kanade.tachiyomi.network.awaitSuccess
import eu.kanade.tachiyomi.network.parseAs
import kotlinx.serialization.json.Json
import okhttp3.OkHttpClient
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.get
import uy.kohesive.injekt.injectLazy

class AniyomiExtensionManager(var context: Context) {
    lateinit var installedAnimeExtensions: List<AnimeExtension.Installed>
    lateinit var availableAnimeExtensions: List<AnimeExtension.Available>
    lateinit var installedMangaExtensions: List<MangaExtension.Installed>
    lateinit var availableMangaExtensions: List<MangaExtension.Available>
    private val json: Json by injectLazy()

    suspend fun fetchInstalledAnimeExtensions(): List<AnimeExtension.Installed> {
        val sources = AnimeExtensionLoader.loadExtensions(context)
        installedAnimeExtensions =
            sources.filterIsInstance<AnimeLoadResult.Success>().map { it.extension }
        return installedAnimeExtensions
    }

    fun fetchInstalledMangaExtensions(): List<MangaExtension.Installed> {
        val sources = ExtensionLoader.loadMangaExtensions(context)
        installedMangaExtensions =
            sources.filterIsInstance<MangaLoadResult.Success>().map { it.extension }
        return installedMangaExtensions
    }

    suspend fun findAvailableAnimeExtensions(repos: List<String>): List<AnimeExtension.Available> {
        if (repos.isEmpty()) return emptyList()

        val client = Injekt.get<OkHttpClient>()

        val extensions = repos.mapNotNull { repo ->
            val indexUrl = if (repo.contains("index.min.json")) repo
            else "${repo.trimEnd('/')}/index.min.json"

            val response = try {
                client.newCall(GET(indexUrl)).awaitSuccess()
            } catch (e: Throwable) {
                Logger.log(
                    "Failed to fetch from $indexUrl: ${e.message}\n${e.stackTraceToString()} ",
                    LogLevel.ERROR
                )
                try {
                    val fallbackUrl = "${fallbackRepoUrl(repo)?.trimEnd('/')}/index.min.json"
                    client.newCall(GET(fallbackUrl)).awaitSuccess()
                } catch (e2: Throwable) {
                    Logger.log(
                        "Failed to fetch from fallback URL for $repo: ${e2.message}\n${e.stackTraceToString()}",
                        LogLevel.ERROR
                    )
                    null

                }
            }

            response?.let {
                try {
                    with(json) {
                        it.parseAs<List<ExtensionJsonObject>>()
                            .toAnimeExtensions(repo)
                    }
                } catch (e: Exception) {
                    Logger.log(
                        "Failed to fetch from $indexUrl: ${e.message}\n${e.stackTraceToString()} ",
                        LogLevel.ERROR
                    )
                    null
                }
            }
        }.flatten()

        return extensions.filter { it.pkgName.isNotEmpty() }
            .also { availableAnimeExtensions = it }
    }

    suspend fun findAvailableMangaExtensions(repos: List<String>): List<MangaExtension.Available> {
        if (repos.isEmpty()) return emptyList()

        val client = Injekt.get<OkHttpClient>()

        val extensions = repos.mapNotNull { repo ->
            val indexUrl = if (repo.contains("index.min.json")) repo
            else "${repo.trimEnd('/')}/index.min.json"

            val response = try {
                client.newCall(GET(indexUrl)).awaitSuccess()
            } catch (e: Throwable) {
                Logger.log(
                    "Failed to fetch from $indexUrl: ${e.message}\n${e.stackTraceToString()} ",
                    LogLevel.ERROR
                )
                try {
                    val fallbackUrl = "${fallbackRepoUrl(repo)?.trimEnd('/')}/index.min.json"
                    client.newCall(GET(fallbackUrl)).awaitSuccess()
                } catch (e2: Throwable) {
                    Logger.log(
                        "Failed to fetch from fallback URL for $repo: ${e2.message}\n${e.stackTraceToString()}",
                        LogLevel.ERROR
                    )
                    null
                }
            }

            response?.let {
                try {
                    with(json) {
                        it.parseAs<List<ExtensionJsonObject>>()
                            .toMangaExtensions(repo)
                    }
                } catch (e: Exception) {
                    Logger.log(
                        "Failed to fetch from $indexUrl: ${e.message}\n${e.stackTraceToString()} ",
                        LogLevel.ERROR
                    )
                    null
                }
            }
        }.flatten()

        return extensions.filter { it.pkgName.isNotEmpty() }
            .also { availableMangaExtensions = it }
    }

    private fun fallbackRepoUrl(repoUrl: String): String? {
        var fallbackRepoUrl = "https://gcore.jsdelivr.net/gh/"
        val strippedRepoUrl = repoUrl
            .removePrefix("https://")
            .removePrefix("http://")
            .removeSuffix("/")
            .removeSuffix("/index.min.json")
        val repoUrlParts = strippedRepoUrl.split("/")
        if (repoUrlParts.size < 3) {
            return null
        }
        val repoOwner = repoUrlParts[1]
        val repoName = repoUrlParts[2]
        fallbackRepoUrl += "$repoOwner/$repoName"
        val repoBranch = if (repoUrlParts.size > 3) {
            repoUrlParts[3]
        } else {
            "main"
        }
        fallbackRepoUrl += "@$repoBranch"
        return fallbackRepoUrl
    }
}