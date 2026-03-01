package com.aayush262.dartotsu_extension_bridge.aniyomi

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.pm.PackageInfoCompat
import dalvik.system.PathClassLoader
import eu.kanade.tachiyomi.animesource.AnimeCatalogueSource
import eu.kanade.tachiyomi.animesource.AnimeSource
import eu.kanade.tachiyomi.animesource.AnimeSourceFactory
import eu.kanade.tachiyomi.extension.anime.model.AnimeExtension
import eu.kanade.tachiyomi.extension.anime.model.AnimeLoadResult
import eu.kanade.tachiyomi.extension.util.MediaType
import eu.kanade.tachiyomi.extension.util.getApplicationIcon
import eu.kanade.tachiyomi.util.system.ChildFirstPathClassLoader
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import java.io.File

internal object AnimeExtensionLoader {

    private const val EXTENSION_FEATURE = "tachiyomi.animeextension"
    private const val METADATA_SOURCE_CLASS = "tachiyomi.animeextension.class"
    private const val METADATA_SOURCE_FACTORY = "tachiyomi.animeextension.factory"
    private const val METADATA_NSFW = "tachiyomi.animeextension.nsfw"
    private const val METADATA_HAS_README = "tachiyomi.animeextension.hasReadme"
    private const val METADATA_HAS_CHANGELOG = "tachiyomi.animeextension.hasChangelog"

    const val LIB_VERSION_MIN = 12
    const val LIB_VERSION_MAX = 16

    @Suppress("DEPRECATION")
    private val PACKAGE_FLAGS = PackageManager.GET_CONFIGURATIONS or
            PackageManager.GET_META_DATA or
            PackageManager.GET_SIGNATURES or
            (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) PackageManager.GET_SIGNING_CERTIFICATES else 0)

    private const val PRIVATE_EXTENSION_EXTENSION = "ext"

    private fun getPrivateExtensionDir(context: Context) = File(context.filesDir, "exts")

    /*fun installPrivateExtensionFile(context: Context, file: File): Boolean {
        val extension = context.packageManager.getPackageArchiveInfo(
            file.absolutePath,
            PACKAGE_FLAGS,
        )
            ?.takeIf { isPackageAnExtension(it) } ?: return false
        val currentExtension = getAnimeExtensionPackageInfoFromPkgName(
            context,
            extension.packageName,
        )

        if (currentExtension != null) {
            if (PackageInfoCompat.getLongVersionCode(extension) <
                PackageInfoCompat.getLongVersionCode(currentExtension)
            ) {
                logcat(LogPriority.ERROR) { "Installed extension version is higher. Downgrading is not allowed." }
                return false
            }

            val extensionSignatures = getSignatures(extension)
            if (extensionSignatures.isNullOrEmpty()) {
                logcat(LogPriority.ERROR) { "Extension to be installed is not signed." }
                return false
            }

            if (!extensionSignatures.containsAll(getSignatures(currentExtension)!!)) {
                logcat(LogPriority.ERROR) { "Installed extension signature is not matched." }
                return false
            }
        }

        val target = File(
           getPrivateExtensionDir(context),
            "${extension.packageName}.${PRIVATE_EXTENSION_EXTENSION}",
        )
        return try {
            target.delete()
            if (currentExtension != null) {

            } else {

            }
            true
        } catch (e: Exception) {

            target.delete()
            false
        }
    }*/
    /**
     * Return a list of all the available extensions initialized concurrently.
     *
     * @param context The application context.
     */
    suspend fun loadExtensions(context: Context): List<AnimeLoadResult> {
        val pkgManager = context.packageManager

        val installedPkgs = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pkgManager.getInstalledPackages(
                PackageManager.PackageInfoFlags.of(PACKAGE_FLAGS.toLong()),
            )
        } else {
            pkgManager.getInstalledPackages(PACKAGE_FLAGS)
        }

        val sharedExtPkgs = installedPkgs
            .asSequence()
            .filter { isPackageAnExtension(it) }
            .map { AnimeExtensionInfo(packageInfo = it, isShared = true) }

        val privateExtPkgs = getPrivateExtensionDir(context)
            .listFiles()
            ?.asSequence()
            ?.filter { it.isFile && it.extension == PRIVATE_EXTENSION_EXTENSION }
            ?.mapNotNull {
                if (it.canWrite()) {
                    it.setReadOnly()
                }

                val path = it.absolutePath
                pkgManager.getPackageArchiveInfo(path, PACKAGE_FLAGS)
                    ?.apply { applicationInfo!!.fixBasePaths(path) }
            }
            ?.filter { isPackageAnExtension(it) }
            ?.map { AnimeExtensionInfo(packageInfo = it, isShared = false) }
            ?: emptySequence()

        val extPkgs = (sharedExtPkgs + privateExtPkgs)
            .distinctBy { it.packageInfo.packageName }
            .mapNotNull { sharedPkg ->
                val privatePkg = privateExtPkgs
                    .singleOrNull { it.packageInfo.packageName == sharedPkg.packageInfo.packageName }
                selectExtensionPackage(sharedPkg, privatePkg)
            }
            .toList()

        if (extPkgs.isEmpty()) return emptyList()


        return extPkgs.map {
            loadExtension(context, it)
        }
    }

    private suspend fun loadExtension(context: Context, extensionInfo: AnimeExtensionInfo): AnimeLoadResult {
        val pkgManager = context.packageManager

        val pkgInfo = extensionInfo.packageInfo
        val appInfo = pkgInfo.applicationInfo!!
        val pkgName = pkgInfo.packageName

        val extName = pkgManager.getApplicationLabel(appInfo).toString().substringAfter("Aniyomi: ")
        val versionName = pkgInfo.versionName
        val versionCode = PackageInfoCompat.getLongVersionCode(pkgInfo)

        if (versionName.isNullOrEmpty()) {
            return AnimeLoadResult.Error
        }

        // Validate lib version
        val libVersion = versionName.substringBeforeLast('.').toDoubleOrNull()
        if (libVersion == null || libVersion < LIB_VERSION_MIN || libVersion > LIB_VERSION_MAX) {

            return AnimeLoadResult.Error
        }


        val isNsfw = appInfo.metaData.getInt(METADATA_NSFW) == 1
        val hasReadme = appInfo.metaData.getInt(METADATA_HAS_README, 0) == 1
        val hasChangelog =
            appInfo.metaData.getInt(METADATA_HAS_CHANGELOG, 0) == 1


        val classLoader = try {
            ChildFirstPathClassLoader(appInfo.sourceDir, null, context.classLoader)
        } catch (_: Throwable) {
            return AnimeLoadResult.Error
        }

        val sources = appInfo.metaData.getString(METADATA_SOURCE_CLASS)!!
            .split(";")
            .map {
                val sourceClass = it.trim()
                if (sourceClass.startsWith(".")) {
                    pkgInfo.packageName + sourceClass
                } else {
                    sourceClass
                }
            }
            .flatMap {
                try {
                    when (val obj = Class.forName(it, false, classLoader).getDeclaredConstructor().newInstance()) {
                        is AnimeSource -> listOf(obj)
                        is AnimeSourceFactory -> obj.createSources()
                        else -> throw Exception("Unknown source class type: ${obj.javaClass}")
                    }
                } catch (_: LinkageError) {
                    try {
                        val fallBackClassLoader = PathClassLoader(appInfo.sourceDir, null, context.classLoader)
                        when (
                            val obj = Class.forName(
                                it,
                                false,
                                fallBackClassLoader,
                            ).getDeclaredConstructor().newInstance()
                        ) {
                            is AnimeSource -> {
                                listOf(obj)
                            }

                            is AnimeSourceFactory -> obj.createSources()
                            else -> throw Exception("Unknown source class type: ${obj.javaClass}")
                        }
                    } catch (e: Throwable) {

                        return AnimeLoadResult.Error
                    }
                } catch (e: Throwable) {
                    return AnimeLoadResult.Error
                }
            }

        val langs = sources.filterIsInstance<AnimeCatalogueSource>()
            .map { it.lang }
            .toSet()
        val lang = when (langs.size) {
            0 -> ""
            1 -> langs.first()
            else -> "all"
        }

        val extension = AnimeExtension.Installed(
            name = extName,
            pkgName = pkgName,
            versionName = versionName,
            versionCode = versionCode,
            libVersion = libVersion,
            lang = lang,
            isNsfw = isNsfw,
            hasReadme = hasReadme,
            hasChangelog = hasChangelog,
            sources = sources,
            pkgFactory = appInfo.metaData.getString(METADATA_SOURCE_FACTORY),
            isUnofficial = true,
            iconUrl = context.getApplicationIcon(pkgName),
        )
        return AnimeLoadResult.Success(extension)
    }

    /**
     * Choose which extension package to use based on version code
     *
     * @param shared extension installed to system
     * @param private extension installed to data directory
     */
    private fun selectExtensionPackage(shared: AnimeExtensionInfo?, private: AnimeExtensionInfo?): AnimeExtensionInfo? {
        when {
            private == null && shared != null -> return shared
            shared == null && private != null -> return private
            shared == null && private == null -> return null
        }

        return if (PackageInfoCompat.getLongVersionCode(shared!!.packageInfo) >=
            PackageInfoCompat.getLongVersionCode(private!!.packageInfo)
        ) {
            shared
        } else {
            private
        }
    }

    /**
     * Returns true if the given package is an extension.
     *
     * @param pkgInfo The package info of the application.
     */
    private fun isPackageAnExtension(pkgInfo: PackageInfo): Boolean {
        return pkgInfo.reqFeatures.orEmpty().any { it.name == EXTENSION_FEATURE }
    }

    /**
     * On Android 13+ the ApplicationInfo generated by getPackageArchiveInfo doesn't
     * have sourceDir which breaks assets loading (used for getting icon here).
     */
    private fun ApplicationInfo.fixBasePaths(apkPath: String) {
        if (sourceDir == null) {
            sourceDir = apkPath
        }
        if (publicSourceDir == null) {
            publicSourceDir = apkPath
        }
    }

    private data class AnimeExtensionInfo(
        val packageInfo: PackageInfo,
        val isShared: Boolean,
    )
}