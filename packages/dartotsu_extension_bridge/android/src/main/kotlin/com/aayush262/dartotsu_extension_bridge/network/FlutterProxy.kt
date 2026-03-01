/*
package com.aayush262.dartotsu_extension_bridge.network

import okio.IOException
import java.net.InetSocketAddress
import java.net.Proxy
import java.net.ProxySelector
import java.net.SocketAddress
import java.net.URI

class FlutterProxy(
    private val port: Int = 8080,
    private val type: Proxy.Type = Proxy.Type.HTTP
) : ProxySelector() {

    override fun select(uri: URI): List<Proxy> {
        val host = FlutterNetworkBridge.callBlocking(
            method = "getProxyIp",
            timeoutMs = 500
        ) as? String ?: return listOf(Proxy.NO_PROXY)

        return listOf(
            Proxy(
                type,
                InetSocketAddress(host, port)
            )
        )
    }

    override fun connectFailed(
        uri: URI?,
        sa: SocketAddress?,
        ioe: IOException?
    ) {
        // ignore
    }
}*/
