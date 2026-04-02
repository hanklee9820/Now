package com.hankle.now.hybrid.jsbridge

import com.hankle.now.hybrid.bridge.BridgeInvocationRequest
import com.hankle.now.hybrid.bridge.BridgeMethodInvoker
import com.hankle.now.hybrid.jsbridge.dto.HybResponse
import com.hankle.now.hybrid.web.WilmarHybridWebView

object JsBridgePlugin {
    fun bind(hook: Any): INowBridge = AnnotatedNowBridge(listOf(hook))

    fun bind(vararg hooks: Any): INowBridge = AnnotatedNowBridge(hooks.toList())

    private class AnnotatedNowBridge(
        hooks: List<Any>,
    ) : INowBridge {
        override var webView: WilmarHybridWebView? = null

        private val invoker = BridgeMethodInvoker(
            hooks = hooks,
            evaluateScript = { script -> webView?.evaluateJavaScriptDirectly(script) },
            webViewProvider = { webView },
        )

        override fun dispatchMethodAsync(
            methodName: String,
            paramData: String?,
            callback: String?,
            oldVersion: Boolean,
        ): Boolean {
            return invoker.dispatch(
                BridgeInvocationRequest(
                    methodName = methodName,
                    paramData = paramData,
                    callbackId = callback,
                    oldVersion = oldVersion,
                ),
            )
        }
    }
}

