package com.aayush262.dartotsu_extension_bridge.aniyomi.models

import android.annotation.SuppressLint
import com.aayush262.dartotsu_extension_bridge.aniyomi.models.extractLibVersion
import com.aayush262.dartotsu_extension_bridge.aniyomi.models.toAnimeExtensionSources
import com.aayush262.dartotsu_extension_bridge.aniyomi.models.toMangaExtensionSources
import eu.kanade.tachiyomi.extension.anime.model.AnimeExtension
import eu.kanade.tachiyomi.extension.anime.model.AvailableAnimeSources
import eu.kanade.tachiyomi.extension.manga.model.AvailableMangaSources
import eu.kanade.tachiyomi.extension.manga.model.MangaExtension
import eu.kanade.tachiyomi.extension.util.ExtensionLoader
import kotlinx.serialization.Serializable

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class ExtensionJsonObject(
    val name: String,
    val pkg: String,
    val apk: String,
    val lang: String,
    val code: Long,
    val version: String,
    val nsfw: Int,
    val hasReadme: Int = 0,
    val hasChangelog: Int = 0,
    val sources: List<ExtensionSourceJsonObject>?,
)

@SuppressLint("UnsafeOptInUsageError")
@Serializable
data class ExtensionSourceJsonObject(
    val id: Long,
    val lang: String,
    val name: String,
    val baseUrl: String,
)

private fun ExtensionJsonObject.extractLibVersion(): Double {
    return version.substringBeforeLast('.').toDouble()
}

private fun List<ExtensionSourceJsonObject>.toAnimeExtensionSources(): List<AvailableAnimeSources> {
    return this.map {
        AvailableAnimeSources(
            id = it.id,
            lang = it.lang,
            name = it.name,
            baseUrl = it.baseUrl,
        )
    }
}

fun List<ExtensionJsonObject>.toAnimeExtensions(repository: String): List<AnimeExtension.Available> {
    return this
        .filter {
            val libVersion = it.extractLibVersion()
            libVersion >= ExtensionLoader.ANIME_LIB_VERSION_MIN && libVersion <= ExtensionLoader.ANIME_LIB_VERSION_MAX
        }
        .map {
            AnimeExtension.Available(
                name = it.name.substringAfter("Aniyomi: "),
                pkgName = it.pkg,
                versionName = it.version,
                versionCode = it.code,
                libVersion = it.extractLibVersion(),
                lang = it.lang,
                isNsfw = it.nsfw == 1,
                hasReadme = it.hasReadme == 1,
                hasChangelog = it.hasChangelog == 1,
                sources = it.sources?.toAnimeExtensionSources().orEmpty(),
                apkName = it.apk,
                repository = repository,
                iconUrl = "${repository.removeSuffix("/index.min.json")}/icon/${it.pkg}.png",
            )
        }
}
private fun List<ExtensionSourceJsonObject>.toMangaExtensionSources(): List<AvailableMangaSources> {
    return this.map {
        AvailableMangaSources(
            id = it.id,
            lang = it.lang,
            name = it.name,
            baseUrl = it.baseUrl,
        )
    }
}
fun List<ExtensionJsonObject>.toMangaExtensions(repository: String): List<MangaExtension.Available> {
    return this
        .filter {
            val libVersion = it.extractLibVersion()
            libVersion >= ExtensionLoader.MANGA_LIB_VERSION_MIN && libVersion <= ExtensionLoader.MANGA_LIB_VERSION_MAX
        }
        .map {
            MangaExtension.Available(
                name = it.name.substringAfter("Tachiyomi: "),
                pkgName = it.pkg,
                versionName = it.version,
                versionCode = it.code,
                libVersion = it.extractLibVersion(),
                lang = it.lang,
                isNsfw = it.nsfw == 1,
                hasReadme = it.hasReadme == 1,
                hasChangelog = it.hasChangelog == 1,
                sources = it.sources?.toMangaExtensionSources().orEmpty(),
                apkName = it.apk,
                repository = repository,
                iconUrl = "${repository.removeSuffix("/index.min.json")}/icon/${it.pkg}.png",
            )
        }
}