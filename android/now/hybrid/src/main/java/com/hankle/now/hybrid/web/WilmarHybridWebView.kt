package com.hankle.now.hybrid.web

import android.content.Context
import android.util.AttributeSet
import android.view.ViewGroup
import android.webkit.CookieManager
import android.widget.FrameLayout
import com.hankle.now.hybrid.bridge.BridgeInvocationRequest
import com.hankle.now.hybrid.jsbridge.INowBridge
import com.hankle.now.hybrid.jsbridge.dto.HybResponse
import com.hankle.now.hybrid.bridge.BridgeJson

class WilmarHybridWebView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {
    private val boundBridges = linkedSetOf<INowBridge>()
    private val nativeWebView = WilmarNativeWebView(context, this)

    var onProgressChanged: ((Int) -> Unit)? = null
    var onFullScreenChanged: ((Boolean) -> Unit)? = null

    init {
        addView(
            nativeWebView,
            LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT),
        )
    }

    fun loadUrl(url: String) {
        nativeWebView.loadUrl(url)
    }

    fun load(source: WilmarLocalSource) {
        nativeWebView.loadUrl(source.url)
    }

    fun loadHtml(html: String, baseUrl: String? = null) {
        nativeWebView.loadDataWithBaseURL(baseUrl, html, "text/html", "utf-8", null)
    }

    fun evaluateJavaScriptDirectly(script: String) {
        nativeWebView.post {
            nativeWebView.evaluateJavascript(script, null)
        }
    }

    fun bindBridge(bridge: INowBridge) {
        if (boundBridges.add(bridge)) {
            bridge.webView = this
        }
    }

    fun unbindBridge(bridge: INowBridge) {
        boundBridges.remove(bridge)
        if (bridge.webView === this) {
            bridge.webView = null
        }
    }

    fun canGoBack(): Boolean = nativeWebView.canGoBack()

    fun goBackPage() {
        nativeWebView.goBack()
    }

    fun syncCookies(url: String, cookies: Map<String, String>) {
        val manager = CookieManager.getInstance()
        manager.setAcceptCookie(true)
        cookies.forEach { (name, value) ->
            manager.setCookie(url, "$name=$value")
        }
        manager.flush()
    }

    fun release() {
        boundBridges.forEach { bridge ->
            if (bridge.webView === this) {
                bridge.webView = null
            }
        }
        boundBridges.clear()
        nativeWebView.destroy()
    }

    internal fun notifyProgress(progress: Int) {
        onProgressChanged?.invoke(progress)
    }

    internal fun notifyFullScreenChanged(fullScreen: Boolean) {
        onFullScreenChanged?.invoke(fullScreen)
    }

    internal fun dispatchNativeMessage(eventName: String, data: String?) {
        val request = BridgeInvocationRequest.from(eventName, data)
        val consumed = boundBridges.any {
            it.dispatchMethodAsync(
                methodName = request.methodName,
                paramData = request.paramData,
                callback = request.callbackId,
                oldVersion = request.oldVersion,
            )
        }
        if (!consumed && !request.callbackId.isNullOrBlank()) {
            evaluateJavaScriptDirectly(
                BridgeJson.toCallbackScript(
                    request.callbackId,
                    HybResponse.error("No native bridge matched ${request.methodName}.", request.oldVersion),
                ),
            )
        }
    }
}

