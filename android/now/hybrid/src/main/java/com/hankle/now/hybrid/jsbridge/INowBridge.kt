package com.hankle.now.hybrid.jsbridge

import com.hankle.now.hybrid.web.WilmarHybridWebView

interface INowBridge {
    var webView: WilmarHybridWebView?

    fun dispatchMethodAsync(
        methodName: String,
        paramData: String?,
        callback: String?,
        oldVersion: Boolean,
    ): Boolean
}

