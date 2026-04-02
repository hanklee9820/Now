package com.hankle.now.hybrid.web

import android.content.Context
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileInputStream
import java.net.URLConnection

internal class WilmarWebViewClient(
    private val context: Context,
) : WebViewClient() {
    override fun shouldInterceptRequest(view: WebView?, request: WebResourceRequest?): WebResourceResponse? {
        val uri = request?.url ?: return super.shouldInterceptRequest(view, request)
        if (uri.scheme != WilmarLocalSource.customScheme) {
            return super.shouldInterceptRequest(view, request)
        }

        val file = resolveFile(uri.host, uri.path) ?: return notFoundResponse()
        if (!file.exists() || file.isDirectory) {
            return notFoundResponse()
        }

        val mimeType = URLConnection.guessContentTypeFromName(file.name) ?: "text/plain"
        return WebResourceResponse(mimeType, null, FileInputStream(file))
    }

    private fun resolveFile(host: String?, path: String?): File? {
        val combined = buildString {
            if (!host.isNullOrBlank()) append(host)
            if (!path.isNullOrBlank()) append(path)
        }.ifBlank { path.orEmpty() }

        if (combined.isBlank()) {
            return null
        }

        val target = if (combined.endsWith("/")) "${combined}index.html" else combined
        return if (target.startsWith("/")) {
            File(target)
        } else {
            File(context.filesDir, target)
        }
    }

    private fun notFoundResponse(): WebResourceResponse {
        return WebResourceResponse(
            "text/plain",
            "utf-8",
            404,
            "Not Found",
            emptyMap(),
            ByteArrayInputStream(ByteArray(0)),
        )
    }
}

