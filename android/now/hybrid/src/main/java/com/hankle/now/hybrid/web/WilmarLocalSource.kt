package com.hankle.now.hybrid.web

import java.net.URI

class WilmarLocalSource private constructor(
    val url: String,
) {
    companion object {
        const val customScheme: String = "localx"

        fun create(localPath: String): WilmarLocalSource {
            val resolved = runCatching { URI(localPath) }.getOrNull()
            val url = if (resolved?.scheme.isNullOrBlank()) {
                "$customScheme://$localPath"
            } else {
                localPath
            }
            return WilmarLocalSource(url)
        }
    }
}

