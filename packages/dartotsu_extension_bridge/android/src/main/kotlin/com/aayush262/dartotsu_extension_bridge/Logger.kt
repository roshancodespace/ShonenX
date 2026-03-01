package com.aayush262.dartotsu_extension_bridge

import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

object Logger {

    @Volatile
    private var channel: MethodChannel? = null

    private val mainScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    fun init(channel: MethodChannel) {
        this.channel = channel
    }

    fun log(message: String, level: LogLevel = LogLevel.INFO) {
        val ch = channel ?: return

        mainScope.launch {
            ch.invokeMethod("log", "[${level.name}] $message")
        }
    }
}

enum class LogLevel {
    ERROR, WARNING, INFO, DEBUG
}