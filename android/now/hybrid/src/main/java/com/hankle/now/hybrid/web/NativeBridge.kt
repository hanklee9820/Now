package com.hankle.now.hybrid.web

import android.webkit.JavascriptInterface

internal class NativeBridge(
    private val owner: WilmarHybridWebView,
) {
    @JavascriptInterface
    fun invokeNativeMethod(data: String?, callback: String?) {
        owner.dispatchNativeMessage(data.orEmpty(), callback)
    }
}

