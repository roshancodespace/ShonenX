package eu.kanade.tachiyomi.extension.anime

import android.content.Context
import android.graphics.drawable.Drawable
import eu.kanade.tachiyomi.extension.anime.model.AnimeExtension
import eu.kanade.tachiyomi.extension.anime.model.AnimeLoadResult
import eu.kanade.tachiyomi.extension.util.ExtensionLoader
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import tachiyomi.domain.source.anime.model.AnimeSourceData

/**
 * The manager of anime extensions installed as another apk which extend the available sources. It handles
 * the retrieval of remotely available anime extensions as well as installing, updating and removing them.
 * To avoid malicious distribution, every anime extension must be signed and it will only be loaded if its
 * signature is trusted, otherwise the user will be prompted with a warning to trust it before being
 * loaded.
 *
 * @param context The application context.
 * @param preferences The application preferences.
 */
class AnimeExtensionManager(
    private val context: Context,
) {

    var isInitialized = false
        private set

    /**
     * API where all the available anime extensions can be found.
     */


    /**
     * The installer which installs, updates and uninstalls the anime extensions.
     */

    private val iconMap = mutableMapOf<String, Drawable>()

    private val _installedAnimeExtensionsFlow =
        MutableStateFlow(emptyList<AnimeExtension.Installed>())
    val installedExtensionsFlow = _installedAnimeExtensionsFlow.asStateFlow()

    fun getAppIconForSource(sourceId: Long): Drawable? {
        val pkgName =
            _installedAnimeExtensionsFlow.value.find { ext -> ext.sources.any { it.id == sourceId } }?.pkgName
        if (pkgName != null) {
            return iconMap[pkgName]
                ?: iconMap.getOrPut(pkgName) { context.packageManager.getApplicationIcon(pkgName) }
        }
        return null
    }

    private val _availableAnimeExtensionsFlow =
        MutableStateFlow(emptyList<AnimeExtension.Available>())
    val availableExtensionsFlow = _availableAnimeExtensionsFlow.asStateFlow()

    private var availableAnimeExtensionsSourcesData: Map<Long, AnimeSourceData> = emptyMap()

    private fun setupAvailableAnimeExtensionsSourcesDataMap(animeextensions: List<AnimeExtension.Available>) {
        if (animeextensions.isEmpty()) return
        availableAnimeExtensionsSourcesData = animeextensions
            .flatMap { ext -> ext.sources.map { it.toAnimeSourceData() } }
            .associateBy { it.id }
    }

    fun getSourceData(id: Long) = availableAnimeExtensionsSourcesData[id]

    private val _untrustedAnimeExtensionsFlow =
        MutableStateFlow(emptyList<AnimeExtension.Untrusted>())
    val untrustedExtensionsFlow = _untrustedAnimeExtensionsFlow.asStateFlow()

    init {
        initAnimeExtensions()
    }

    /**
     * Loads and registers the installed animeextensions.
     */
    private fun initAnimeExtensions() {
        val animeextensions = ExtensionLoader.loadAnimeExtensions(context)

        _installedAnimeExtensionsFlow.value = animeextensions
            .filterIsInstance<AnimeLoadResult.Success>()
            .map { it.extension }

        _untrustedAnimeExtensionsFlow.value = animeextensions
            .filterIsInstance<AnimeLoadResult.Untrusted>()
            .map { it.extension }

        isInitialized = true
    }
}

