package com.aayush262.dartotsu_extension_bridge

import android.app.Activity
import android.app.Application
import android.content.Context
import android.util.Log
import androidx.fragment.app.FragmentActivity
import com.aayush262.dartotsu_extension_bridge.aniyomi.AniyomiBridge
import com.aayush262.dartotsu_extension_bridge.aniyomi.AniyomiExtensionManager
import eu.kanade.tachiyomi.network.NetworkHelper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import kotlinx.serialization.json.Json
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.addSingletonFactory
/** DartotsuExtensionBridgePlugin */
class DartotsuExtensionBridgePlugin : FlutterPlugin {
    private lateinit var context: Context
    private lateinit var aniyomiChannel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d("PluginDebug", "Plugin attached to engine")
        context = binding.applicationContext

        Injekt.addSingletonFactory<Application> { context as Application }
        Injekt.addSingletonFactory { NetworkHelper(context) }
        Injekt.addSingletonFactory { NetworkHelper(context).client }
        Injekt.addSingletonFactory { Json { ignoreUnknownKeys = true ;explicitNulls = false }}
        Injekt.addSingletonFactory { AniyomiExtensionManager(context) }
        aniyomiChannel = MethodChannel(binding.binaryMessenger, "aniyomiExtensionBridge")
        aniyomiChannel.setMethodCallHandler(AniyomiBridge(context))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        aniyomiChannel.setMethodCallHandler(null)
    }

}
