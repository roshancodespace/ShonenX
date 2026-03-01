package com.aayush262.dartotsu_extension_bridge

import android.util.Log
import com.aayush262.dartotsu_extension_bridge.network.FlutterNetwork.enableFlutterNetworking
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class FlutterKotlinBridge {

    private lateinit var networkChannel: MethodChannel
    private lateinit var loggerChannel: MethodChannel
    fun attach(binding: FlutterPlugin.FlutterPluginBinding) {
        networkChannel = MethodChannel(
            binding.binaryMessenger,
            "flutterKotlinBridge.network"
        ).apply {
            setMethodCallHandler(Handler())
        }

        loggerChannel = MethodChannel(
            binding.binaryMessenger,
            "flutterKotlinBridge.logger"
        )

        Logger.init(loggerChannel)
    }

    fun detach() {
        networkChannel.setMethodCallHandler(null)
        loggerChannel.setMethodCallHandler(null)
    }


    private inner class Handler : MethodChannel.MethodCallHandler {
        override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
            when (call.method) {
                "initClient" -> {
                    val args = call.arguments as? Map<*, *>
                        ?: return result.error(
                            "INVALID_ARGUMENTS",
                            "Expected a map",
                            null
                        )

                    enableFlutterNetworking(networkChannel, args)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }
}