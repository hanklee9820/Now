package com.hankle.now.hybrid.web

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.webkit.WebSettings
import android.webkit.WebView
import androidx.compose.ui.platform.isDebugInspectorInfoEnabled
import com.hankle.now.hybrid.NowHybrid

@SuppressLint("SetJavaScriptEnabled")
internal class WilmarNativeWebView(
    context: Context,
    private val owner: WilmarHybridWebView,
) : WebView(context) {
    init {
        settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            allowFileAccess = true
            allowContentAccess = true
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
            mediaPlaybackRequiresUserGesture = false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            setWebContentsDebuggingEnabled(true)
        }
        webViewClient = WilmarWebViewClient(context)
        webChromeClient = WilmarWebChromeClient(owner)
        addJavascriptInterface(NativeBridge(owner), NowHybrid.defaultJavaScriptInterfaceName)
    }
}

