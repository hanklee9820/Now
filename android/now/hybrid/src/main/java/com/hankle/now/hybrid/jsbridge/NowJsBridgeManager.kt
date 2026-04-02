package com.hankle.now.hybrid.jsbridge

import com.hankle.now.hybrid.web.WilmarHybridWebView

object NowJsBridgeManager : INowJsBridge {
    override fun bind(bridge: INowBridge, webView: WilmarHybridWebView) {
        bridge.webView = webView
        webView.bindBridge(bridge)
    }

    override fun bind(webView: WilmarHybridWebView, vararg bridges: INowBridge) {
        bridges.forEach { bind(it, webView) }
    }
}

