package com.aayush262.dartotsu_extension_bridge.network

import LogInterceptor
import com.aayush262.dartotsu_extension_bridge.Logger
import eu.kanade.tachiyomi.network.NetworkHelper
import io.flutter.plugin.common.MethodChannel
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.dnsoverhttps.DnsOverHttps
import uy.kohesive.injekt.Injekt
import uy.kohesive.injekt.api.get
import java.util.concurrent.TimeUnit

object FlutterNetwork {

    fun enableFlutterNetworking(channel: MethodChannel, data: Map<*, *>): Boolean {
        try {
            val client = Injekt.get<NetworkHelper>()
            val dns = data["dns"] as? String? ?: ""

            val dnsClient = OkHttpClient.Builder()
                .connectTimeout(5, TimeUnit.SECONDS)
                .readTimeout(5, TimeUnit.SECONDS)
                .build()
            val doh = dns.takeIf { it.isNotEmpty() }?.let {
                DnsOverHttps.Builder()
                    .client(dnsClient)
                    .url(it.toHttpUrl())
                    .build()
            }

            client.client = client.client.newBuilder()
                .dns(doh ?: client.client.dns)
                .addInterceptor(LogInterceptor())
                .addInterceptor(CookieInterceptor(channel))
                .build()
            Logger.log("Flutter networking enabled");
            return true
        } catch (t: Throwable) {
            return false
        }
    }
}