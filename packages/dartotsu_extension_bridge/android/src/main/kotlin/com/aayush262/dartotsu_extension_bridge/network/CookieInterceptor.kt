package com.aayush262.dartotsu_extension_bridge.network

import android.os.Handler
import android.os.Looper
import android.util.Log
import okhttp3.Interceptor
import okhttp3.Response
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

class CookieInterceptor(
    private val channel: MethodChannel
) : Interceptor {

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        val url = request.url.toString()

        val cookieHeader = getCookiesBlocking(channel, url)
        val newRequest = if (!cookieHeader.isNullOrEmpty()) {
            request.newBuilder()
                .removeHeader("Cookie")
                .addHeader("Cookie", cookieHeader)
                .build()
        } else {
            request
        }

        val response = chain.proceed(newRequest)

        val setCookies = response.headers("Set-Cookie")
        if (setCookies.isNotEmpty()) {
            sendCookiesToFlutter(channel, url, setCookies)
        }

        return response
    }

    private fun getCookiesBlocking(
        channel: MethodChannel,
        url: String
    ): String? {
        val latch = CountDownLatch(1)
        var resultHeader: String? = null

        mainHandler.post {
            channel.invokeMethod(
                "getCookies",
                url,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        val map = result as? Map<*, *>
                        resultHeader = map
                            ?.entries
                            ?.joinToString("; ") { "${it.key}=${it.value}" }
                        latch.countDown()
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        latch.countDown()
                    }

                    override fun notImplemented() {
                        latch.countDown()
                    }
                }
            )
        }

        latch.await(500, TimeUnit.MILLISECONDS)
        return resultHeader
    }

    private fun sendCookiesToFlutter(
        channel: MethodChannel,
        url: String,
        cookies: List<String>
    ) {
        mainHandler.post {
            channel.invokeMethod(
                "setCookies",
                mapOf(
                    "url" to url,
                    "cookies" to cookies
                )
            )
        }
    }

}
