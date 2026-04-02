package com.hankle.now.hybrid.jsbridge

import com.hankle.now.hybrid.web.WilmarHybridWebView

interface INowJsBridge {
    fun bind(bridge: INowBridge, webView: WilmarHybridWebView)
    fun bind(webView: WilmarHybridWebView, vararg bridges: INowBridge)
}

